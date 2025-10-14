local StockService = {}

-- === SERVICES
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local Response = require(Utility.Response)
local BridgeNet2 = require(Utility.BridgeNet2)
local TableKit = require(Utility.BridgeNet2.TableKit)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local Debug = require(Utility.Debug)(script)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local UnitService = require(ServerScriptService.Modules.UnitService)
local MoneyService = require(ServerScriptService.Modules.MoneyService)

-- === TYPES
local ET = require(ReplicatedStorage.Enums.T)

-- === ENUMS
local UnitsRarity = require(ReplicatedStorage.Enums.unitsRarity)
local Blocks = require(ReplicatedStorage.Enums.blocks)
local Melee = require(ReplicatedStorage.Enums.melee)
local Ranged = require(ReplicatedStorage.Enums.ranged)
local CategoryEnums: { [string]: { [string]: ET.Item } } = {
	Blocks = Blocks,
	Melee = Melee,
	Ranged = Ranged,
}

-- === CONSTANTS
local RESTOCK_ALL_PRODUCT_ID: number = 3430856208
local TIME_TO_RELOAD_STOCK: number = 300 -- 5 minutes
local PURCHASE_ACTION_KIND: { [string]: string } = {
	GrantItem = "GrantItem",
	RestockItem = "RestockItem",
	RestockAll = "RestockAll",
}
local TYPE_TO_CATEGORY: { [string]: string } = {
	BLOCK = "Blocks",
	MELEE = "Melee",
	RANGED = "Ranged",
}
local CATEGORY_TO_TYPE: { [string]: string } = {}
for typeName, categoryName in TYPE_TO_CATEGORY do
	CATEGORY_TO_TYPE[categoryName] = typeName
end

-- === LOCAL VARIABLES
local GlobalStock: table = {
	Blocks = {},
	Melee = {},
	Ranged = {},
}
local PlayerStock: { [Player]: table } = {}
local PlayerStockCycle: { [Player]: number? } = {}
local CurrentCycleId: number?
local CurrentTimeToReload: number?
local ProductActionById: { [number]: { kind: string, itemName: string?, category: string?, itemType: string? } } = {}
local ProductPriceCache: { [number]: number? } = {}
local ProductPriceTargetsById: {
	[number]: { { category: string, itemName: string, priceField: "ProductRobuxPrice" | "RestockProductPrice" } },
} =
	{}
local ProductPriceRequestsInFlight: { [number]: boolean } = {}

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
	local elapsedInCycle: number = unixTimestamp % TIME_TO_RELOAD_STOCK
	local secondsRemaining: number = TIME_TO_RELOAD_STOCK - elapsedInCycle
	if secondsRemaining == 0 then
		return TIME_TO_RELOAD_STOCK
	end
	return secondsRemaining
end

local function getOrderedRarityKeys(): { string }
	local rarityEntries: table = {}
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

local function resolveItemDefinition(itemPayload: table?): (ET.Item?, string?, string?)
	if typeof(itemPayload) ~= "table" then
		return nil, nil, Response.MESSAGES.INVALID_PAYLOAD
	end
	local itemType: string? = itemPayload.Type
	if not itemType then
		return nil, nil, Response.MESSAGES.INVALID_TYPE
	end
	local categoryName: string? = TYPE_TO_CATEGORY[itemType]
	if not categoryName then
		return nil, nil, Response.MESSAGES.INVALID_TYPE
	end
	local categoryEnum = CategoryEnums[categoryName]
	if not categoryEnum then
		return nil, nil, Response.MESSAGES.INVALID_CATEGORY
	end
	local itemDefinition: ET.Item? = categoryEnum[itemPayload.Name]
	if not itemDefinition then
		return nil, nil, Response.MESSAGES.INVALID_ITEM
	end
	return itemDefinition, categoryName, nil
end

