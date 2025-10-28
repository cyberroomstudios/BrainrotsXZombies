local RankingService = {}

-- === SERVICES
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("RankingService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === CUSTOM TYPES
export type RankingEntry = {
	UserId: number,
	Value: number,
}

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local RankingGui = require(script.RankingGui)

-- === ENUMS
local RankingType = require(ReplicatedStorage.Enums.rankingType)

-- === CONSTANTS
local DEFAULT_RANKING_COUNT: number = 10
local MAX_RANKING_COUNT: number = 100
local RANKING_PREFIX: string = "Ranking_"
local ACTIONS = table.freeze({
	GetRanking = "GetRanking",
	UpdatePlayer = "UpdatePlayer",
})
local RANKING_TYPES: { string } = table.freeze({
	RankingType.Playtime,
	RankingType.Money,
	RankingType.MaxWave,
	RankingType.RobuxSpent,
})
local PLAYER_DATA_KEYS_BY_TYPE: { [string]: string } = table.freeze({
	[RankingType.Playtime] = "totalPlaytime",
	[RankingType.Money] = "money",
	[RankingType.MaxWave] = "maxWave",
	[RankingType.RobuxSpent] = "robuxSpent",
})
local RANKINGS_FOLDER_NAME: string = "rankings"
local MAX_DISPLAYED_RANKS: number = DEFAULT_RANKING_COUNT

-- === LOCAL VARIABLES
local DataStores: { [string]: OrderedDataStore } = {}
local RankingBoards: { [string]: any } = {}
local DisplayNameCache: { [number]: string } = {}

-- === LOCAL FUNCTIONS
local function getDataStoreName(rankingType: string): string
	return RANKING_PREFIX .. rankingType
end

local function isValidRankingType(rankingType: string?): boolean
	return rankingType ~= nil and PLAYER_DATA_KEYS_BY_TYPE[rankingType] ~= nil
end

local function getOrderedStore(rankingType: string): OrderedDataStore
	if DataStores[rankingType] == nil then
		DataStores[rankingType] = DataStoreService:GetOrderedDataStore(getDataStoreName(rankingType))
	end
	return DataStores[rankingType]
end

local function findSurfaceGui(container: Instance): SurfaceGui?
	if container:IsA("SurfaceGui") then
		return container
	end

	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("SurfaceGui") then
			return descendant
		end
	end

	return nil
end

local function getPlayerStat(player: Player, rankingType: string): number?
	local key = PLAYER_DATA_KEYS_BY_TYPE[rankingType]
	if not key then
		return nil
	end
	local success, value = pcall(function(): number?
		return PlayerDataHandler:Get(player, key)
	end)
	if not success then
		warn(`[RankingService] Failed to read {key} for {player.Name}: {value}`)
		return nil
	end
	if typeof(value) ~= "number" then
		warn(`[RankingService] Invalid data type for {key} for {player.Name}: {typeof(value)}`)
		return nil
	end
	return value
end

local function shouldUpdateScore(
	store: OrderedDataStore,
	rankingType: string,
	userKey: string,
	newValue: number
): boolean
	local success, currentValue = pcall(function(): (number, DataStoreKeyInfo)
		return store:GetAsync(userKey)
	end)
	if success and typeof(currentValue) == "number" then
		if currentValue == newValue then
			return false
		end
		if not RankingType.Compare(rankingType, currentValue, newValue) then
			return false
		end
	elseif not success then
		warn(`[RankingService] Failed to fetch current score for {rankingType}: {currentValue}`)
	end
	return true
end

local function writeScore(store: OrderedDataStore, rankingType: string, userKey: string, value: number): ()
	local success, err = pcall(function(): ()
		store:SetAsync(userKey, value)
	end)
	if not success then
		warn(`[RankingService] Failed to write score for {rankingType}: {err}`)
	end
end

local function fetchRankingEntries(store: OrderedDataStore, rankingType: string, count: number): { RankingEntry }?
	local success, pages = pcall(function(): DataStorePages
		return store:GetSortedAsync(RankingType.IsAscending(rankingType), count)
	end)
	if not success then
		warn(`[RankingService] Failed to fetch ranking entries for {rankingType}: {pages}`)
		return nil
	end
	local entries: { RankingEntry } = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(entry.key) or entry.key
		table.insert(entries, {
			UserId = userId,
			Value = entry.value,
		})
	end
	return entries
end

function RankingService.ResolveDisplayName(userId: number?): string
	if userId == nil then
		return "Unknown"
	end

	local cached = DisplayNameCache[userId]
	if cached then
		return cached
	end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		local displayName = player.DisplayName ~= "" and player.DisplayName or player.Name
		DisplayNameCache[userId] = displayName
		return displayName
	end

	local success, result = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local resolvedName = success and typeof(result) == "string" and result or string.format("User %d", userId)
	DisplayNameCache[userId] = resolvedName
	return resolvedName
end

function RankingService:InitRankingBoards(): ()
	table.clear(RankingBoards)

	local rankingsFolder = Workspace:FindFirstChild(RANKINGS_FOLDER_NAME)
	if not rankingsFolder then
		rankingsFolder = Workspace:WaitForChild(RANKINGS_FOLDER_NAME, 5)
	end
	if not rankingsFolder then
		warn(`[RankingService] Rankings folder "{RANKINGS_FOLDER_NAME}" not found in workspace`)
		return
	end

	for _, rankingType in ipairs(RANKING_TYPES) do
		local container = rankingsFolder:FindFirstChild(rankingType)
		if not container then
			warn(`[RankingService] Ranking model "{rankingType}" missing under workspace.{RANKINGS_FOLDER_NAME}`)
		else
			local surfaceGui = findSurfaceGui(container)
			if not surfaceGui then
				warn(`[RankingService] SurfaceGui not found for ranking "{rankingType}"`)
			else
				RankingBoards[rankingType] = RankingGui.new(surfaceGui, {
					rankingType = rankingType,
					title = rankingType,
					maxEntries = MAX_DISPLAYED_RANKS,
					nameResolver = RankingService.ResolveDisplayName,
				})
			end
		end
	end
end

function RankingService:InitDataObservers(): ()
	for rankingType, key in pairs(PLAYER_DATA_KEYS_BY_TYPE) do
		PlayerDataHandler:Observe(key, function(player: Player)
			RankingService:OnTrackedStatChanged(player, rankingType)
		end)
	end
end

function RankingService:OnTrackedStatChanged(player: Player, rankingType: string): ()
	if not isValidRankingType(rankingType) then
		return
	end

	local value = getPlayerStat(player, rankingType)
	if value == nil then
		return
	end

	RankingService:UpdatePlayerRanking(player, rankingType, value)
	RankingService:RefreshRankingDisplay(rankingType)
end

function RankingService:RefreshRankingDisplay(rankingType: string): ()
	if not isValidRankingType(rankingType) then
		return
	end

	local board = RankingBoards[rankingType]
	if not board then
		return
	end

	local entries = RankingService:GetRanking(rankingType, MAX_DISPLAYED_RANKS)
	if not entries then
		return
	end

	board:SetEntries(entries)
end

function RankingService:RefreshAllRankingDisplays(): ()
	for _, rankingType in ipairs(RANKING_TYPES) do
		RankingService:RefreshRankingDisplay(rankingType)
	end
end

-- === GLOBAL FUNCTIONS
function RankingService:Init(): ()
	RankingService:InitDataStores()
	RankingService:InitBridgeListener()
	RankingService:InitRankingBoards()
	RankingService:InitDataObservers()
	RankingService:ConnectPlayerSignals()
	RankingService:RefreshAllRankingDisplays()
end

function RankingService:InitDataStores(): ()
	for _, rankingType in ipairs(RANKING_TYPES) do
		getOrderedStore(rankingType)
	end
end

function RankingService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): table
		if typeof(data) ~= "table" then
			return {
				[statusIdentifier] = "error",
				[messageIdentifier] = "InvalidPayload",
			}
		end

		local action = data[actionIdentifier]
		if action == ACTIONS.GetRanking then
			local rankingType = data.rankingType
			if not isValidRankingType(rankingType) then
				return {
					[statusIdentifier] = "error",
					[messageIdentifier] = "InvalidRankingType",
				}
			end

			local count: number? = data.count
			if count ~= nil and typeof(count) ~= "number" then
				count = tonumber(count)
			end
			local entries = RankingService:GetRanking(rankingType, count)
			if not entries then
				return {
					[statusIdentifier] = "error",
					[messageIdentifier] = "DataStoreError",
				}
			end

			return {
				[statusIdentifier] = "success",
				[messageIdentifier] = "RankingFetched",
				rankingType = rankingType,
				entries = entries,
			}
		elseif action == ACTIONS.UpdatePlayer then
			local rankingType = data.rankingType
			if rankingType and not isValidRankingType(rankingType) then
				return {
					[statusIdentifier] = "error",
					[messageIdentifier] = "InvalidRankingType",
				}
			end
			RankingService:UpdatePlayer(player, rankingType)
			return {
				[statusIdentifier] = "success",
				[messageIdentifier] = "PlayerUpdated",
			}
		end

		return {
			[statusIdentifier] = "error",
			[messageIdentifier] = "UnknownAction",
		}
	end
