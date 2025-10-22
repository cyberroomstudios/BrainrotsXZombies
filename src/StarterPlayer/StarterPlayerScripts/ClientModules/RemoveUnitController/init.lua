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
local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)
local Debug = require(Utility.Debug)(script)

-- === LOCAL VARIABLES
local Player: Player = Players.LocalPlayer
local Mouse: Mouse = Player:GetMouse()
local RuntimeFolder: Folder?
local HoverHighlight: Highlight?
local ActiveUnit: Model?
local ActiveUnitInfo: table?
local RenderConnection: RBXScriptConnection?
local InputConnection: RBXScriptConnection?

-- === LOCAL FUNCTIONS
local function ensureRuntimeFolder(): Folder?
	if RuntimeFolder and RuntimeFolder.Parent then
		return RuntimeFolder
	end
	local success, folder = pcall(function(): Instance
		return ClientUtil:WaitForDescendants(workspace, "runtime", tostring(Player.UserId))
	end)
	if success and folder then
		RuntimeFolder = folder
	else
		Debug.warn("Runtime folder for player not available")
	end
	return RuntimeFolder
end

local function ensureHighlight(): Highlight
	if HoverHighlight and HoverHighlight.Parent then
		return HoverHighlight
	end
	HoverHighlight = Instance.new("Highlight")
	HoverHighlight.Name = "RemoveUnitHoverHighlight"
	HoverHighlight.FillTransparency = 0.5
	HoverHighlight.FillColor = Color3.fromRGB(255, 92, 92)
	HoverHighlight.OutlineTransparency = 0
	HoverHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	HoverHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	HoverHighlight.Enabled = false
	HoverHighlight.Parent = workspace
	return HoverHighlight
end

local function clearHover(): ()
	ActiveUnit = nil
	ActiveUnitInfo = nil
	if HoverHighlight then
		HoverHighlight.Adornee = nil
		HoverHighlight.Enabled = false
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
			if parent and parent.Parent == runtime then
				return current, parent.Name
			end
		end
		current = current.Parent
	end

	return nil, nil
end

local function updateHover(): ()
	local target = Mouse.Target
	local unit, unitType = resolveUnitFromInstance(target)

	if not unit then
		if ActiveUnit then
			clearHover()
		end
		return
	end

	if unit == ActiveUnit and ActiveUnitInfo then
		return
	end

	local slotAttribute = unit:GetAttribute("MAP_SLOT")
	local subSlotAttribute = unit:GetAttribute("MAP_SUB_SLOT")
	if not slotAttribute or not subSlotAttribute then
		clearHover()
		return
	end

	local slotNumber = tonumber(slotAttribute)
	local subSlotNumber = tonumber(subSlotAttribute)

	local highlight = ensureHighlight()
	highlight.Adornee = unit
	highlight.Enabled = true

	ActiveUnit = unit
	ActiveUnitInfo = {
		itemType = unitType,
		itemName = unit.Name,
		slot = slotNumber or slotAttribute,
		subSlot = subSlotNumber or subSlotAttribute,
	}
end

local function onInputEnded(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if not ActiveUnitInfo then
		return
	end

	bridge:InvokeServerAsync({
		[actionIdentifier] = "RemoveItem",
		data = {
			ItemType = ActiveUnitInfo.itemType,
			ItemName = ActiveUnitInfo.itemName,
			Slot = ActiveUnitInfo.slot,
			SubSlot = ActiveUnitInfo.subSlot,
		},
	})

	clearHover()
end

-- === GLOBAL FUNCTIONS
function RemoveUnitController:Init(): ()
	ensureRuntimeFolder()
end

function RemoveUnitController:Open(): ()
	RemoveUnitController:Close()
	if not ensureRuntimeFolder() then
		Debug.warn("Cannot start RemoveUnitController without runtime folder")
		return
	end
	ensureHighlight()
	RenderConnection = RunService.RenderStepped:Connect(updateHover)
	InputConnection = UserInputService.InputEnded:Connect(onInputEnded)
end

function RemoveUnitController:Close(): ()
	if RenderConnection then
		RenderConnection:Disconnect()
		RenderConnection = nil
	end
	if InputConnection then
		InputConnection:Disconnect()
		InputConnection = nil
	end
	clearHover()
end

function RemoveUnitController:IsOpen(): boolean
	return RenderConnection ~= nil
end

function RemoveUnitController:Toggle(): ()
	if RemoveUnitController:IsOpen() then
		RemoveUnitController:Close()
	else
		RemoveUnitController:Open()
	end
end

return RemoveUnitController
