local BaseShopScreenController = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local Response = require(Utility.Response)
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local Tags = require(ReplicatedStorage.Enums.Tags)

-- === ENUMS
local Blocks = require(ReplicatedStorage.Enums.blocks)
local Melee = require(ReplicatedStorage.Enums.melee)
local Ranged = require(ReplicatedStorage.Enums.ranged)

-- === CONSTANTS
local LAYOUT_ORDER_GAP: number = 10
local ROBUX_BUTTON_DEFAULT_TEXT: string = "..."
local CATEGORY_CONFIG: {
	[string]: {
		Enum: table,
		Type: string,
		ContainerTag: string,
		Container: ScrollingFrame?,
		Buttons: Frame?,
		TabButtonTag: string,
		TabButton: TextButton?,
	},
} =
	{
		Blocks = {
			Enum = Blocks,
			Type = "BLOCK",
			ContainerTag = Tags.BASE_SHOP_BLOCKS_CONTAINER,
			TabButtonTag = Tags.BASE_SHOP_BLOCKS_TAB_BUTTON,
		},
		Melee = {
			Enum = Melee,
			Type = "MELEE",
			ContainerTag = Tags.BASE_SHOP_MELEE_CONTAINER,
			TabButtonTag = Tags.BASE_SHOP_MELEE_TAB_BUTTON,
		},
		Ranged = {
			Enum = Ranged,
			Type = "RANGED",
			ContainerTag = Tags.BASE_SHOP_RANGED_CONTAINER,
			TabButtonTag = Tags.BASE_SHOP_RANGED_TAB_BUTTON,
		},
	}

-- === LOCAL VARIABLES
local Screen: Frame
local TimeRestockTextLabel: TextLabel
local RestockAllButton: TextButton
local CloseButton: TextButton
local SelectedCategoryName: string?
local SelectedItemName: string?
local LatestStockByCategory: { [string]: table } = {}
local PriceRequestsInFlight: { [string]: boolean } = {}
local RobuxRestockAllTimestampOffset: number = 0
local CurrentCycleId: number?

-- === LOCAL FUNCTIONS
local function findStockLabel(root: Instance?): TextLabel?
	if not root then
		return nil
	end
	local descendant = root:FindFirstChild("Stock", true)
	if descendant and descendant:IsA("TextLabel") then
		return descendant
	end
	return nil
end

local function setItemQuantityDisplay(target: Instance?, quantity: number): ()
	if not target then
		return
	end
	quantity = tonumber(quantity) or 0
	quantity = math.max(0, quantity)
	if target:IsA("GuiObject") then
		target:SetAttribute("STOCK_QUANTITY", quantity)
	end
	local label = findStockLabel(target)
	if label then
		label.Text = tostring(quantity)
	end
end

local function getEntryQuantity(stockEntry: any): number
	if typeof(stockEntry) == "table" then
		local quantityValue = tonumber(stockEntry.Quantity)
		if quantityValue then
			return quantityValue
		end
	end
	return tonumber(stockEntry) or 0
end

local function getEntryProductPrice(stockEntry: any): number?
	if typeof(stockEntry) == "table" then
		local price = stockEntry.ProductRobuxPrice
		if type(price) == "number" then
			return price
		end
	end
	return nil
end

local function updateRobuxButtonTitle(robuxButton: Instance?, price: number?)
	if not robuxButton or not robuxButton:IsA("GuiButton") then
		return
	end

	local titleLabel = robuxButton:FindFirstChild("Title")
	if not titleLabel or not titleLabel:IsA("TextLabel") then
		return
	end

	if type(price) == "number" then
		titleLabel.Text = string.format("%d ROBUX", price)
	else
		titleLabel.Text = ROBUX_BUTTON_DEFAULT_TEXT
	end
end