local function registerPriceTarget(productId: number?, categoryName: string, itemName: string, priceField: string): ()
	if type(productId) ~= "number" or productId <= 0 then
		warn(`Invalid productId for {categoryName} {itemName}: {productId}`)
		return
	end
	local targets = ProductPriceTargetsById[productId]
	if not targets then
		targets = {}
		ProductPriceTargetsById[productId] = targets
	end
	for _, target in targets do
		if target.category == categoryName and target.itemName == itemName and target.priceField == priceField then
			return
		end
	end
	table.insert(targets, {
		category = categoryName,
		itemName = itemName,
		priceField = priceField :: "ProductRobuxPrice" | "RestockProductPrice",
	})
end

local function getCachedProductPrice(productId: number?): number?
	if type(productId) ~= "number" or productId <= 0 then
		warn(`Invalid productId: {productId}`)
		return nil
	end
	return ProductPriceCache[productId]
end

local function getItemDefinitionByCategory(categoryName: string, itemName: string): ET.Item?
	local enum = CategoryEnums[categoryName]
	if not enum then
		return nil
	end
	local definition = enum[itemName]
	if definition then
		return definition
	end
	for _, item in enum do
		if item.Name == itemName then
			return item
		end
	end
	return nil
end

local function makeStockEntry(itemDefinition: ET.Item, quantity: number): table
	local entryQuantity: number = tonumber(quantity) or 0
	return {
		Quantity = entryQuantity,
		ProductRobuxPrice = getCachedProductPrice(itemDefinition.ProductId),
		RestockProductPrice = getCachedProductPrice(itemDefinition.RestockProductId),
	}
end

local function ensureStockEntry(categoryStock: table, itemDefinition: ET.Item, itemName: string): table
	local entry = categoryStock[itemName]
	if type(entry) ~= "table" then
		entry = makeStockEntry(itemDefinition, 0)
		categoryStock[itemName] = entry
	else
		entry.ProductRobuxPrice = getCachedProductPrice(itemDefinition.ProductId)
		entry.RestockProductPrice = getCachedProductPrice(itemDefinition.RestockProductId)
	end
	return entry
end

local function fireRemoteEvent(player: Player, actionName: string, message: string, extra: table?): ()
	local payload = Response.makeSuccess(message, extra or {})
	payload[actionIdentifier] = actionName
	bridge:Fire(player, payload)
end

local function fireRemoteEventForAllPlayers(actionName: string, message: string, extra: table?): ()
	for _, player in ipairs(Players:GetPlayers()) do
		fireRemoteEvent(player, actionName, message, extra)
	end
end

local function getCurrentCycle(): number
	local cycleId = CurrentCycleId
	if not cycleId then
		local now = os.time()
		cycleId = getCycleIdFromUnix(now)
		StockService:LoadGlobalStock(cycleId)
		CurrentCycleId = cycleId
		CurrentTimeToReload = getSecondsUntilNextCycle(now)
	end
	return cycleId
end

local function getPlayerStock(player: Player): table
	local stock: table? = PlayerStock[player]
	local restockCycleValue = PlayerDataHandler:Get(player, "restockCycle")
	local restockCycle = type(restockCycleValue) == "number" and restockCycleValue or 0
	local currentCycle = getCurrentCycle()
	local usingGlobalStock = restockCycle <= 0 or currentCycle >= restockCycle

	if usingGlobalStock then
		if not stock or PlayerStockCycle[player] ~= currentCycle then
			stock = TableKit.DeepCopy(GlobalStock)
			PlayerStock[player] = stock
			PlayerStockCycle[player] = currentCycle
			fireRemoteEvent(player, "StockUpdated", Response.MESSAGES.STOCK_UPDATED, {
				cycleId = currentCycle,
				stock = stock,
			})
		end
		return stock :: table
	end

	if not stock or PlayerStockCycle[player] ~= restockCycle then
		stock = StockService:NewItemsStock(restockCycle)
		PlayerStock[player] = stock
		PlayerStockCycle[player] = restockCycle
		local timeToReload = CurrentTimeToReload
		if type(timeToReload) ~= "number" then
			timeToReload = getSecondsUntilNextCycle(os.time())
		end
		fireRemoteEvent(player, "RobuxRestockAllFulfilled", Response.MESSAGES.PLAYER_RESTOCKED, {
			cycleId = restockCycle,
			stock = stock,
			productId = RESTOCK_ALL_PRODUCT_ID,
			timestampOffset = (restockCycle - currentCycle) * TIME_TO_RELOAD_STOCK + timeToReload,
		})
	end

	return stock :: table
