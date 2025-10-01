local MapService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local UtilService = require(ServerScriptService.Modules.UtilService)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local BaseService = require(ServerScriptService.Modules.BaseService)

function MapService:Init() end

function MapService:AddItemInDataBase(player: Player, itemType: string, itemName: string, slot: string, subSlot: string)
	local itemOnMapId = PlayerDataHandler:Get(player, "itemOnMapId")
	local data = {
		Id = itemOnMapId + 1,
		Type = itemType,
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

function MapService:GetItemFromTypeAndName(unitType: string, unitName: string)
	local unitsFolder = ReplicatedStorage.developer.units
	local items = {
		["blocks"] = unitsFolder.blocks,
		["melee"] = unitsFolder.melee,
		["ranged"] = unitsFolder.ranged,
		["trap"] = unitsFolder.trap,
	}

	if items[unitType] then
		local item = items[unitType]:FindFirstChild(unitName)

		if item then
			return item:Clone()
		end
	end
end

function MapService:SetItemOnMap(player: Player, unitType: string, unitName: string, slot: number, subSlot: number)
	local base = BaseService:GetBase(player)
	if base then
		local baseTemplate = base.baseTemplate

		local baseTemplate = UtilService:WaitForDescendants(base, "baseTemplate")

		local baseSlots = UtilService:WaitForDescendants(baseTemplate, "baseSlots")

		local slots = UtilService:WaitForDescendants(baseSlots, "slots")

		local slotModel = UtilService:WaitForDescendants(slots, slot)

		local subSlotPart = UtilService:WaitForDescendants(slotModel, subSlot)

		local position = subSlotPart.Position
		local item = MapService:GetItemFromTypeAndName(unitType, unitName)
		local yOffset = (subSlotPart.Size.Y / 2) + (item.PrimaryPart.Size.Y / 2)

		item:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, yOffset, 0)))

		item.Parent = workspace.runtime[player.UserId][unitType]
	end
end

function MapService:InitMapFromPlayer(player: Player)
	local items = PlayerDataHandler:Get(player, "itemsOnMap")

	for _, item in items do
		local itemType = item.Type
		local itemName = item.Name
		local slot = item.Slot
		local subSlot = item.SubSlot

		MapService:SetItemOnMap(player, itemType, itemName, slot, subSlot)
	end
end
return MapService