local function updateButtonsForSelection(config: table, stockEntry: any): ()
	local buttons = config.Buttons
	if not buttons then
		return
	end

	local quantity = getEntryQuantity(stockEntry)
	setItemQuantityDisplay(buttons, quantity)
	local buyButton = buttons:FindFirstChild("Buy")
	if buyButton and buyButton:IsA("GuiButton") then
		local hasStock = quantity > 0
		buyButton.Active = hasStock
		buyButton.AutoButtonColor = hasStock
		buyButton.Selectable = hasStock
	end
	local robuxButton = buttons:FindFirstChild("Robux")
	updateRobuxButtonTitle(robuxButton, getEntryProductPrice(stockEntry))
end

local function invokeStockAction(action: string, payload: table?): table?
	local success, response = pcall(function(): any
		return bridge:InvokeServerAsync({
			[actionIdentifier] = action,
			data = payload,
		})
	end)

	if not success then
		warn(`[BaseShop] Failed to invoke {action}: {tostring(response)}`)
		return nil
	end

	if typeof(response) ~= "table" then
		return response
	end

	local status = response[statusIdentifier]
	local message = response[messageIdentifier]

	if status == "error" then
		warn(`[BaseShop] {action} failed: {message or "Unknown error"}`)
	elseif status == "success" then
		if message then
			print(`[BaseShop] {action}: {message}`)
		end
	elseif status ~= nil then
		warn(`[BaseShop] {action} returned unexpected status: {tostring(status)}`)
	end

	return response
end

local function getPriceRequestKey(categoryName: string, itemName: string): string
	return `{categoryName}::{itemName}`
end

local function ensureRobuxPrices(categoryName: string, config: table, itemName: string, stockEntry: any): ()
	if typeof(stockEntry) ~= "table" then
		return
	end

	if type(stockEntry.ProductRobuxPrice) == "number" and type(stockEntry.RestockProductPrice) == "number" then
		return
	end

	local requestKey = getPriceRequestKey(categoryName, itemName)
	if PriceRequestsInFlight[requestKey] then
		return
	end
	PriceRequestsInFlight[requestKey] = true

	task.spawn(function(): ()
		local response = invokeStockAction("FetchItemRobuxPrice", {
			Item = {
				Type = config.Type,
				Name = itemName,
			},
		})

		PriceRequestsInFlight[requestKey] = nil

		if not Response.isSuccessResponse(response) then
			return
		end

		local resolvedCategory = response.category or categoryName
		local resolvedItemName = response.itemName or itemName

		local categoryStock = LatestStockByCategory[resolvedCategory]
		if typeof(categoryStock) ~= "table" then
			categoryStock = {}
			LatestStockByCategory[resolvedCategory] = categoryStock
		end

		local updatedEntry = categoryStock[resolvedItemName]
		if typeof(updatedEntry) ~= "table" then
			local quantity = 0
			if typeof(updatedEntry) == "number" then
				quantity = updatedEntry
			end
			updatedEntry = {
				Quantity = quantity,
			}
			categoryStock[resolvedItemName] = updatedEntry
		end

		updatedEntry.ProductRobuxPrice = response.ProductRobuxPrice
		updatedEntry.RestockProductPrice = response.RestockProductPrice

		local itemFrames = config.ItemFrames
		local itemFrame = itemFrames and itemFrames[resolvedItemName]
		if itemFrame then
			itemFrame:SetAttribute("PRODUCT_ROBUX_PRICE", response.ProductRobuxPrice)
			itemFrame:SetAttribute("RESTOCK_PRODUCT_PRICE", response.RestockProductPrice)
		end

		if SelectedCategoryName == resolvedCategory and SelectedItemName == resolvedItemName then
			BaseShopScreenController:UpdateSelectedItemDisplay()
		end
	end)
end

-- === GLOBAL FUNCTIONS
function BaseShopScreenController:Init(): ()
	BaseShopScreenController:CreateReferences()
	BaseShopScreenController:InitBridgeListener()
	BaseShopScreenController:ConfigureProximityPrompt()
	BaseShopScreenController:InitAttributeListener()
	BaseShopScreenController:CreateButtonListeners()
end