end

local function getPlayerCategoryStock(player: Player, categoryName: string): table
	local stock: table = getPlayerStock(player)
	local categoryStock: table? = stock[categoryName]
	if not categoryStock then
		error(`UNEXPECTED: Missing category stock for {categoryName} in player {player.Name}`)
	end
	return categoryStock
end

local function applyPriceToTargets(productId: number, price: number?): ()
	local targets = ProductPriceTargetsById[productId]
	if not targets then
		return
	end
	for _, target in targets do
		local itemDefinition = getItemDefinitionByCategory(target.category, target.itemName)
		local categoryStock = GlobalStock[target.category]
		if categoryStock then
			local entry = categoryStock[target.itemName]
			if type(entry) == "table" then
				entry[target.priceField] = price
			elseif itemDefinition then
				categoryStock[target.itemName] = makeStockEntry(itemDefinition, entry or 0)
				categoryStock[target.itemName][target.priceField] = price
			end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local playerCategory = getPlayerStock(player)[target.category]
			if playerCategory then
				local playerEntry = playerCategory[target.itemName]
				if type(playerEntry) == "table" then
					playerEntry[target.priceField] = price
				elseif itemDefinition then
					playerCategory[target.itemName] = makeStockEntry(itemDefinition, playerEntry or 0)
					playerCategory[target.itemName][target.priceField] = price
				end
			end
		end
	end
end

local function updateCachedProductPrice(productId: number, price: number?): ()
	if type(productId) ~= "number" or productId <= 0 then
		return
	end
	ProductPriceCache[productId] = price
	applyPriceToTargets(productId, price)
end

local function resolveProductPrice(productId: number): number?
	if type(productId) ~= "number" or productId <= 0 then
		return
	end
	local cachedPrice = ProductPriceCache[productId]
	if cachedPrice ~= nil then
		return cachedPrice
	end
	if ProductPriceRequestsInFlight[productId] then
		repeat
			task.wait()
			cachedPrice = ProductPriceCache[productId]
		until ProductPriceRequestsInFlight[productId] == nil or cachedPrice ~= nil
		return ProductPriceCache[productId]
	end

	ProductPriceRequestsInFlight[productId] = true
	local price: number? = nil
	local success, result = pcall(function(): ()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)
	if success and typeof(result) == "table" then
		price = tonumber(result.PriceInRobux)
	else
		warn(`StockService: Failed to fetch product info for {productId}: {tostring(result)}`)
	end
	ProductPriceRequestsInFlight[productId] = nil
	updateCachedProductPrice(productId, price)
	return price
end

