local PreviewController = {}

-- === CONSTANTS
local DETECTOR_REGION_SIZE = Vector3.new(2, 50, 2)
local DETECTOR_POSITION_Y = 6.25
local GRID_CELL_SIZE = Vector3.new(4, 2, 4)
local PREVIEW_AREA_CYLINDER_THICKNESS = 0.1

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

-- === ENUMS
local Blocks = require(ReplicatedStorage.Enums.blocks)
local Melee = require(ReplicatedStorage.Enums.melee)
local Ranged = require(ReplicatedStorage.Enums.ranged)
local Spikes = require(ReplicatedStorage.Enums.spikes)
local UnitEnums = {
	["BLOCK"] = Blocks,
	["MELEE"] = Melee,
	["RANGED"] = Ranged,
	["SPIKES"] = Spikes,
}

-- === LOCAL VARIABLES
local Player: Player = Players.LocalPlayer
local Mouse: Mouse = Player:GetMouse()
local CurrentItemName: string = ""
local CurrentItemType: string = ""
local PreviewModel: Model?
local PreviewArea: Part?

-- === LOCAL FUNCTIONS
local function placeSelectedUnit(): ()
	if not PreviewModel then
		Debug.warn("Skipping placement: no preview model")
		return
	end

	local previewPos = PreviewModel:GetPivot().Position
	local detector: Part = Instance.new("Part")
	detector.Size = DETECTOR_REGION_SIZE
	detector.CFrame = CFrame.new(previewPos.X, DETECTOR_POSITION_Y, previewPos.Z)
	detector.Anchored = true
	detector.CanCollide = true
	detector.Transparency = 1
	detector.Parent = workspace

	local touching: { Instance } = detector:GetTouchingParts()
	local slot: string?
	local subSlot: string?
	for _, instance: Instance in ipairs(touching) do
		if instance:GetAttribute("GRID_TYPE") == "SUB_SLOT" then
			slot = instance.Parent.Name
			subSlot = instance.Name
			break
		end
	end

	detector:Destroy()

	if not slot or not subSlot then
		Debug.warn("Skipping placement: no valid slot found")
		return
	end

	local unitData = UnitEnums[CurrentItemType]
	if not unitData then
		Debug.warn("Skipping placement: no unit data found for type", CurrentItemType)
		return
	end

	local unitInfo = unitData[CurrentItemName]
	if not unitInfo then
		Debug.warn("Skipping placement: no unit info found for name", CurrentItemName)
		return
	end

	bridge:InvokeServerAsync({
		[actionIdentifier] = "SetItem",
		data = {
			ItemType = CurrentItemType,
			ItemName = CurrentItemName,
			Slot = slot,
			SubSlot = subSlot,
			IsBrainrot = unitInfo.IsBrainrot,
		},
	})
end

-- === GLOBAL FUNCTIONS
function PreviewController:Init(): ()
	PreviewController:InitButtonListeners()
end

function PreviewController:InitButtonListeners(): ()
	UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean): ()
		if not PreviewModel then
			return -- No preview active, ignore input
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			placeSelectedUnit()
		end
	end)
end

function PreviewController:GetStartBasePartPosition(): Vector3?
	local base = BaseController:GetBase()
	if base then
		local baseTemplate = ClientUtil:WaitForDescendants(base, "baseTemplate")
		local baseSlots = ClientUtil:WaitForDescendants(baseTemplate, "baseSlots")
		local slots = ClientUtil:WaitForDescendants(baseSlots, "slots")
		local model1 = ClientUtil:WaitForDescendants(slots, "1")
		local part1 = ClientUtil:WaitForDescendants(model1, "1")
		return part1.Position
	else
		Debug.warn("Base not found")
		return nil
	end
end

function PreviewController:GetItemFromTypeAndName(unitType: string, unitName: string): Model?
	local unitsFolder = ReplicatedStorage.developer.units
	local items = {
		["BLOCK"] = unitsFolder.blocks,
		["MELEE"] = unitsFolder.melee,
		["RANGED"] = unitsFolder.ranged,
		["TRAP"] = unitsFolder.trap,
		["SPIKES"] = unitsFolder.spikes,
	}
	if items[unitType] then
		local item = items[unitType]:FindFirstChild(unitName)
		if item then
			return item:Clone()
		else
			Debug.warn("Item not found:", unitName)
			return nil
		end
	else
		Debug.warn("Item type not found:", unitType)
		return nil
	end
end