function BaseShopScreenController:CreateReferences(): ()
	Screen = UIReferences:GetReference(Tags.BASE_SHOP_SCREEN)
	TimeRestockTextLabel = UIReferences:GetReference(Tags.BASE_SHOP_TIME_TEXT)
	RestockAllButton = UIReferences:GetReference(Tags.BASE_SHOP_RESTOCK_ALL_BUTTON)
	CloseButton = UIReferences:GetReference(Tags.BASE_SHOP_CLOSE_BUTTON)
	for categoryName, config in pairs(CATEGORY_CONFIG) do
		local container: ScrollingFrame? = UIReferences:GetReference(config.ContainerTag)
		config.Container = container
		if container then
			config.Buttons = container:FindFirstChild("BUTTONS")
			if config.Buttons then
				config.Buttons.Visible = false
				config.ItemFrames = {}
			else
				error(`Container doesn't have BUTTONS child for category {categoryName}`)
			end

			local uiListLayout: UIListLayout? = container:FindFirstChildWhichIsA("UIListLayout")
			if uiListLayout then
				local function refreshContainerCanvasSize(): ()
					container.CanvasSize = UDim2.new(
						0,
						0,
						uiListLayout.Padding.Scale,
						uiListLayout.AbsoluteContentSize.Y + uiListLayout.Padding.Offset
					)
				end
				refreshContainerCanvasSize()
				uiListLayout.Changed:Connect(function(property: string): ()
					if property == "AbsoluteContentSize" then
						refreshContainerCanvasSize()
					end
				end)
			else
				error(`Container doesn't have UIListLayout child for category {categoryName}`)
			end
		else
			error(`Container not found for category {categoryName}`)
		end
		local tabButton = UIReferences:GetReference(config.TabButtonTag)
		config.TabButton = tabButton
		if not tabButton then
			error(`Tab button not found for category {categoryName}`)
		end
	end
end

function BaseShopScreenController:InitBridgeListener(): ()
	bridge:Connect(function(response): ()
		if typeof(response) ~= "table" then
			return
		end
		local action = response[actionIdentifier]
		if action == "RobuxItemPurchaseFulfilled" then
			if Response.isSuccessResponse(response) then
				BaseShopScreenController:RefreshStock()
			end
		elseif action == "RobuxItemRestockFulfilled" then
			if Response.isSuccessResponse(response) then
				local categoryName = response.category
				local itemName = response.itemName
				local remainingStock = response.remainingStock
				if type(categoryName) ~= "string" or type(itemName) ~= "string" or type(remainingStock) ~= "number" then
					BaseShopScreenController:RefreshStock()
					return
				end
				local applied = BaseShopScreenController:SetItemQuantity(categoryName, itemName, remainingStock)
				if not applied then
					BaseShopScreenController:RefreshStock()
				end
			end
		elseif action == "RobuxRestockAllFulfilled" then
			if Response.isSuccessResponse(response) then
				RobuxRestockAllTimestampOffset = response.timestampOffset
				CurrentCycleId = response.cycleId
				BaseShopScreenController:BuildCategories(response.stock)
				BaseShopScreenController:UpdateSelectedItemDisplay()
			end
		elseif action == "StockUpdated" then
			if Response.isSuccessResponse(response) then
				local stock: table = response.stock
				local cycleId: number = response.cycleId
				if not CurrentCycleId or cycleId > CurrentCycleId then
					BaseShopScreenController:BuildCategories(stock)
					BaseShopScreenController:UpdateSelectedItemDisplay()
					CurrentCycleId = cycleId
				end
			end
		end
	end)
end

function BaseShopScreenController:ClearScreen(): ()
	SelectedCategoryName = nil
	SelectedItemName = nil
	for _, config in pairs(CATEGORY_CONFIG) do
		if config.Buttons then
			config.Buttons.Visible = false
		end
	end
end