local function promptProductPurchase(player: Player, productId: number?): (boolean, string?)
	if type(productId) ~= "number" or productId <= 0 then
		warn(`ProductId not configured for {player.Name}`)
		return false, Response.MESSAGES.PRODUCT_NOT_CONFIGURED
	end
	local success, errorMessage = pcall(function(): ()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	if not success then
		warn(`Failed to prompt product purchase for {player.Name}: {tostring(errorMessage)}`)
		return false, Response.MESSAGES.PROMPT_FAILED
	end
	return true, nil
end

local function registerProductActions(): ()
	table.clear(ProductActionById)
	table.clear(ProductPriceTargetsById)
	for categoryName, enum in CategoryEnums do
		local resolvedItemType = CATEGORY_TO_TYPE[categoryName]
		for itemName, itemDefinition in enum do
			local definitionName = itemDefinition.Name or itemName
			local productId = itemDefinition.ProductId
			if type(productId) == "number" and productId > 0 then
				ProductActionById[productId] = {
					kind = PURCHASE_ACTION_KIND.GrantItem,
					itemName = definitionName,
					category = categoryName,
					itemType = resolvedItemType,
				}
				registerPriceTarget(productId, categoryName, definitionName, "ProductRobuxPrice")
			end
			local restockProductId = itemDefinition.RestockProductId
			if type(restockProductId) == "number" and restockProductId > 0 then
				ProductActionById[restockProductId] = {
					kind = PURCHASE_ACTION_KIND.RestockItem,
					itemName = definitionName,
					category = categoryName,
				}
				registerPriceTarget(restockProductId, categoryName, definitionName, "RestockProductPrice")
			end
		end
	end
	if type(RESTOCK_ALL_PRODUCT_ID) == "number" and RESTOCK_ALL_PRODUCT_ID > 0 then
		ProductActionById[RESTOCK_ALL_PRODUCT_ID] = {
			kind = PURCHASE_ACTION_KIND.RestockAll,
		}
	end
end

local function resolveProductAction(productId: number): table?
	local actionInfo = ProductActionById[productId]
	if actionInfo then
		return actionInfo
	end

	for categoryName, enum in CategoryEnums do
		local resolvedItemType = CATEGORY_TO_TYPE[categoryName]
		for itemName, itemDefinition in enum do
			local definitionName = itemDefinition.Name or itemName
			if type(itemDefinition.ProductId) == "number" and itemDefinition.ProductId == productId then
				return {
					kind = PURCHASE_ACTION_KIND.GrantItem,
					itemName = definitionName,
					category = categoryName,
					itemType = resolvedItemType,
				}
			end
			if type(itemDefinition.RestockProductId) == "number" and itemDefinition.RestockProductId == productId then
				return {
					kind = PURCHASE_ACTION_KIND.RestockItem,
					itemName = definitionName,
					category = categoryName,
				}
			end
		end
	end

	if type(RESTOCK_ALL_PRODUCT_ID) == "number" and RESTOCK_ALL_PRODUCT_ID > 0 then
		if productId == RESTOCK_ALL_PRODUCT_ID then
			return {
				kind = PURCHASE_ACTION_KIND.RestockAll,
			}
		end
	end

	return nil
end

local function restockPlayerItem(player: Player, categoryName: string, itemName: string): number
	local itemDefinition: ET.Item = CategoryEnums[categoryName][itemName]
	local stock: { Min: number, Max: number } = itemDefinition.Stock
	local random = Random.new()
	local quantity: number = random:NextInteger(stock.Min, stock.Max)
	local categoryStock: table = getPlayerCategoryStock(player, categoryName)
	local entryName = itemDefinition.Name or itemName
	local entry = ensureStockEntry(categoryStock, itemDefinition, entryName)
	entry.Quantity = quantity
	return quantity
end

-- === GLOBAL FUNCTIONS
function StockService:Init(): ()
	registerProductActions()
	StockService:InitBridgeListener()
	StockService:InitStockCounter()
	Players.PlayerRemoving:Connect(function(player: Player): ()
		PlayerStock[player] = nil
		PlayerStockCycle[player] = nil
	end)
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return StockService:ProcessReceipt(receiptInfo)
	end
end

function StockService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table?): any
		data = data or {}
		local action = data[actionIdentifier]
		local payload = data.data
		if action == "GetStock" then
			return StockService:GetStock(player)
		elseif action == "BuyItem" then
			return StockService:HandleBuyItem(player, payload)
		elseif action == "BuyItemWithRobux" then
			return StockService:HandleBuyItemWithRobux(player, payload)
		elseif action == "RestockItemWithRobux" then
			return StockService:HandleRestockItemWithRobux(player, payload)
		elseif action == "RestockAllWithRobux" then
			return StockService:HandleRestockAllWithRobux(player, payload)
		elseif action == "FetchItemRobuxPrice" then
			return StockService:HandleFetchItemRobuxPrice(player, payload)
		end
		return Response.makeError(Response.MESSAGES.UNKNOWN_ACTION)
	end
