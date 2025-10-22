local BackpackScreenWrapper = {}
BackpackScreenWrapper.__index = BackpackScreenWrapper

-- === SERVICES
local Players = game:GetService("Players")

-- === CUSTOM TYPES
type ItemWidgets = { Button: GuiButton, QuantityLabel: TextLabel? }
export type ItemsDictionary = { [string]: { ItemWidgets } }
export type Entry = { Key: string, Amount: number? }
export type BackpackScreenWrapper = {
	Items: ItemsDictionary?,
	new: (
		screen: Frame,
		itemsContainer: Frame,
		closeButton: GuiButton,
		itemTemplate: GuiButton
	) -> BackpackScreenWrapper,
	Open: (self: BackpackScreenWrapper) -> (),
	Close: (self: BackpackScreenWrapper) -> (),
	Toggle: (self: BackpackScreenWrapper) -> (),
	CreateItem: (self: BackpackScreenWrapper, key: string, amount: number?) -> ItemsDictionary,
	BuildItems: (self: BackpackScreenWrapper, entries: { Entry }) -> (),
	SetItemQuantity: (self: BackpackScreenWrapper, key: string, amount: number?) -> (),
	OnItemActivated: ((key: string) -> ())?,
	OnOpen: (() -> ())?,
	OnClose: (() -> ())?,
}
type Private = {
	Screen: Frame?,
	ItemsContainer: Frame?,
	CloseButton: GuiButton?,
	ItemTemplate: GuiButton,
}

-- === PRIVATE VARIABLES
local __: { [BackpackScreenWrapper]: Private } = setmetatable({}, { __mode = "k" })

-- === CONSTRUCTOR
function BackpackScreenWrapper.new(
	screen: Frame,
	itemsContainer: Frame,
	closeButton: GuiButton,
	itemTemplate: GuiButton
): BackpackScreenWrapper
	assert(screen ~= nil, "BackpackScreenWrapper: screen is nil.")
	assert(itemsContainer ~= nil, "BackpackScreenWrapper: itemsContainer is nil.")
	assert(closeButton ~= nil, "BackpackScreenWrapper: closeButton is nil.")
	assert(itemTemplate ~= nil, "BackpackScreenWrapper: itemTemplate is nil.")

	local self: BackpackScreenWrapper = setmetatable({}, BackpackScreenWrapper)
	__[self] = {
		Screen = screen,
		ItemsContainer = itemsContainer,
		CloseButton = closeButton,
		ItemTemplate = itemTemplate,
	}

	closeButton.MouseButton1Click:Connect(function(): ()
		self:Close()
	end)

	return self
end

-- === GLOBAL FUNCTIONS
function BackpackScreenWrapper:Open(): ()
	__[self].Screen.Visible = true
	if self.OnOpen then
		self.OnOpen()
	end
end

function BackpackScreenWrapper:Close(): ()
	__[self].Screen.Visible = false
	if self.OnClose then
		self.OnClose()
	end
end

function BackpackScreenWrapper:IsOpen(): boolean
	return __[self].Screen.Visible
end

function BackpackScreenWrapper:Toggle(): ()
	if self:IsOpen() then
		self:Close()
	else
		self:Open()
	end
end

function BackpackScreenWrapper:CreateItem(key: string, amount: number?): ItemsDictionary
	self.Items = self.Items or {}
	if self.Items[key] then
		warn(`BackpackScreenWrapper: item {key} already exists.`)
		return self.Items
	end
	local private: Private = __[self]

	local itemButton = private.ItemTemplate:Clone()
	if not itemButton then
		warn("BackpackScreenWrapper: item template not available.")
		return self.Items
	end

	itemButton.Parent = private.ItemsContainer
	itemButton.Visible = true
	itemButton.MouseButton1Click:Connect(function(): ()
		if self.OnItemActivated then
			self.OnItemActivated(key)
		end
	end)

	local quantityLabel = itemButton:FindFirstChild("Quantity", true)
	if quantityLabel and quantityLabel:IsA("TextLabel") then
		quantityLabel.Text = amount and `x{amount}` or ""
	else
		warn(`BackpackScreenWrapper: quantity label not found for {key}.`)
		quantityLabel = nil
	end

	self.Items[key] = {
		Button = itemButton,
		QuantityLabel = quantityLabel,
	}

	return self.Items
end

function BackpackScreenWrapper:BuildItems(entries: { Entry }?): ItemsDictionary
	if typeof(entries) ~= "table" then
		warn("BackpackScreenWrapper: expected table of units while building items.")
		return {}
	end

	local items: ItemsDictionary = {}
	for _, unit in pairs(entries) do
		items = self:CreateItem(unit.Key, unit.Amount)
	end
	return items
end

function BackpackScreenWrapper:SetItemQuantity(key: string, amount: number?): ()
	if self.Items then
		local item = self.Items[key]
		if item then
			if item.QuantityLabel then
				item.QuantityLabel.Text = amount and `x{amount}` or ""
			end
		end
	end
end

return BackpackScreenWrapper