function BaseShopScreenController:CreateButtonListeners(): ()
	RestockAllButton.MouseButton1Click:Connect(function(): ()
		local response = invokeStockAction("RestockAllWithRobux", {})
		if not response then
			return
		end
		if not Response.isSuccessResponse(response) then
			BaseShopScreenController:RefreshStock()
		end
	end)

	CloseButton.MouseButton1Click:Connect(function(): ()
		BaseShopScreenController:Close()
	end)

	for categoryName, config in pairs(CATEGORY_CONFIG) do
		local buttons = config.Buttons
		local buyButton = buttons:FindFirstChild("Buy")
		local robuxButton = buttons:FindFirstChild("Robux")
		local restockButton = buttons:FindFirstChild("Restock")

		if buyButton and buyButton:IsA("GuiButton") then
			buyButton.MouseButton1Click:Connect(function(): ()
				if SelectedItemName and SelectedCategoryName == categoryName then
					local response = invokeStockAction("BuyItem", {
						Item = {
							Type = config.Type,
							Name = SelectedItemName,
						},
					})
					if Response.isSuccessResponse(response) then
						local responseItemName = response.itemName or SelectedItemName
						local remainingStock = response.remainingStock
						if typeof(remainingStock) == "number" and responseItemName then
							local applied =
								BaseShopScreenController:SetItemQuantity(categoryName, responseItemName, remainingStock)
							if not applied then
								BaseShopScreenController:RefreshStock()
							end
						else
							BaseShopScreenController:RefreshStock()
						end
					else
						BaseShopScreenController:RefreshStock()
					end
				end
			end)
		end

		if robuxButton and robuxButton:IsA("GuiButton") then
			robuxButton.MouseButton1Click:Connect(function(): ()
				if SelectedItemName and SelectedCategoryName == categoryName then
					invokeStockAction("BuyItemWithRobux", {
						Item = {
							Type = config.Type,
							Name = SelectedItemName,
						},
					})
				end
			end)
		end

		if restockButton and restockButton:IsA("GuiButton") then
			restockButton.MouseButton1Click:Connect(function(): ()
				if SelectedItemName and SelectedCategoryName == categoryName then
					local response = invokeStockAction("RestockItemWithRobux", {
						Item = {
							Type = config.Type,
							Name = SelectedItemName,
						},
					})
					if not Response.isSuccessResponse(response) then
						BaseShopScreenController:RefreshStock()
					end
				end
			end)
		end

		local tabButton = config.TabButton
		if tabButton and tabButton:IsA("GuiButton") then
			tabButton.MouseButton1Click:Connect(function()
				for _, otherConfig in pairs(CATEGORY_CONFIG) do
					otherConfig.Container.Visible = false
				end
				config.Container.Visible = true
			end)
		end
	end
end

function BaseShopScreenController:ConfigureProximityPrompt(): ()
	local proximityPart = ClientUtil:WaitForDescendants(workspace, "map", "stores", "base", "store", "ProximityPart")
	local proximityPrompt = proximityPart.ProximityPrompt

	proximityPrompt.PromptShown:Connect(function(): ()
		BaseShopScreenController:Open()
		BaseShopScreenController:RefreshStock()
	end)

	proximityPrompt.PromptHidden:Connect(function(): ()
		BaseShopScreenController:Close()
	end)
end

function BaseShopScreenController:Open(): ()
	Screen.Visible = true
end

function BaseShopScreenController:Close(): ()
	BaseShopScreenController:ClearScreen()
	Screen.Visible = false
end

function BaseShopScreenController:InitAttributeListener(): ()
	workspace:GetAttributeChangedSignal("TIME_TO_RELOAD_RESTOCK"):Connect(function(): ()
		local leftTime: number = workspace:GetAttribute("TIME_TO_RELOAD_RESTOCK")
		if RobuxRestockAllTimestampOffset > 0 then
			RobuxRestockAllTimestampOffset -= 1
			leftTime = RobuxRestockAllTimestampOffset
		end
		TimeRestockTextLabel.Text = "Shop Restock In: " .. ClientUtil:FormatSecondsToMinutes(leftTime)
	end)
end

function BaseShopScreenController:BuildCategories(stock: table): ()
	if not stock then
		return
	end

	LatestStockByCategory = {}

	for categoryName, _ in pairs(CATEGORY_CONFIG) do
		local categoryStock = stock[categoryName]
		if typeof(categoryStock) ~= "table" then
			categoryStock = {}
		end
		LatestStockByCategory[categoryName] = categoryStock
		BaseShopScreenController:BuildCategoryItems(categoryName, categoryStock)
	end