function PreviewController:Start(unitType: string, unitName: string): ()
	-- Make sure to stop any existing preview first
	PreviewController:Stop()

	CurrentItemType = unitType
	CurrentItemName = unitName

	local gridOrigin = PreviewController:GetStartBasePartPosition()
	PreviewModel = PreviewController:GetItemFromTypeAndName(unitType, unitName)
	PreviewModel.PrimaryPart.Transparency = 0.5
	PreviewModel.PrimaryPart.CanTouch = false
	PreviewModel.PrimaryPart.CanCollide = false
	PreviewModel.PrimaryPart.Anchored = true

	local faceEnemySpawnRotation = CFrame.Angles(0, (Player:GetAttribute("BASE") % 2 == 0 and 0 or math.rad(180)), 0)
	PreviewModel:PivotTo(CFrame.new(PreviewModel.PrimaryPart.Position) * faceEnemySpawnRotation)

	-- Ignore the player and preview in the raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { Player.Character, PreviewModel }

	local function getMousePosition(): Vector3?
		local unitRay = Mouse.UnitRay
		local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)
		if raycastResult then
			return raycastResult.Position
		end
		return nil
	end

	-- Function to align the preview to the grid
	local function snapToGridXZ(pos: Vector3): Vector3
		local relative = pos - gridOrigin

		-- Compute X and Z aligned to the grid
		local x = math.floor(relative.X / GRID_CELL_SIZE.X + 0.5) * GRID_CELL_SIZE.X
		local z = math.floor(relative.Z / GRID_CELL_SIZE.Z + 0.5) * GRID_CELL_SIZE.Z

		-- Model bounding box
		local bboxCFrame, bboxSize = PreviewModel:GetBoundingBox()
		local baseY = bboxCFrame.Position.Y - (bboxSize.Y / 2)

		-- Target floor height
		local targetY = 8.501
		local offsetY = targetY - baseY

		-- Move the entire model
		local newPivot = PreviewModel:GetPivot()
			+ Vector3.new(x + gridOrigin.X - bboxCFrame.Position.X, offsetY, z + gridOrigin.Z - bboxCFrame.Position.Z)

		PreviewModel:PivotTo(newPivot)

		-- Return only the final pivot position (if needed later)
		return newPivot.Position
	end

	local startPos = getMousePosition()
	if startPos then
		local snapped = snapToGridXZ(startPos)
		PreviewModel:PivotTo(CFrame.new(snapped))
	end

	PreviewModel.Name = "Preview"
	PreviewModel.Parent = workspace

	-- Create the area preview part
	PreviewArea = Instance.new("Part")
	PreviewArea.Name = "PreviewArea"
	PreviewArea.Anchored = true
	PreviewArea.CanCollide = false
	PreviewArea.Transparency = 0
	PreviewArea.Color = Color3.fromRGB(76, 0, 255)
	PreviewArea.Material = Enum.Material.ForceField
	PreviewArea.Shape = Enum.PartType.Cylinder
	PreviewArea.Parent = workspace

	-- In Roblox, a Cylinder lies on the X axis by default
	-- TODO radius should be set from unit DetectionRange property
	local radius: number = 15
	PreviewArea.Size = Vector3.new(PREVIEW_AREA_CYLINDER_THICKNESS, radius * 2, radius * 2)

	-- Rotate so it rests on the ground
	local horizontalCylinderRotation = CFrame.Angles(0, 0, math.rad(90))
	PreviewArea.CFrame = CFrame.new(Vector3.new(0, 0, 0)) * horizontalCylinderRotation

	self.previewConnection = RunService.RenderStepped:Connect(function(): ()
		local targetPos = getMousePosition()
		if targetPos then
			local snapped = snapToGridXZ(targetPos)
			local cframe = CFrame.new(snapped)
			PreviewModel:PivotTo(cframe * faceEnemySpawnRotation)
			PreviewArea.CFrame = cframe * horizontalCylinderRotation
		end
	end)
end

function PreviewController:Stop(): ()
	if self.previewConnection then
		self.previewConnection:Disconnect()
		self.previewConnection = nil
	end
	if PreviewModel then
		PreviewModel:Destroy()
		PreviewModel = nil
	end
	if PreviewArea then
		PreviewArea:Destroy()
		PreviewArea = nil
	end
	CurrentItemName = ""
	CurrentItemType = ""
end

function PreviewController:RemoveAllItems(): ()
	bridge:InvokeServerAsync({
		[actionIdentifier] = "RemoveAllItems",
		data = {},
	})
end

return PreviewController