end

function StockService:GetStock(player: Player): table
	return getPlayerStock(player)
end

function StockService:HandleBuyItem(player: Player, payload: table?): table
	local itemPayload = payload and payload.Item
	local itemDefinition, categoryName, errorMessage = resolveItemDefinition(itemPayload)
	if not itemDefinition then
		return Response.makeError(errorMessage or Response.MESSAGES.INVALID_ITEM)
	end

	local categoryStock = getPlayerCategoryStock(player, categoryName)
	local entryName = itemDefinition.Name or (itemPayload and itemPayload.Name)
	local entry = ensureStockEntry(categoryStock, itemDefinition, entryName)
	local available = tonumber(entry.Quantity) or 0

	if available <= 0 then
		return Response.makeError(Response.MESSAGES.OUT_OF_STOCK, {
			itemName = itemDefinition.Name,
		})
	end

	if not MoneyService:HasMoney(player, itemDefinition.Price) then
		return Response.makeError(Response.MESSAGES.INSUFFICIENT_FUNDS, {
			itemName = itemDefinition.Name,
		})
	end

	MoneyService:ConsumeMoney(player, itemDefinition.Price)
	entry.Quantity = available - 1
	UnitService:Give(player, itemDefinition.Name, itemPayload.Type)

	return Response.makeSuccess(Response.MESSAGES.ITEM_PURCHASED, {
		itemName = itemDefinition.Name,
		remainingStock = entry.Quantity,
	})
end

function StockService:HandleBuyItemWithRobux(player: Player, payload: table?): table
	local itemPayload = payload and payload.Item
	local itemDefinition, categoryName, errorMessage = resolveItemDefinition(itemPayload)
	if not itemDefinition then
		return Response.makeError(errorMessage or Response.MESSAGES.INVALID_ITEM)
	end
	local productId: number? = itemDefinition.ProductId
	local success, promptError = promptProductPurchase(player, productId)
	if not success then
		return Response.makeError(promptError or Response.MESSAGES.PROMPT_FAILED)
	end
	return Response.makeSuccess(Response.MESSAGES.PURCHASE_PENDING, {
		itemName = itemDefinition.Name,
		category = categoryName,
		productId = productId,
		purchasePending = true,
	})
end

function StockService:HandleRestockItemWithRobux(player: Player, payload: table?): table
	local itemPayload = payload and payload.Item
	local itemDefinition, categoryName, errorMessage = resolveItemDefinition(itemPayload)
	if not itemDefinition then
		return Response.makeError(errorMessage or Response.MESSAGES.INVALID_ITEM)
	end
	local productId: number? = itemDefinition.RestockProductId or itemDefinition.ProductId
	local success, promptError = promptProductPurchase(player, productId)
	if not success then
		return Response.makeError(promptError or Response.MESSAGES.PROMPT_FAILED)
	end
	return Response.makeSuccess(Response.MESSAGES.PURCHASE_PENDING, {
		itemName = itemDefinition.Name,
		category = categoryName,
		productId = productId,
		purchasePending = true,
	})
end

function StockService:HandleRestockAllWithRobux(player: Player, _payload: table?): table
	local success, promptError = promptProductPurchase(player, RESTOCK_ALL_PRODUCT_ID)
	if not success then
		return Response.makeError(promptError or Response.MESSAGES.PROMPT_FAILED)
	end
	return Response.makeSuccess(Response.MESSAGES.PURCHASE_PENDING, {
		productId = RESTOCK_ALL_PRODUCT_ID,
		purchasePending = true,
	})
end