end

function BaseShopScreenController:BuildCategoryItems(categoryName: string, stockList: table?): ()
	stockList = stockList or {}

	local config = CATEGORY_CONFIG[categoryName]
	local container = config.Container
	local enum = config.Enum
	local itemsFolder = ReplicatedStorage.GUI.Shop.Items
	config.ItemFrames = config.ItemFrames or {}

	if not container then
		return
	end

	local function ensureItemFrame(itemName: string, itemInfo: table, stockEntry: any)
		local itemFrame = config.ItemFrames[itemName]
		if not itemFrame or not itemFrame.Parent then
			local template = itemsFolder[itemInfo.Rarity]
			if not template then
				return nil
			end

			itemFrame = template:Clone()
			itemFrame.Name = itemName
			itemFrame.Parent = container
			config.ItemFrames[itemName] = itemFrame

			local capturedButton = itemFrame
			local capturedItemName = itemName
			local capturedCategoryName = categoryName
			capturedButton.MouseButton1Click:Connect(function(): ()
				SelectedCategoryName = capturedCategoryName
				SelectedItemName = capturedItemName
				BaseShopScreenController:UpdateSelectedItemDisplay()
			end)
		end

		if not itemFrame then
			return nil
		end

		itemFrame.Visible = true
		itemFrame.LayoutOrder = (itemInfo.GUI.Order or 0) * LAYOUT_ORDER_GAP

		local quantity = getEntryQuantity(stockEntry)
		local content = itemFrame:FindFirstChild("Content")
		if content and content:IsA("Frame") then
			local mainInfos = content:FindFirstChild("MainInfos")
			if mainInfos and mainInfos:IsA("Frame") then
				local itemNameLabel = mainInfos:FindFirstChild("ItemName")
				if itemNameLabel and itemNameLabel:IsA("TextLabel") then
					itemNameLabel.Text = itemInfo.GUI.Name
				end
				local descLabel = mainInfos:FindFirstChild("Desc")
				if descLabel and descLabel:IsA("TextLabel") then
					descLabel.Text = itemInfo.GUI.Description
				end
				local priceLabel = mainInfos:FindFirstChild("Price")
				if priceLabel and priceLabel:IsA("TextLabel") then
					priceLabel.Text = ClientUtil:FormatToUSD(itemInfo.Price)
				end
			end
		end

		setItemQuantityDisplay(itemFrame, quantity)
		if typeof(stockEntry) == "table" then
			itemFrame:SetAttribute("PRODUCT_ROBUX_PRICE", stockEntry.ProductRobuxPrice)
			itemFrame:SetAttribute("RESTOCK_PRODUCT_PRICE", stockEntry.RestockProductPrice)
		else
			itemFrame:SetAttribute("PRODUCT_ROBUX_PRICE", nil)
			itemFrame:SetAttribute("RESTOCK_PRODUCT_PRICE", nil)
		end

		return itemFrame
	end

	local processed: { [string]: boolean } = {}

	for itemName, itemInfo in pairs(enum) do
		local stockEntry = stockList[itemName]
		if itemInfo then
			ensureItemFrame(itemName, itemInfo, stockEntry)
			processed[itemName] = true
		end
	end

	for itemName, stockEntry in pairs(stockList) do
		if not processed[itemName] then
			local itemInfo = enum[itemName]
			if itemInfo then
				ensureItemFrame(itemName, itemInfo, stockEntry)
				processed[itemName] = true
			end
		end
	end

	for existingName, frame in pairs(config.ItemFrames) do
		if not processed[existingName] and frame then
			frame.Visible = false
		end
	end
end

