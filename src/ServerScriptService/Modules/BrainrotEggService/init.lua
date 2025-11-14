local BrainrotEggService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- === MODULES
local BaseService = require(ServerScriptService.Modules.BaseService)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("BrainrotEggService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === ENUMS
local BrainrotEgg = require(ReplicatedStorage.Enums.brainrotEgg)

-- === GLOBAL FUNCTIONS
function BrainrotEggService:Init(): ()
	BrainrotEggService:InitBridgeListener()
end

function BrainrotEggService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "GetEggs" then
			return BrainrotEggService:GetEggsFromBackpack(player)
		else
			return {
				[statusIdentifier] = "error",
				[messageIdentifier] = "Invalid action",
			}
		end
	end
end

function BrainrotEggService:GiveEgg(player: Player, brainrotEggName: string): ()
	if not BrainrotEgg[brainrotEggName] then
		warn("Brainrot Egg Not Found")
		return
	end

	PlayerDataHandler:Update(
		player,
		"brainrotEggsBackpack",
		function(current: { [string]: number }): { [string]: number }
			if current[brainrotEggName] then
				current[brainrotEggName] += 1
			else
				current[brainrotEggName] = 1
			end
			return current
		end
	)
end

function BrainrotEggService:GetEggsFromBackpack(player: Player): { [string]: number }
	return PlayerDataHandler:Get(player, "brainrotEggsBackpack")
end

function BrainrotEggService:GetNextEggSlotMap(player: Player)
	local base = BaseService:GetBase(player)
	local platforms = base and base:WaitForChild("platforms") or nil
	local eggFolder = platforms and platforms:FindFirstChild("egg") or nil

	if eggFolder then
		local plots = eggFolder:GetChildren()

		for _, value in ipairs(plots) do
			-- TODO: implement slot selection logic
		end
	end
end

function BrainrotEggService:SetEggInMap(player: Player)
	-- TODO: implement SetEggInMap
end

return BrainrotEggService
