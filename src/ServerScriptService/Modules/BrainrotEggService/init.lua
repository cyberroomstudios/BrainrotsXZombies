local BrainrotEggService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local brainrotEgg = require(ReplicatedStorage.Enums.brainrotEgg)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local BaseService = require(ServerScriptService.Modules.BaseService)
local bridge = BridgeNet2.ReferenceBridge("BrainrotEggService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

function BrainrotEggService:Init()
	BrainrotEggService:InitBridgeListener()
end

function BrainrotEggService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "GetEggs" then
			return BrainrotEggService:GetEggsFromBackpack(player)
		end
	end
end

function BrainrotEggService:GiveEgg(player: Player, brainrotEggName: string)
	if not brainrotEgg[brainrotEggName] then
		warn("Brainrot Egg Not Found")
		return
	end

	PlayerDataHandler:Update(player, "brainrotEggsBackpack", function(current)
		if current[brainrotEggName] then
			current[brainrotEggName] = current[brainrotEggName] + 1
			return current
		end

		current[brainrotEggName] = 1

		return current
	end)
end

function BrainrotEggService:GetEggsFromBackpack(player: Player)
	return PlayerDataHandler:Get(player, "brainrotEggsBackpack")
end

function BrainrotEggService:GetNextEggSlotMap(player: Player)
	local base = BaseService:GetBase(player)
	local platforms = base:WaitForChild("platforms")
	local eggFolder = platforms:WaitForChild("egg")

	if eggFolder then
		local plots = eggFolder:GetChildren()

		for _, value in plots do
		end
	end
end

function BrainrotEggService:SetEggInMap(player: Player)

	--local platforms
end

return BrainrotEggService
