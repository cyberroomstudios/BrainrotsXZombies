local StockService = {}

-- === SERVICES
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local TableKit = require(Utility.BridgeNet2.TableKit)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local Debug = require(Utility.Debug)(script)

-- === TYPES
local ET = require(ReplicatedStorage.Enums.T)

-- === ENUMS
local UnitsRarity = require(ReplicatedStorage.Enums.unitsRarity)
local Blocks = require(ReplicatedStorage.Enums.blocks)
local Melee = require(ReplicatedStorage.Enums.melee)
local Ranged = require(ReplicatedStorage.Enums.ranged)
local UnitService = require(ServerScriptService.Modules.UnitService)

local CategoryEnums: { [string]: { [string]: ET.Item } } = {
	Blocks = Blocks,
	Melee = Melee,
	Ranged = Ranged,
}

-- === CONSTANTS
local TIME_TO_RELOAD_STOCK: number = 60 * 5

-- === LOCAL VARIABLES
local GlobalStock = {
	Blocks = {},
	Melee = {},
	Ranged = {},
}
local PlayerStock = {}
local CurrentCycleId: number?

-- === LOCAL FUNCTIONS
local function sortByGuiOrder(t: table): ()
	table.sort(t, function(a, b)
		return a.GUI.Order < b.GUI.Order
	end)
end

local function getCycleIdFromUnix(unixTimestamp: number): number
	return math.floor(unixTimestamp / TIME_TO_RELOAD_STOCK)
end

local function getSecondsUntilNextCycle(unixTimestamp: number): number
	local elapsedInCycle = unixTimestamp % TIME_TO_RELOAD_STOCK
	local secondsRemaining = TIME_TO_RELOAD_STOCK - elapsedInCycle
	if secondsRemaining == 0 then
		return TIME_TO_RELOAD_STOCK
	end
	return secondsRemaining
end

local function getOrderedRarityKeys(): { string }
	local rarityEntries = {}
	for rarityName, rarityData in UnitsRarity do
		table.insert(rarityEntries, {
			Name = rarityName,
			Data = rarityData,
		})
	end
	table.sort(rarityEntries, function(a, b)
		return a.Data.GUI.Order < b.Data.GUI.Order
	end)

	local orderedKeys = {}
	for _, entry in rarityEntries do
		table.insert(orderedKeys, entry.Name)
	end
	return orderedKeys
end

-- === GLOBAL FUNCTIONS
function StockService:Init(): ()
	StockService:InitBridgeListener()
	StockService:InitStockCounter()
end

function StockService:InitGlobalStock(): ()
	local orderedRarityKeys = getOrderedRarityKeys()

	local function initGlobalStockCategory(enum: { [string]: ET.Item }, category: string, rarityName: string): ()
		local items = table.clone(StockService:GetStockFromRarity(enum, rarityName))
		sortByGuiOrder(items)
		for blockIndex, value in items do
			GlobalStock[category][value.Name] = 0
		end
	end

	for _, rarityName in orderedRarityKeys do
		for categoryName, enum in CategoryEnums do
			initGlobalStockCategory(enum, categoryName, rarityName)
		end
	end
end

function StockService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): ()
		if data[actionIdentifier] == "GetStock" then
			return StockService:GetStock(player)
		end

		if data[actionIdentifier] == "BuyItem" then
			local item: table = data.data.Item
			print("BuyItem", item)
			UnitService:Give(player, item.Name, item.Type)
		end
	end
end

function StockService:GetStock(player: Player): table
	if not PlayerStock[player] then
		PlayerStock[player] = TableKit.DeepCopy(GlobalStock)
	end
	return PlayerStock[player]
end

function StockService:InitStockCounter(): ()
	task.spawn(function(): ()
		while true do
			local now: number = os.time()
			local cycleId: number = getCycleIdFromUnix(now)

			if CurrentCycleId ~= cycleId then
				Debug.print("StockService:InitStockCounter - NewCycleDetected", cycleId)
				StockService:InitGlobalStock()
				StockService:CreateItemsStock(cycleId)
				CurrentCycleId = cycleId
			end

			local currTimeToReload = getSecondsUntilNextCycle(now)
			workspace:SetAttribute("TIME_TO_RELOAD_RESTOCK", currTimeToReload)
			task.wait(1)
		end
	end)
end

function StockService:GetStockFromRarity(enum: table, rarityName: string): { ET.Item }
	local selectedItems: { ET.Item } = {}
	for _, item in enum do
		if item.Rarity == rarityName then
			table.insert(selectedItems, item)
		end
	end
	table.sort(selectedItems, function(a, b)
		return a.Odd > b.Odd
	end)
	return selectedItems
end

function StockService:CreateItemsStock(cycleId: number): ()
	local raffledRarities: { string } = {}
	Debug.print("StockService:CreateItemsStock - Seed", cycleId)
	local random = Random.new(cycleId)

	-- Pega todas as categorias e vê quais vão ser sorteadas
	local orderedRarityKeys = getOrderedRarityKeys()
	for _, rarityName in orderedRarityKeys do
		local rarityData = UnitsRarity[rarityName]
		local odd: number = rarityData.Odd
		local roll: number = random:NextNumber()
		Debug.print("StockService:CreateItemsStock - RarityRoll", rarityName, "Odd:", odd, "Roll:", roll)
		if roll <= odd then
			table.insert(raffledRarities, rarityName)
			Debug.print("StockService:CreateItemsStock - RaritySelected", rarityName)
		end
	end

	local raffledItems: { [string]: { ET.Item } } = {}
	for categoryName, _ in CategoryEnums do
		raffledItems[categoryName] = {}
	end

	for _, rarity in raffledRarities do
		for categoryName, enum in CategoryEnums do
			local items = raffledItems[categoryName]
			local stock = StockService:GetStockFromRarity(enum, rarity)
			local added: boolean = false
			for _, item in stock do
				local odd: number = item.Odd
				local roll: number = random:NextNumber()
				Debug.print(
					"StockService:CreateItemsStock - ItemRoll",
					categoryName,
					"Item:",
					item.Name,
					"Odd:",
					odd,
					"Roll:",
					roll
				)
				if roll <= odd then
					added = true
					table.insert(items, item)
					Debug.print("StockService:CreateItemsStock - ItemSelected", categoryName, "Item:", item.Name)
				end
			end
			-- Se não tive saido nenhum, pega o item de maior sorte
			if not added then
				table.insert(items, stock[1])
				if stock[1] then
					Debug.print("StockService:CreateItemsStock - ItemFallback", categoryName, "Item:", stock[1].Name)
				else
					Debug.print(
						"StockService:CreateItemsStock - ItemFallback",
						categoryName,
						"No items available for rarity",
						rarity
					)
				end
			end
		end
	end

	for categoryName, items in raffledItems do
		for _, item in items do
			local quantity: number = random:NextInteger(item.Stock.Min, item.Stock.Max)
			Debug.print(
				"StockService:CreateItemsStock - QuantityRoll",
				categoryName,
				"Item:",
				item.Name,
				"Min:",
				item.Stock.Min,
				"Max:",
				item.Stock.Max,
				"Quantity:",
				quantity
			)
			GlobalStock[categoryName][item.Name] = quantity
		end
	end
end

return StockService
