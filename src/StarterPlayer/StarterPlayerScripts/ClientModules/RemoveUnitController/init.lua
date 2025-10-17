local RemoveUnitController = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PreviewService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local BaseController = require(Players.LocalPlayer.PlayerScripts.ClientModules.BaseController)
local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)
local Debug = require(Utility.Debug)(script)

-- === CONSTANTS
local UNIT_CONTAINERS = {
	BLOCK = true,
	MELEE = true,
	RANGED = true,
	SPIKES = true,
}
local SLOT_DISTANCE_THRESHOLD_SQR = 25 -- 5 studs squared
local RAYCAST_ORIGIN_OFFSET = Vector3.new(0, 10, 0)
local RAYCAST_DIRECTION = Vector3.new(0, -200, 0)
local RAYCAST_FILTER_TYPE = Enum.RaycastFilterType.Exclude

-- === LOCAL STATE
local player: Player = Players.LocalPlayer
local mouse: Mouse = player:GetMouse()
local runtimeFolder: Folder?
local hoverHighlight: Highlight?
local activeUnit: Model?
local activeUnitInfo: table?
local renderConnection: RBXScriptConnection?
local inputConnection: RBXScriptConnection?
local slotIndex: { [Instance]: { part: BasePart, slot: string, subSlot: string, position: Vector3 } } = {}
local slotEntries: { { part: BasePart, slot: string, subSlot: string, position: Vector3 } } = {}

-- === LOCAL FUNCTIONS
local function ensureRuntimeFolder(): Folder?
	if runtimeFolder and runtimeFolder.Parent then
		return runtimeFolder
	end

	local success, folder = pcall(function(): Instance
		return ClientUtil:WaitForDescendants(workspace, "runtime", tostring(player.UserId))
	end)
	if success and folder then
		runtimeFolder = folder
	else
		Debug.warn("Runtime folder for player not available")
	end
	return runtimeFolder
end

local function ensureHighlight(): Highlight
	if hoverHighlight and hoverHighlight.Parent then
		return hoverHighlight
	end

	hoverHighlight = Instance.new("Highlight")
	hoverHighlight.Name = "RemoveUnitHoverHighlight"
	hoverHighlight.FillTransparency = 0.5
	hoverHighlight.FillColor = Color3.fromRGB(255, 92, 92)
	hoverHighlight.OutlineTransparency = 0
	hoverHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	hoverHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	hoverHighlight.Enabled = false
	hoverHighlight.Parent = workspace

	return hoverHighlight
end

local function clearHover(): ()
	activeUnit = nil
	activeUnitInfo = nil
	if hoverHighlight then
		hoverHighlight.Adornee = nil
		hoverHighlight.Enabled = false
	end
end

local function buildSlotIndex(): ()
	table.clear(slotIndex)
	table.clear(slotEntries)

	local base = BaseController:GetBase()
	if not base then
		Debug.warn("Base not found; cannot prepare removal grid lookup")
		return
	end

	local baseTemplate = ClientUtil:WaitForDescendants(base, "baseTemplate")
	local baseSlots = ClientUtil:WaitForDescendants(baseTemplate, "baseSlots")
	local slotsFolder = ClientUtil:WaitForDescendants(baseSlots, "slots")

	for _, slotModel in ipairs(slotsFolder:GetChildren()) do
		if slotModel:IsA("Model") then
			for _, descendant in ipairs(slotModel:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant:GetAttribute("GRID_TYPE") == "SUB_SLOT" then
					local entry = {
						part = descendant,
						slot = slotModel.Name,
						subSlot = descendant.Name,
						position = descendant.Position,
					}
					slotIndex[descendant] = entry
					table.insert(slotEntries, entry)
				end
			end
		end
	end
end

local function resolveUnitFromInstance(instance: Instance?): (Model?, string?)
	if not instance then
		return nil, nil
	end

	local runtime = ensureRuntimeFolder()
	if not runtime then
		return nil, nil
	end

	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") then
			local parent = current.Parent
			if parent and parent.Parent == runtime and UNIT_CONTAINERS[parent.Name] then
				return current, parent.Name
			end
		end
		current = current.Parent
	end

	return nil, nil
end

local function resolveSlotEntry(unit: Model): { part: BasePart, slot: string, subSlot: string, position: Vector3 }?
	if #slotEntries == 0 then
		buildSlotIndex()
	end
	if #slotEntries == 0 then
		return nil
	end

	local pivot = unit:GetPivot()
	local origin = pivot.Position + RAYCAST_ORIGIN_OFFSET

	local params = RaycastParams.new()
	params.FilterType = RAYCAST_FILTER_TYPE
	local filter = { unit }
	if player.Character then
		table.insert(filter, player.Character)
	end
	params.FilterDescendantsInstances = filter

	local result = workspace:Raycast(origin, RAYCAST_DIRECTION, params)
	if result then
		local candidate: Instance? = result.Instance
		while candidate do
			local entry = slotIndex[candidate]
			if entry then
				return entry
			end
			candidate = candidate.Parent
		end
	end

	local pivotPos = pivot.Position
	local closestEntry
	local closestDistance = math.huge
	for _, entry in ipairs(slotEntries) do
		local targetPos = entry.position
		local dx = targetPos.X - pivotPos.X
		local dz = targetPos.Z - pivotPos.Z
		local dist = dx * dx + dz * dz
		if dist < closestDistance then
			closestDistance = dist
			closestEntry = entry
		end
	end

	if closestEntry and closestDistance <= SLOT_DISTANCE_THRESHOLD_SQR then
		return closestEntry
	end

	return nil
end

local function updateHover(): ()
	local target = mouse.Target
	local unit, unitType = resolveUnitFromInstance(target)

	if not unit then
		if activeUnit then
			clearHover()
		end
		return
	end

	if unit == activeUnit and activeUnitInfo then
		return
	end

	local slotEntry = resolveSlotEntry(unit)
	if not slotEntry then
		clearHover()
		return
	end

	local highlight = ensureHighlight()
	highlight.Adornee = unit
	highlight.Enabled = true

	activeUnit = unit
	activeUnitInfo = {
		itemType = unitType,
		itemName = unit.Name,
		slot = slotEntry.slot,
		subSlot = slotEntry.subSlot,
	}
end

local function onInputEnded(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if not activeUnitInfo then
		return
	end

	bridge:InvokeServerAsync({
		[actionIdentifier] = "RemoveItem",
		data = {
			ItemType = activeUnitInfo.itemType,
			ItemName = activeUnitInfo.itemName,
			Slot = activeUnitInfo.slot,
			SubSlot = activeUnitInfo.subSlot,
		},
	})

	clearHover()
end

-- === GLOBAL FUNCTIONS
function RemoveUnitController:Init(): ()
	ensureRuntimeFolder()
end

function RemoveUnitController:Start(): ()
	RemoveUnitController:Stop()

	if not ensureRuntimeFolder() then
		Debug.warn("Cannot start RemoveUnitController without runtime folder")
		return
	end

	if #slotEntries == 0 then
		buildSlotIndex()
	end

	ensureHighlight()

	renderConnection = RunService.RenderStepped:Connect(updateHover)
	inputConnection = UserInputService.InputEnded:Connect(onInputEnded)
end

function RemoveUnitController:Stop(): ()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	clearHover()
end

function RemoveUnitController:Toggle(): ()
	if RemoveUnitController:IsActive() then
		RemoveUnitController:Stop()
	else
		RemoveUnitController:Start()
	end
end

function RemoveUnitController:IsActive(): boolean
	return renderConnection ~= nil
end

return RemoveUnitController
