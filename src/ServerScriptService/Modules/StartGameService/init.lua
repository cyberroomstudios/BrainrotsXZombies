local StartGameService = {}
local Players = game:GetService("Players")

-- Init Bridg Net
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local BaseService = require(ServerScriptService.Modules.BaseService)
local MapService = require(ServerScriptService.Modules.MapService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local UnitService = require(ServerScriptService.Modules.UnitService)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local bridge = BridgeNet2.ReferenceBridge("StartGameService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local playerInitializer = {}

function StartGameService:Init()
	StartGameService:InitBridgeListener()

	Players.PlayerRemoving:Connect(function(player)
		playerInitializer[player] = false
	end)
end

function StartGameService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "Start" then
			-- Segurança para evitar que seja inicializado mais de uma vez
			if playerInitializer[player] then
				warn("User already configured")
				return false
			end

			-- Criando a pasta do Player
			StartGameService:CreatePlayerFolder(player)

			-- Alocando a Base
			BaseService:Allocate(player)

			MapService:InitMapFromPlayer(player)

			StartGameService:InitPlayerAtributes(player)

			StartGameService:CreatePlayerAttributes(player)
			--	UnitService:Give(player, "TowerLevel1", "RANGED")
			--	UnitService:Give(player, "TowerLevel2", "RANGED")
			--	UnitService:Give(player, "TowerLevel3", "RANGED")
			-- UnitService:Give(player, "TowerLevel4", "RANGED")

			--	UnitService:Give(player, "cappuccinoAssassino", "MELEE")
			--			UnitService:Give(player, "tungTungSahur", "MELEE")
			--			UnitService:Give(player, "odin", "MELEE")

			--			UnitService:Give(player, "Tower1", "RANGED")
			--	UnitService:Give(player, "bobritoBandito", "RANGED")
			--	UnitService:Give(player, "Noobini", "RANGED")

			--	UnitService:Give(player, "blue", "BLOCK")
		end
	end
end

function StartGameService:CreatePlayerFolder(player: Player)
	local playerFolder = Instance.new("Folder", workspace.runtime)
	playerFolder.Name = player.UserId

	local enemysFolder = Instance.new("Folder", playerFolder)
	enemysFolder.Name = "Enemys"

	local rangedUnitFolder = Instance.new("Folder", playerFolder)
	rangedUnitFolder.Name = "RANGED"

	local BlockUnitFolder = Instance.new("Folder", playerFolder)
	BlockUnitFolder.Name = "BLOCK"

	local meleeUnitFolder = Instance.new("Folder", playerFolder)
	meleeUnitFolder.Name = "MELEE"
end

function StartGameService:CreatePlayerAttributes(player: Player)
	local function getBaseStoreSpawn()
		local spawn = UtilService:WaitForDescendants(workspace, "map", "stores", "base", "Spawn")

		if not spawn then
			warn("[ERROR] Base Store Spawn not found! ")
			return
		end

		return spawn
	end

	local baseSpawn = getBaseStoreSpawn()

	if baseSpawn then
		player:SetAttribute("SPAWN_BASE_STORE_CFRAME", baseSpawn.CFrame)
	end
end

function StartGameService:InitPlayerAtributes(player: Player)
	-- Inicializando o Dinheiro
	local money = PlayerDataHandler:Get(player, "money")
	player:SetAttribute("MONEY", money)
end

return StartGameService
