local MapService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local UtilService = require(ServerScriptService.Modules.UtilService)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local BaseService = require(ServerScriptService.Modules.BaseService)

function MapService:Init() end

function MapService:AddItemInDataBase(player: Player, itemName: string, slot: string, subSlot: string)
	local itemOnMapId = PlayerDataHandler:Get(player, "itemOnMapId")
	local data = {
		Id = itemOnMapId + 1,
		Name = itemName,
		Slot = slot,
		SubSlot = subSlot,
	}

	PlayerDataHandler:Set(player, "itemOnMapId", itemOnMapId + 1)

	PlayerDataHandler:Update(player, "itemsOnMap", function(current)
		table.insert(current, data)
		return current
	end)
end

function MapService:SetItemOnMap(player: Player, itemName: string, slot: number, subSlot: number)
	local base = BaseService:GetBase(player)
	if base then
		local baseTemplate = base.baseTemplate

		local baseTemplate = UtilService:WaitForDescendants(base, "baseTemplate")

		local baseSlots = UtilService:WaitForDescendants(baseTemplate, "baseSlots")

		local slots = UtilService:WaitForDescendants(baseSlots, "slots")

		local slotModel = UtilService:WaitForDescendants(slots, slot)

		local subSlotPart = UtilService:WaitForDescendants(slotModel, subSlot)

		local position = subSlotPart.Position
		local item = ReplicatedStorage.developer.units.blocks[itemName]:Clone()
		local yOffset = (subSlotPart.Size.Y / 2) + (item.Size.Y / 2)
		item.Position = position + Vector3.new(0, yOffset, 0)
		item.Anchored = true
		item.Parent = workspace
	end
end

function MapService:InitMapFromPlayer(player: Player)
	local items = PlayerDataHandler:Get(player, "itemsOnMap")

	for _, item in items do
		local itemName = item.Name
		local slot = item.Slot
		local subSlot = item.SubSlot

		MapService:SetItemOnMap(player, itemName, slot, subSlot)
	end
end
return MapService
