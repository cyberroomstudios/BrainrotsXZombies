local WaveService = {}

-- Init Bridg Net
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("WaveService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local EnemyService = require(ServerScriptService.Modules.EnemyService)
local ThreadService = require(ServerScriptService.Modules.ThreadService)

function WaveService:Init()
	WaveService:InitBridgeListener()
end

function WaveService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "StartWave" then
			WaveService:StartWave(player)
		end
	end
end

function WaveService:StartWave(player: Player)
	if player:GetAttribute("GAME_ON") then
		return
	end

	player:SetAttribute("GAME_ON", true)

	-- Inicia a verificação dos Ranged
	ThreadService:StartRanged(player)

	task.spawn(function()
		player:SetAttribute("BASE_LIFE", 100)
		player:SetAttribute("CURRENT_WAVE", 1)
		EnemyService:SpawnEnemy(player, 1)
	end)
end

return WaveService
