local PlayerDataHandler = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PlayerLoaded")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === ON START
local bridgePlayer = BridgeNet2.ReferenceBridge("Player") -- REMOVE? Unused right now...
bridgePlayer.OnServerInvoke = function(player, data)
	if data[actionIdentifier] == "getPlayerData" then
		local playerData = PlayerDataHandler:GetAll(player)
		return {
			[statusIdentifier] = "success",
			[messageIdentifier] = "Player data retrieved",
			playerData = playerData,
		}
	end
end

-- === CONSTANTS
local TIMEOUT_SECONDS: number = 30
local DATA_TEMPLATE: { [string]: any } = {
	totalPlaytime = 0,
	itemsOnMap = {}, -- Representa todos os itens que estão setados no mapa
	unitsBackpack = {}, -- Representa todas as unidades que estão no backpack do jogador
	brainrotEggsBackpack = {}, -- Representa todas as os ovos de brainrots que estão no backpack do jogador
	weapons = {}, -- Representa todas as armas que o jogador possui
	money = 0, -- Representa o dinheiro do jogador
	restockCycle = 0,
	maxWave = 0, -- Representa a onda máxima que aquele jogador chegou
	robuxSpent = 0, -- Representa a quantidade de robux gasto pelo jogador
}

-- === MODULES
local ProfileService = require(ServerScriptService.libs.ProfileService)

-- === LOCAL VARIABLES
local CachedJoinTimestamps: { [Player]: number } = {}
local ProfileStore = ProfileService.GetProfileStore("PlayerProfile", DATA_TEMPLATE)
local Profiles: { [Player]: table } = {}
local Observers: { [string]: { (player: Player, key: string) -> () } } = {}

-- === LOCAL FUNCTIONS
local function onPlayerAdded(player: Player): ()
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function(): ()
			Profiles[player] = nil
			player:Kick()
		end)

		if not player:IsDescendantOf(Players) then
			profile:Release()
		else
			Profiles[player] = profile
			CachedJoinTimestamps[player] = os.time()
		end

		profile:Reconcile()
		bridge:Fire(player, {
			[actionIdentifier] = "PlayerLoaded",
			[statusIdentifier] = "success",
			[messageIdentifier] = "Player data loaded",
			data = profile.Data,
		})
	else
		player:Kick()
	end
end

local function onPlayerRemoving(player: Player): ()
	local joinTimestamp = CachedJoinTimestamps[player]
	local leaveTimestamp = os.time()
	local playtime = leaveTimestamp - joinTimestamp

	PlayerDataHandler:Update(player, "totalPlaytime", function(currentPlaytime: number): number
		return currentPlaytime + playtime
	end)

	if Profiles[player] then
		Profiles[player]:Release()
	end
end

local function getProfile(player: Player): table
	-- Try waiting for the profile to load but don't wait too long
	local startTime = os.time()
	while not Profiles[player] and os.time() - startTime < TIMEOUT_SECONDS do
		task.wait()
	end
	assert(Profiles[player], `Profile not found for player "{player.Name}"`)
	return Profiles[player]
end

local function notifyObservers(player: Player, key: string): ()
	local listeners = Observers[key]
	if not listeners then
		return
	end

	for _, observer in ipairs(table.clone(listeners)) do
		task.spawn(observer, player, key)
	end
end

function PlayerDataHandler:Wipe(player: Player): ()
	local success = ProfileStore:WipeProfileAsync("Player_" .. player.UserId)
	if success then
		player:Kick()
	end
end

-- Getter/Setter methods
function PlayerDataHandler:Get(player: Player, key: string): any?
	local profile = getProfile(player)
	-- assert(profile.Data[key], `Key "{key}" not found in player "{player.Name}" data.`)
	return profile.Data[key]
end

function PlayerDataHandler:Set(player: Player, key: string, value: any): ()
	local profile = getProfile(player)
	-- Check if key exists
	-- assert(profile.Data[key], `Key "{key}" not found in player "{player.Name}" data.`)
	-- Check if there is a type mismatch
	assert(
		type(value) == type(profile.Data[key]),
		`Value type mismatch for key "{key}" in player "{player.Name}" data.`
	)
	profile.Data[key] = value
	notifyObservers(player, key)
end

function PlayerDataHandler:Update(player: Player, key: string, callback: (oldValue: any) -> any): ()
	local oldData = self:Get(player, key)
	local newData = callback(oldData)
	self:Set(player, key, newData)
end

function PlayerDataHandler:Observe(key: string, callback: (player: Player, key: string) -> ()): ()
	assert(type(key) == "string", "PlayerDataHandler:Observe requires key to be a string")
	assert(type(callback) == "function", "PlayerDataHandler:Observe requires callback to be a function")
	local listeners = Observers[key]
	if not listeners then
		listeners = {}
		Observers[key] = listeners
	end
	table.insert(listeners, callback)
end

function PlayerDataHandler:GetAll(player: Player): { [string]: any }
	return getProfile(player).Data
end

function PlayerDataHandler:Init(): ()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return PlayerDataHandler