function StockService:HandleFetchItemRobuxPrice(player: Player, payload: table?): table
	local itemPayload = payload and payload.Item
	local itemDefinition, categoryName, errorMessage = resolveItemDefinition(itemPayload)
	if not itemDefinition then
		return Response.makeError(errorMessage or Response.MESSAGES.INVALID_ITEM)
	end

	local categoryStock = getPlayerCategoryStock(player, categoryName)
	local entryName = itemDefinition.Name or (itemPayload and itemPayload.Name) or itemDefinition.Name
	local entry = ensureStockEntry(categoryStock, itemDefinition, entryName)

	local productPrice = resolveProductPrice(itemDefinition.ProductId)
	local restockPrice = resolveProductPrice(itemDefinition.RestockProductId)

	entry.ProductRobuxPrice = productPrice
	entry.RestockProductPrice = restockPrice

	return Response.makeSuccess(Response.MESSAGES.PRICES_UPDATED, {
		category = categoryName,
		itemName = entryName,
		ProductRobuxPrice = productPrice,
		RestockProductPrice = restockPrice,
	})
end

function StockService:ProcessReceipt(receiptInfo: table): Enum.ProductPurchaseDecision
	local productId: number? = receiptInfo and receiptInfo.ProductId
	local playerId: number? = receiptInfo and receiptInfo.PlayerId
	if type(productId) ~= "number" or type(playerId) ~= "number" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player: Player? = Players:GetPlayerByUserId(playerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local actionInfo: table? = resolveProductAction(productId)

	if not actionInfo then
		warn(`No product action mapping found for ProductId {tostring(productId)}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success, errorMessage = pcall(function(): ()
		if actionInfo.kind == PURCHASE_ACTION_KIND.GrantItem then
			local itemName: string? = actionInfo.itemName
			local categoryName: string? = actionInfo.category
			if not itemName then
				error("Missing itemName for GrantItem action")
			end
			local itemType: string? = actionInfo.itemType
			if not itemType and categoryName then
				itemType = CATEGORY_TO_TYPE[categoryName]
			end
			if not itemType then
				error(`Unable to resolve item type for {tostring(itemName)}`)
			end
			UnitService:Give(player, itemName, itemType)
			fireRemoteEvent(player, "RobuxItemPurchaseFulfilled", Response.MESSAGES.ITEM_PURCHASED, {
				itemName = itemName,
				category = categoryName,
				productId = productId,
			})
		elseif actionInfo.kind == PURCHASE_ACTION_KIND.RestockItem then
			local categoryName: string? = actionInfo.category
			local itemName: string? = actionInfo.itemName
			if not categoryName or not itemName then
				error("Missing required data for RestockItem action")
			end
			local restoredQuantity = restockPlayerItem(player, categoryName, itemName)
			fireRemoteEvent(player, "RobuxItemRestockFulfilled", Response.MESSAGES.ITEM_RESTOCKED, {
				itemName = itemName,
				category = categoryName,
				remainingStock = restoredQuantity,
				productId = productId,
			})
		elseif actionInfo.kind == PURCHASE_ACTION_KIND.RestockAll then
			local restockCycle: number = PlayerDataHandler:Get(player, "restockCycle") or 0
			if restockCycle <= CurrentCycleId then
				restockCycle = CurrentCycleId + 1
			else
				restockCycle += 1
			end
			PlayerDataHandler:Set(player, "restockCycle", restockCycle)
			PlayerStock[player] = StockService:NewItemsStock(restockCycle)
			PlayerStockCycle[player] = restockCycle
			fireRemoteEvent(player, "RobuxRestockAllFulfilled", Response.MESSAGES.PLAYER_RESTOCKED, {
				stock = PlayerStock[player],
				productId = productId,
				timestampOffset = (restockCycle - CurrentCycleId) * TIME_TO_RELOAD_STOCK + CurrentTimeToReload,
				cycleId = restockCycle,
			})
		else
			error(`Unknown product action kind {actionInfo.kind}`)
		end
	end)

	if not success then
		warn(`Failed to process receipt for ProductId {productId}: {errorMessage}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function StockService:InitStockCounter(): ()
	task.spawn(function(): ()
		while true do
			local now: number = os.time()
			local cycleId: number = getCycleIdFromUnix(now)

			if CurrentCycleId ~= cycleId then
				Debug.print(`StockService:InitStockCounter - NewCycleDetected {cycleId}`)
				StockService:LoadGlobalStock(cycleId)
				CurrentCycleId = cycleId
				fireRemoteEventForAllPlayers("StockUpdated", Response.MESSAGES.STOCK_UPDATED, {
					cycleId = CurrentCycleId,
					stock = GlobalStock,
				})
			end

			CurrentTimeToReload = getSecondsUntilNextCycle(now)
			workspace:SetAttribute("TIME_TO_RELOAD_RESTOCK", CurrentTimeToReload)
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

function StockService:NewItemsStock(seed: number?): table
	local orderedRarityKeys = getOrderedRarityKeys()
	local result: table = {}
	for categoryName, _ in CategoryEnums do
		result[categoryName] = {}
	end

	local function initStockCategory(enum: { [string]: ET.Item }, category: string, rarityName: string): ()
		local items = table.clone(StockService:GetStockFromRarity(enum, rarityName))
		sortByGuiOrder(items)
		for blockIndex, value in items do
			result[category][value.Name] = makeStockEntry(value, 0)
		end
	end

	for _, rarityName in orderedRarityKeys do
		for categoryName, enum in CategoryEnums do
			initStockCategory(enum, categoryName, rarityName)
		end
	end

	local raffledRarities: { string } = {}
	Debug.print(`StockService:NewItemsStock - Seed {seed}`)
	local random = Random.new(seed)

	for _, rarityName in orderedRarityKeys do
		local rarityData = UnitsRarity[rarityName]
		local odd: number = rarityData.Odd
		local roll: number = random:NextNumber()
		Debug.print(`StockService:NewItemsStock - RarityRoll {rarityName} Odd: {odd} Roll: {roll}`)
		if roll <= odd then
			table.insert(raffledRarities, rarityName)
			Debug.print(`StockService:NewItemsStock - RaritySelected {rarityName}`)
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
					`StockService:NewItemsStock - ItemRoll {categoryName} Item: {item.Name} Odd: {odd} Roll: {roll}`
				)
				if roll <= odd then
					added = true
					table.insert(items, item)
					Debug.print(`StockService:NewItemsStock - ItemSelected {categoryName} Item: {item.Name}`)
				end
			end
			-- Se não tive saido nenhum, pega o item de maior sorte
			if not added then
				table.insert(items, stock[1])
				if stock[1] then
					Debug.print(`StockService:NewItemsStock - ItemFallback {categoryName} Item: {stock[1].Name}`)
				else
					Debug.print(
						`StockService:NewItemsStock - ItemFallback {categoryName} No items available for rarity {rarity}`
					)
				end
			end
		end
	end

	for categoryName, items in raffledItems do
		for _, item in items do
			local quantity: number = random:NextInteger(item.Stock.Min, item.Stock.Max)
			Debug.print(
				`StockService:CreateItemsStock - QuantityRoll {categoryName} Item: {item.Name} Min: {item.Stock.Min} Max: {item.Stock.Max} Quantity: {quantity}`
			)
			local entry = ensureStockEntry(result[categoryName], item, item.Name)
			entry.Quantity = quantity
		end
	end

	Debug.print(`StockService:NewItemsStock - Result:`, result)
	return result
end

function StockService:LoadGlobalStock(cycleId: number): ()
	GlobalStock = StockService:NewItemsStock(cycleId)
	Debug.print(`StockService:LoadGlobalStock - GlobalStock:`, GlobalStock)
end

return StockService
