local MapService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local Debug = require(ReplicatedStorage.Utility.Debug)(script)

-- === ENUMS
local Blocks = require(ReplicatedStorage.Enums.blocks)

local CONTAINER_TYPES = { "BLOCK", "ENEMIES", "MELEE", "RANGED", "SPIKES" }
local SLOT_ATTRIBUTE = "MAP_SLOT"
local SUB_SLOT_ATTRIBUTE = "MAP_SUB_SLOT"

-- === GLOBAL FUNCTIONS
function MapService:Init(): () end

function MapService:AddItemInDatabase(
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
		item:SetAttribute(SLOT_ATTRIBUTE, tostring(slot))
		item:SetAttribute(SUB_SLOT_ATTRIBUTE, tostring(subSlot))
		item.Parent = workspace.runtime[player.UserId][unitType]

		if isBrainrot then
			-- Add animation if unit is Brainrot
			MapService:PlayIdleAnimation(item)
		end
	end
end

function MapService:PlayIdleAnimation(model: Model): ()
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
	local stringSlot = tostring(slot)
	local stringSubSlot = tostring(subSlot)
	local instance: Instance?
	for _, child in ipairs(container:GetChildren()) do
		if child.Name == itemName then
			local childSlot = child:GetAttribute(SLOT_ATTRIBUTE)
			local childSubSlot = child:GetAttribute(SUB_SLOT_ATTRIBUTE)
			if childSlot == stringSlot and childSubSlot == stringSubSlot then
				instance = child
				break
			end
		end
	end
	if not instance then
		instance = container:FindFirstChild(itemName)
	end
	if instance then
		instance:Destroy()
	else
		Debug.warn(
			`Instance not found in workspace: {itemName} (slot {slot}, subSlot {subSlot}) of type {itemType} for player {player.Name}`
		)
	end
end

function MapService:ClearMapItems(player: Player): table
	Debug.print("Clearing all map items for player:", player.Name)
	local itemsOnMap = PlayerDataHandler:Get(player, "itemsOnMap")
	local removedItems: table = {}
	for _, item in ipairs(itemsOnMap) do
		if not removedItems[item.Type] then
			removedItems[item.Type] = {}
		end
		if not removedItems[item.Type][item.Name] then
			removedItems[item.Type][item.Name] = 0
		end
		removedItems[item.Type][item.Name] += 1
	end
	PlayerDataHandler:Set(player, "itemsOnMap", {})
	for _, itemType in ipairs(CONTAINER_TYPES) do
		local container = workspace.runtime[player.UserId][itemType]
		local items = container:GetChildren()
		for _, item in ipairs(items) do
			item:Destroy()
		end
	end
	return removedItems
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

function MapService:RestartBaseMap(player: Player): ()
	for _, itemType in ipairs(CONTAINER_TYPES) do
		local container = workspace.runtime[player.UserId][itemType]
		local items = container:GetChildren()
		for _, item in ipairs(items) do
			item:Destroy()
		end
	end
	MapService:InitMapForPlayer(player)
end

return MapService