end

function RankingService:ConnectPlayerSignals(): ()
	local function deferUpdatePlayer(player: Player): ()
		task.defer(RankingService.UpdatePlayer, RankingService, player)
	end

	for _, player in Players:GetPlayers() do
		deferUpdatePlayer(player)
	end
	Players.PlayerAdded:Connect(deferUpdatePlayer)
	Players.PlayerRemoving:Connect(deferUpdatePlayer)
end

function RankingService:UpdatePlayer(player: Player, rankingType: string?): ()
	if rankingType ~= nil then
		if not isValidRankingType(rankingType) then
			warn(`[RankingService] Invalid ranking type provided: {rankingType}`)
			return
		end

		local value = getPlayerStat(player, rankingType)
		if value == nil then
			return
		end

		RankingService:UpdatePlayerRanking(player, rankingType, value)
		RankingService:RefreshRankingDisplay(rankingType)
		return
	end

	local hasUpdated = false
	for _, rankingTypeName in ipairs(RANKING_TYPES) do
		local value = getPlayerStat(player, rankingTypeName)
		if value ~= nil then
			RankingService:UpdatePlayerRanking(player, rankingTypeName, value)
			hasUpdated = true
		end
	end

	if hasUpdated then
		RankingService:RefreshAllRankingDisplays()
	end
end

function RankingService:UpdatePlayerRanking(player: Player, rankingType: string, overrideValue: number?): ()
	if not isValidRankingType(rankingType) then
		warn(`[RankingService] Invalid ranking type provided: {rankingType}`)
		return
	end
	local value = overrideValue
	if value == nil then
		value = getPlayerStat(player, rankingType)
		if value == nil then
			warn(`[RankingService] Could not retrieve player stat for {player.Name} and ranking type {rankingType}`)
			return
		end
	end

	local store = getOrderedStore(rankingType)
	local userKey = tostring(player.UserId)
	if shouldUpdateScore(store, rankingType, userKey, value) then
		writeScore(store, rankingType, userKey, value)
	end
end

function RankingService:GetRanking(rankingType: string, count: number?): { RankingEntry }?
	if not isValidRankingType(rankingType) then
		warn(`[RankingService] Invalid ranking type provided: {rankingType}`)
		return nil
	end

	count = count or DEFAULT_RANKING_COUNT
	count = math.clamp(math.floor(count), 1, MAX_RANKING_COUNT)

	local store = getOrderedStore(rankingType)
	return fetchRankingEntries(store, rankingType, count)
end

return RankingService
