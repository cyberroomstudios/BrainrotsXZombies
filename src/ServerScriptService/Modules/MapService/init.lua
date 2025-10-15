local MapService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local Debug = require(ReplicatedStorage.Utility.Debug)(script)
local blocks = require(ReplicatedStorage.Enums.blocks)
local melee = require(ReplicatedStorage.Enums.melee)
local ranged = require(ReplicatedStorage.Enums.ranged)
local spikes = require(ReplicatedStorage.Enums.spikes)

-- === ENUMS
local Blocks = require(ReplicatedStorage.Enums.blocks)

local CONTAINER_TYPES = { "BLOCK", "ENEMIES", "MELEE", "RANGED", "SPIKES" }

-- === GLOBAL FUNCTIONS
function MapService:Init(): () end

local unitTypesEnums = {
	["BLOCK"] = blocks,
	["MELEE"] = melee,
	["RANGED"] = ranged,
	["SPIKES"] = spikes,
}

function MapService:AddItemInDataBase(
	player: Player,
	itemType: string,
	itemName: string,
	slot: string,
	subSlot: string,
	isBrainrot: boolean
): ()
	local data = {
		Type = itemType,
		Name = itemName,
		Slot = slot,
		SubSlot = subSlot,
		IsBrainrot = isBrainrot,
	}
	PlayerDataHandler:Update(player, "itemsOnMap", function(current: table): ()
		table.insert(current, data)
		return current
	end)
end

function MapService:GetItemFromTypeAndName(unitType: string, unitName: string): Model?
	local unitsFolder: Folder = ReplicatedStorage.developer.units
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
			Debug.warn(`Item name not found: {unitName} in type {unitType} folder`)
		end
	else
		Debug.warn(`Item type not found: {unitType}`)
	end
end

function MapService:SetItemOnMap(
	player: Player,
	unitType: string,
	unitName: string,
	slot: number,
	subSlot: number,
	isBrainrot: boolean
): ()
	local base = BaseService:GetBase(player)
	local initBaserefPosition = BaseService:GetInitBaseRefPosition(player)
	if base then
		local baseTemplate = UtilService:WaitForDescendants(base, "baseTemplate")
		local baseSlots = UtilService:WaitForDescendants(baseTemplate, "baseSlots")
		local slots = UtilService:WaitForDescendants(baseSlots, "slots")
		local slotModel = UtilService:WaitForDescendants(slots, slot)
		local subSlotPart = UtilService:WaitForDescendants(slotModel, subSlot)

		local position = subSlotPart.Position
		local item = MapService:GetItemFromTypeAndName(unitType, unitName)
		local yOffset = (subSlotPart.Size.Y / 2) + (item.PrimaryPart.Size.Y / 2)

		local baseIndex = tonumber(base.Name)
		local rotation = CFrame.Angles(0, (baseIndex % 2 == 0 and 0 or math.rad(180)), 0)

		item:PivotTo(CFrame.new(position + Vector3.new(0, yOffset, 0)) * rotation)
		item:SetAttribute("IS_BRAINROT", isBrainrot)

		item:SetAttribute("HP", unitTypesEnums[unitType][unitName].HP)
		item:SetAttribute("CURRENT_HP", unitTypesEnums[unitType][unitName].HP)
		item.Parent = workspace.runtime[player.UserId][unitType]
		
		if item:FindFirstChild("XP") then
			item:FindFirstChild("XP").Enabled = false
		end
		if isBrainrot then
			-- Add animation if unit is Brainrot
			-- Adiciona a animação se for brainrot
			MapService:CreateWalkAnimation(item)
		end
	end
end

function MapService:CreateWalkAnimation(model: Model): ()
	local AnimationController: AnimationController = model:FindFirstChild("AnimationController")
	local idle = AnimationController:LoadAnimation(model.Animations.Idle)
	idle.Priority = Enum.AnimationPriority.Idle
	idle:Play()
end

function MapService:RemoveItemFromMap(
	player: Player,
	itemType: string,
	itemName: string,
	slot: number,
	subSlot: number
): ()
	PlayerDataHandler:Update(player, "itemsOnMap", function(current: table): table
		for index, item in ipairs(current) do
			if item.Type == itemType and item.Name == itemName and item.Slot == slot and item.SubSlot == subSlot then
				table.remove(current, index)
				break
			end
		end
		return current
	end)

	local container = workspace.runtime[player.UserId][itemType]
	local instance = container:FindFirstChild(itemName)
	if instance then
		instance:Destroy()
	else
		Debug.warn(`Instance not found in workspace: {itemName} of type {itemType} for player {player.Name}`)
	end
end

function MapService:ClearMapItems(player: Player): ()
	print("Clearing all map items for player:", player.Name)
	PlayerDataHandler:Set(player, "itemsOnMap", {})
	for _, itemType in ipairs(CONTAINER_TYPES) do
		local container = workspace.runtime[player.UserId][itemType]
		local items = container:GetChildren()
		for _, item in ipairs(items) do
			item:Destroy()
		end
	end
end

function MapService:InitMapForPlayer(player: Player): ()
	local items = PlayerDataHandler:Get(player, "itemsOnMap")
	for _, item in items do
		local itemType = item.Type
		local itemName = item.Name
		local slot = item.Slot
		local subSlot = item.SubSlot
		local isBrainrot = item.IsBrainrot
		MapService:SetItemOnMap(player, itemType, itemName, slot, subSlot, isBrainrot)
	end
end

function MapService:RestartBaseMap(player: Player)
	local function clean(folderName: string)
		local parts = workspace.runtime[player.UserId][folderName]:GetChildren()

		for _, part in parts do
			part:Destroy()
		end
	end

	clean("Enemys")
	clean("RANGED")
	clean("BLOCK")
	clean("MELEE")
	clean("SPIKES")

	MapService:InitMapFromPlayer(player)
end

return MapService
