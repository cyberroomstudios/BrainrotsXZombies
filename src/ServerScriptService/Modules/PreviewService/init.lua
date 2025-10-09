local PreviewService = {}

-- Init Bridg Net
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)

local bridge = BridgeNet2.ReferenceBridge("PreviewService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local MapService = require(ServerScriptService.Modules.MapService)

function PreviewService:Init()
	PreviewService:InitBridgeListener()
end

function PreviewService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "SetItem" then
			local itemType = data.data.ItemType
			local itemName = data.data.ItemName
			local slot = data.data.Slot
			local subSlot = data.data.SubSlot
			local isBrainrot = data.data.IsBrainrot
			
			PreviewService:SetItem(player, itemType, itemName, slot, subSlot, isBrainrot)
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
)
	MapService:SetItemOnMap(player, itemType, itemName, slot, subSlot, isBrainrot)
	MapService:AddItemInDataBase(player, itemType, itemName, slot, subSlot, isBrainrot)
end

return PreviewService