function BaseShopScreenController:SetItemQuantity(categoryName: string, itemName: string, quantity: number?): boolean
	local config = CATEGORY_CONFIG[categoryName]
	if not config then
		warn(`No category config for {categoryName}`)
		return false
	end

	local itemFrames = config.ItemFrames
	if not itemFrames then
		warn(`No item frames for category {categoryName}`)
		return false
	end

	local itemFrame = itemFrames[itemName]
	if not itemFrame then
		warn(`No item frame for item {itemName} in category {categoryName}`)
		return false
	end

	itemFrame.Visible = true
	local resolvedQuantity = tonumber(quantity) or 0
	setItemQuantityDisplay(itemFrame, resolvedQuantity)

	local categoryStock = LatestStockByCategory[categoryName]
	if not categoryStock then
		categoryStock = {}
		LatestStockByCategory[categoryName] = categoryStock
	end

	local stockEntry = categoryStock[itemName]
	if typeof(stockEntry) == "table" then
		stockEntry.Quantity = resolvedQuantity
	else
		local productPriceAttr = itemFrame:GetAttribute("PRODUCT_ROBUX_PRICE")
		local restockPriceAttr = itemFrame:GetAttribute("RESTOCK_PRODUCT_PRICE")
		categoryStock[itemName] = {
			Quantity = resolvedQuantity,
			ProductRobuxPrice = typeof(productPriceAttr) == "number" and productPriceAttr or nil,
			RestockProductPrice = typeof(restockPriceAttr) == "number" and restockPriceAttr or nil,
		}
	end

	if SelectedCategoryName == categoryName and SelectedItemName == itemName then
		BaseShopScreenController:UpdateSelectedItemDisplay()
	end
	return true
end

function BaseShopScreenController:UpdateSelectedItemDisplay(): ()
	for _, config in pairs(CATEGORY_CONFIG) do
		if config.Buttons then
			config.Buttons.Visible = false
		end
	end

	if not SelectedCategoryName or not SelectedItemName then
		SelectedCategoryName = nil
		SelectedItemName = nil
		return
	end

	local config = CATEGORY_CONFIG[SelectedCategoryName]
	if not config then
		SelectedCategoryName = nil
		SelectedItemName = nil
		return
	end

	local itemFrames = config.ItemFrames
	local selectedFrame = itemFrames and itemFrames[SelectedItemName]
	if not selectedFrame or not selectedFrame.Visible then
		if config.Buttons then
			config.Buttons.Visible = false
		end
		SelectedCategoryName = nil
		SelectedItemName = nil
		return
	end

	local categoryStock = LatestStockByCategory[SelectedCategoryName]
	if not categoryStock then
		categoryStock = {}
		LatestStockByCategory[SelectedCategoryName] = categoryStock
	end

	local stockEntry = categoryStock[SelectedItemName]
	if stockEntry == nil then
		local frameQuantity = selectedFrame:GetAttribute("STOCK_QUANTITY")
		local robuxPriceAttr = selectedFrame:GetAttribute("PRODUCT_ROBUX_PRICE")
		local restockPriceAttr = selectedFrame:GetAttribute("RESTOCK_PRODUCT_PRICE")
		stockEntry = {
			Quantity = tonumber(frameQuantity) or 0,
			ProductRobuxPrice = typeof(robuxPriceAttr) == "number" and robuxPriceAttr or nil,
			RestockProductPrice = typeof(restockPriceAttr) == "number" and restockPriceAttr or nil,
		}
		categoryStock[SelectedItemName] = stockEntry
	end

	if config.Buttons then
		config.Buttons.LayoutOrder = (selectedFrame.LayoutOrder or 0) + 1
		config.Buttons.Visible = true
		updateButtonsForSelection(config, stockEntry)
	end

	ensureRobuxPrices(SelectedCategoryName, config, SelectedItemName, stockEntry)
end

function BaseShopScreenController:RefreshStock(): ()
	local stock = invokeStockAction("GetStock")
	if typeof(stock) ~= "table" then
		return
	end

	if stock[statusIdentifier] ~= nil then
		return
	end

	BaseShopScreenController:BuildCategories(stock)
	BaseShopScreenController:UpdateSelectedItemDisplay()
end

return BaseShopScreenController
