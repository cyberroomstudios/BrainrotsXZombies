local PreviewService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PreviewService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local BaseService = require(ServerScriptService.Modules.BaseService)
local MapService = require(ServerScriptService.Modules.MapService)
local UnitService = require(ServerScriptService.Modules.UnitService)
local UtilService = require(ServerScriptService.Modules.UtilService)

-- === GLOBAL FUNCTIONS
function PreviewService:Init(): ()
	PreviewService:InitBridgeListener()
end

function PreviewService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): ()
		if data[actionIdentifier] == "SetItem" then
			local itemType = data.data.ItemType
			local itemName = data.data.ItemName
			local slot = data.data.Slot
			local subSlot = data.data.SubSlot
			local isBrainrot = data.data.IsBrainrot
			PreviewService:SetItem(player, itemType, itemName, slot, subSlot, isBrainrot)
		elseif data[actionIdentifier] == "RemoveItem" then
			local itemType = data.data.ItemType
			local itemName = data.data.ItemName
			local slot = data.data.Slot
			local subSlot = data.data.SubSlot
			PreviewService:RemoveItem(player, itemType, itemName, slot, subSlot)
		elseif data[actionIdentifier] == "RemoveAllItems" then
			PreviewService:RemoveAllItems(player)
		else
			return {
				[statusIdentifier] = "error",
				[messageIdentifier] = "Invalid action",
			}
		end
	end
end

function PreviewService:SetItem(
	player: Player,
	itemType: string,
	itemName: string,
	slot: number,
	subSlot: number,
	isBrainrot: boolean
): ()
	if UnitService:Consume(player, itemName, itemType) then
		MapService:SetItemOnMap(player, itemType, itemName, slot, subSlot, isBrainrot)
		MapService:AddItemInDatabase(player, itemType, itemName, slot, subSlot, isBrainrot)
	end
end

function PreviewService:RemoveItem(
	player: Player,
	itemType: string,
	itemName: string,
	slot: number,
	subSlot: number
): ()
	MapService:RemoveItemFromMap(player, itemType, itemName, slot, subSlot)
	UnitService:Give(player, itemName, itemType)
end

function PreviewService:RemoveAllItems(player: Player): ()
	local removedItems = MapService:ClearMapItems(player)
	for unitType, units in pairs(removedItems) do
		for unitName, amount in pairs(units) do
			UnitService:Give(player, unitName, unitType, amount)
		end
	end
end

return PreviewService
