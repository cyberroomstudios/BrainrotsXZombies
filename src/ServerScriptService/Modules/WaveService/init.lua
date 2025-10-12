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
local Cycle1 = require(ReplicatedStorage.Cycles.Cycle1)

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
		WaveService:StartNewWave(player, 1, 1)
	end)
end

function WaveService:StartNewWave(player: Player, cycleNumber: number, waveNumber: number)
	player:SetAttribute("CURRENT_CYCLE", cycleNumber)
	player:SetAttribute("CURRENT_WAVE", waveNumber)

	if cycleNumber == 1 then
		local wave = Cycle1[waveNumber]

		if not wave then
			return
		end

		local amountBase = wave.AmountEnemies.Base
		local amountTank = wave.AmountEnemies.Tank
		local amountFast = wave.AmountEnemies.Fast
		local amountElite = wave.AmountEnemies.Elite
		local amountPlus = wave.AmountEnemies.Plus

		for i = 1, amountBase do
			EnemyService:SpawnEnemy(player, "Base")
			task.wait(1)
		end

		for i = 1, amountTank do
			EnemyService:SpawnEnemy(player, "Tank")
			task.wait(1)
		end

		for i = 1, amountFast do
			EnemyService:SpawnEnemy(player, "Fast")
			task.wait(1)
		end

		for i = 1, amountElite do
			EnemyService:SpawnEnemy(player, "Elite")
			task.wait(1)
		end

		for i = 1, amountPlus do
			EnemyService:SpawnEnemy(player, "Plus")
			task.wait(1)
		end
	end

	if cycleNumber == 2 then
	end
end

return WaveService
