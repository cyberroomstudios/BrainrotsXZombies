local BaseStoreScreenController = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)

-- === ENUMS
local Blocks = require(ReplicatedStorage.Enums.blocks)
local Melee = require(ReplicatedStorage.Enums.melee)
local Ranged = require(ReplicatedStorage.Enums.ranged)

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
			ContainerTag = "BLOCKS_CONTAINER",
			TabButtonTag = "BASE_SHOP_BLOCKS_TAB_BUTTON",
		},
		Melee = {
			Enum = Melee,
			Type = "MELEE",
			ContainerTag = "MELEE_CONTAINER",
			TabButtonTag = "BASE_SHOP_MELEE_TAB_BUTTON",
		},
		Ranged = {
			Enum = Ranged,
			Type = "RANGED",
			ContainerTag = "RANGED_CONTAINER",
			TabButtonTag = "BASE_SHOP_RANGED_TAB_BUTTON",
		},
	}

-- === LOCAL VARIABLES
local Screen: Frame
local TimeRestockTextLabel: TextLabel
local SelectedItem: table? = nil
local RestockAllButton: TextButton
local CloseButton: TextButton

-- === LOCAL FUNCTIONS
local function refreshScrollingFrameCanvasSize(frame: ScrollingFrame): ()
	local uiListLayout: UIListLayout = frame:FindFirstChildWhichIsA("UIListLayout")
	frame.CanvasSize =
		UDim2.new(0, 0, uiListLayout.Padding.Scale, uiListLayout.AbsoluteContentSize.Y + uiListLayout.Padding.Offset)
end

-- === GLOBAL FUNCTIONS
function BaseStoreScreenController:Init(): ()
	BaseStoreScreenController:CreateReferences()
	BaseStoreScreenController:ConfigureProximityPrompt()
	BaseStoreScreenController:InitAttributeListener()
	BaseStoreScreenController:CreateButtonListeners()
end

function BaseStoreScreenController:CreateReferences(): ()
	Screen = UIReferences:GetReference("BASE_SHOP_SCREEN")
	TimeRestockTextLabel = UIReferences:GetReference("BASE_STORE_TIME_TEXTLABEL")
	RestockAllButton = UIReferences:GetReference("BASE_SHOP_RESTOCK_BUTTON")
	CloseButton = UIReferences:GetReference("BASE_SHOP_CLOSE_BUTTON")
	for categoryName, config in pairs(CATEGORY_CONFIG) do
		local container = UIReferences:GetReference(config.ContainerTag)
		config.Container = container
		if container then
			config.Buttons = container:FindFirstChild("BUTTONS")
			if config.Buttons then
				config.Buttons.Visible = false
			else
				error("Container doesn't have BUTTONS child for category " .. categoryName)
			end
		else
			error("Container not found for category " .. categoryName)
		end
		local tabButton = UIReferences:GetReference(config.TabButtonTag)
		config.TabButton = tabButton
		if not tabButton then
			error("Tab button not found for category " .. categoryName)
		end
	end
end

function BaseStoreScreenController:ClearScreen(): ()
	SelectedItem = nil
	for _, config in pairs(CATEGORY_CONFIG) do
		for _, child in config.Container:GetChildren() do
			if (not child:IsA("UIListLayout")) and child.Name ~= "BUTTONS" then
				child:Destroy()
			end
		end
		config.Buttons.Visible = false
	end
end

