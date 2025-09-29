local WaveService = {}

-- Init Bridg Net
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local EnemyService = require(ServerScriptService.Modules.EnemyService)
local bridge = BridgeNet2.ReferenceBridge("WaveService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

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
	
	task.spawn(function()
		local currentWave = player:SetAttribute("CURRENT_WAVE") or 1
		WaveService:SpawnEnemy(player, currentWave)
	end)
end

function WaveService:SpawnEnemy(player: Player, currentWave: number)
	local base = BaseService:GetBase(player)
	local enemyFolder = UtilService:WaitForDescendants(base, "baseTemplate", "enemy")
	local enemySpawns = {}

	for _, value in enemyFolder:GetChildren() do
		table.insert(enemySpawns, value)
	end

	if base then
		for i = 1, 1 do
			task.spawn(function()
				local enemySpawn = enemySpawns[math.random(1, #enemySpawns)]
				EnemyService:Create(player, enemySpawn)
			end)
			task.wait(0.2)
		end
	end
end

return WaveService
