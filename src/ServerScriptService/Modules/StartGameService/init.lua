local StartGameService = {}

-- === SERVICES
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("StartGameService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local Debug = require(ReplicatedStorage.Utility.Debug)(script)
local BaseService = require(ServerScriptService.Modules.BaseService)
local BrainrotEggService = require(ServerScriptService.Modules.BrainrotEggService)
local MapService = require(ServerScriptService.Modules.MapService)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local UnitService = require(ServerScriptService.Modules.UnitService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local WeaponService = require(ServerScriptService.Modules.WeaponService)

-- === LOCAL VARIABLES
local ReadyPlayers: { [Player]: boolean } = {}

-- === LOCAL FUNCTIONS
local function createFolder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- === GLOBAL FUNCTIONS
function StartGameService:Init()
	StartGameService:InitBridgeListener()
	Players.PlayerRemoving:Connect(function(player: Player): ()
		ReadyPlayers[player] = false
	end)
end

function StartGameService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): ()
		if data[actionIdentifier] == "Start" then
			-- Avoid multiple initializations:
			if ReadyPlayers[player] then
				warn(`Player {player.Name} already initialized!`)
				return false
			end

			StartGameService:CreatePlayerFolder(player)
			BaseService:Allocate(player)
			MapService:InitMapForPlayer(player)
			BrainrotEggService:InitEggsForPlayer(player)
			StartGameService:InitPlayerAtributes(player)
			StartGameService:CreatePlayerAttributes(player)

			-- Give Units:
			-- UnitService:Give(player, "Blue", "BLOCK")
			-- UnitService:Give(player, "Orange", "BLOCK")
			-- UnitService:Give(player, "Yellow", "BLOCK")
			-- UnitService:Give(player, "CappuccinoAssassino", "MELEE")
			-- UnitService:Give(player, "TungTungSahur", "MELEE")
			-- UnitService:Give(player, "Odin", "MELEE")
			-- UnitService:Give(player, "Lirili", "MELEE")
			-- UnitService:Give(player, "TowerLevel1", "RANGED")
			-- UnitService:Give(player, "TowerLevel2", "RANGED")
			-- UnitService:Give(player, "TowerLevel3", "RANGED")
			-- UnitService:Give(player, "TowerLevel4", "RANGED")
			-- UnitService:Give(player, "BobritoBandito", "RANGED")
			-- UnitService:Give(player, "Noobini", "RANGED")
			-- UnitService:Give(player, "BobritoBandito", "RANGED")
			-- UnitService:Give(player, "TralaleroTralala", "RANGED")
			-- UnitService:Give(player, "BombardinoCrocodilo", "RANGED")
			-- UnitService:Give(player, "SpikesLevel1", "SPIKES")

			-- Give Weapons:
			WeaponService:Give(player, "Fist")
			WeaponService:Give(player, "Pistol")
			WeaponService:Give(player, "AK47")
			WeaponService:Give(player, "Uzi")
		end
	end
end

function StartGameService:CreatePlayerFolder(player: Player): ()
	local playerFolder = createFolder(workspace.runtime, tostring(player.UserId))
	createFolder(playerFolder, "ENEMIES")
	createFolder(playerFolder, "RANGED")
	createFolder(playerFolder, "BLOCK")
	createFolder(playerFolder, "MELEE")
	createFolder(playerFolder, "SPIKES")
end

function StartGameService:CreatePlayerAttributes(player: Player): ()
	local function getBaseShopSpawn(): Part?
		local spawn_ = UtilService:WaitForDescendants(workspace, "map", "stores", "base", "Spawn")
		if not spawn_ then
			warn("[ERROR] Base store spawn part not found!")
			return
		end
		return spawn_
	end
	local baseSpawn = getBaseShopSpawn()
	if baseSpawn then
		player:SetAttribute("SPAWN_BASE_STORE_CFRAME", baseSpawn.CFrame)
	end
end

function StartGameService:InitPlayerAtributes(player: Player): ()
	-- Money:
	local money = PlayerDataHandler:Get(player, "money")
	player:SetAttribute("MONEY", money) -- TODO add all Player attributes keys to a Enum
end

return StartGameService