function BaseStoreScreenController:CreateButtonListeners(): ()
	RestockAllButton.MouseButton1Click:Connect(function(): ()
		print("Restock all")
	end)

	CloseButton.MouseButton1Click:Connect(function(): ()
		BaseStoreScreenController:Close()
	end)

	for _, config in pairs(CATEGORY_CONFIG) do
		local buttons = config.Buttons
		local buyButton = buttons:FindFirstChild("Buy")
		local robuxButton = buttons:FindFirstChild("Robux")
		local restockButton = buttons:FindFirstChild("Restock")

		if buyButton and buyButton:IsA("GuiButton") then
			buyButton.MouseButton1Click:Connect(function()
				if not SelectedItem then
					return
				end
				if SelectedItem.Type ~= config.Type then
					return
				end
				bridge:InvokeServerAsync({
					[actionIdentifier] = "BuyItem",
					data = {
						Item = SelectedItem,
					},
				})
			end)
		end

		if robuxButton and robuxButton:IsA("GuiButton") then
			robuxButton.MouseButton1Click:Connect(function()
				print("Robux purchase flow not implemented for " .. config.Type)
			end)
		end

		if restockButton and restockButton:IsA("GuiButton") then
			restockButton.MouseButton1Click:Connect(function()
				print("Restock requested for " .. config.Type)
			end)
		end

		local tabButton = config.TabButton
		if tabButton and tabButton:IsA("GuiButton") then
			tabButton.MouseButton1Click:Connect(function()
				for _, otherConfig in pairs(CATEGORY_CONFIG) do
					otherConfig.Container.Visible = false
				end
				config.Container.Visible = true
				refreshScrollingFrameCanvasSize(config.Container)
			end)
		end
	end
end

function BaseStoreScreenController:ConfigureProximityPrompt(): ()
	local proximityPart = ClientUtil:WaitForDescendants(workspace, "map", "stores", "base", "store", "ProximityPart")
	local proximityPrompt = proximityPart.ProximityPrompt

	proximityPrompt.PromptShown:Connect(function(): ()
		BaseStoreScreenController:ClearScreen()
		BaseStoreScreenController:Open()
		local result = bridge:InvokeServerAsync({
			[actionIdentifier] = "GetStock",
		})
		BaseStoreScreenController:BuildCategories(result)
	end)

	proximityPrompt.PromptHidden:Connect(function(): ()
		BaseStoreScreenController:Close()
	end)
end

function BaseStoreScreenController:Open(): ()
	Screen.Visible = true
end

function BaseStoreScreenController:Close(): ()
	Screen.Visible = false
end

function BaseStoreScreenController:InitAttributeListener(): ()
	workspace:GetAttributeChangedSignal("TIME_TO_RELOAD_RESTOCK"):Connect(function()
		local leftTime = workspace:GetAttribute("TIME_TO_RELOAD_RESTOCK")
		TimeRestockTextLabel.Text = "Shop Restock In:" .. ClientUtil:FormatSecondsToMinutes(leftTime)
	end)
end

function BaseStoreScreenController:BuildCategories(stockByCategory: table): ()
	if not stockByCategory then
		return
	end

	for categoryName, _ in pairs(CATEGORY_CONFIG) do
		BaseStoreScreenController:BuildCategoryItems(categoryName, stockByCategory[categoryName])
	end
end

function BaseStoreScreenController:BuildCategoryItems(categoryName: string, stockList: table?): ()
	local config = CATEGORY_CONFIG[categoryName]
	local container = config.Container
	local enum = config.Enum
	local itemsFolder = ReplicatedStorage.GUI.Shop.Items

	for itemName, _ in stockList do
		local itemInfo = enum[itemName]

		if itemInfo then
			local template = itemsFolder[itemInfo.Rarity]
			if template then
				local newItem = template:Clone()

				newItem.Content.MainInfos.ItemName.Text = itemInfo.GUI.Name
				newItem.Content.MainInfos.Desc.Text = itemInfo.GUI.Description
				newItem.Content.MainInfos.Price.Text = ClientUtil:FormatToUSD(itemInfo.Price)

				newItem.Name = itemName
				newItem.LayoutOrder = itemInfo.GUI.Order
				newItem.Parent = container

				newItem.MouseButton1Click:Connect(function()
					SelectedItem = {
						Type = config.Type,
						Name = itemName,
					}

					for _, child in container:GetChildren() do
						if child ~= config.Buttons and not child:IsA("UIListLayout") then
							if child.LayoutOrder > newItem.LayoutOrder then
								child.LayoutOrder += 1
							end
						end
					end

					config.Buttons.LayoutOrder = newItem.LayoutOrder + 1
				end)
			end
		end
	end

	refreshScrollingFrameCanvasSize(config.Container)
end

return BaseStoreScreenController
