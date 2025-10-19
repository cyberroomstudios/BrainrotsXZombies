local BackpackScreenController = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("UnitService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local PreviewController = require(Players.LocalPlayer.PlayerScripts.ClientModules.PreviewController)

-- === LOCAL VARIABLES
local Screen: Frame
local ItemsContainer: Frame
local ItemTemplate: TextButton
local CloseButton: TextButton
local RemoveAllButton: TextButton
local Items: { [string]: { [string]: { Button: TextButton, QuantityLabel: TextLabel } } }

-- === GLOBAL FUNCTIONS
function BackpackScreenController:Init(): ()
	BackpackScreenController:CreateReferences()
	BackpackScreenController:InitButtonListeners()
	BackpackScreenController:InitBridgeListener()
end

function BackpackScreenController:CreateReferences(): ()
	Screen = UIReferences:GetReference("BACKPACK_SCREEN")
	ItemsContainer = UIReferences:GetReference("BACKPACK_ITEMS_CONTAINER")
	ItemTemplate = ReplicatedStorage.GUI.Backpack.ITEM
	CloseButton = UIReferences:GetReference("BACKPACK_CLOSE_BUTTON")
	RemoveAllButton = UIReferences:GetReference("BACKPACK_REMOVE_ALL_BUTTON")
end

function BackpackScreenController:InitButtonListeners(): ()
	CloseButton.MouseButton1Click:Connect(function(): ()
		BackpackScreenController:Close()
	end)
	RemoveAllButton.MouseButton1Click:Connect(function(): ()
		PreviewController:RemoveAllItems()
	end)
end

function BackpackScreenController:InitBridgeListener(): ()
	bridge:Connect(function(response: table): ()
		if typeof(response) ~= "table" then
			return
		end
		local action = response[actionIdentifier]
		if action == "ItemQuantityChanged" then
			local unitName: string = response.UnitName
			local unitType: string = response.UnitType
			local amount: number = response.Amount
			BackpackScreenController:SetItemQuantity(unitType, unitName, amount)
		elseif action == "ItemAdded" then
			local unitName: string = response.UnitName
			local unitType: string = response.UnitType
			local amount: number = response.Amount
			BackpackScreenController:SetItemQuantity(unitType, unitName, amount)
		end
	end)
end

function BackpackScreenController:ToggleVisibility(): ()
	if Screen.Visible then
		BackpackScreenController:Close()
	else
		BackpackScreenController:Open()
	end
end

function BackpackScreenController:Open(): ()
	Screen.Visible = true
	if Items == nil then
		BackpackScreenController:BuildScreen()
	end
end

function BackpackScreenController:Close(): ()
	Screen.Visible = false
	PreviewController:Stop()
end

function BackpackScreenController:IsOpen(): boolean
	return Screen ~= nil and Screen.Visible
end

function BackpackScreenController:BuildScreen(): ()
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetAllUnits",
		data = {},
	})
	Items = {}
	for _, unit in pairs(result) do
		BackpackScreenController:CreateItem(unit.UnitType, unit.UnitName, unit.Amount)
	end
end

function BackpackScreenController:CreateItem(unitType: string, unitName: string, amount: number): ()
	if Items and Items[unitType] and Items[unitType][unitName] then
		warn(`UNEXPECTED: There's already a unit of type {unitType} with name {unitName} in the backpack.`)
		return
	end
	local itemButton: TextButton = ItemTemplate:Clone()
	itemButton.Parent = ItemsContainer
	itemButton.Visible = true
	itemButton.MouseButton1Click:Connect(function(): ()
		PreviewController:Start(unitType, unitName)
	end)
	local quantityLabel: TextLabel = itemButton:FindFirstChild("Quantity", true)
	quantityLabel.Text = `x{amount}`
	Items[unitType] = Items[unitType] or {}
	Items[unitType][unitName] = { Button = itemButton, QuantityLabel = quantityLabel }
end

function BackpackScreenController:SetItemQuantity(unitType: string, unitName: string, amount: number): ()
	if Items and Items[unitType] and Items[unitType][unitName] then
		Items[unitType][unitName].QuantityLabel.Text = `x{amount}`
	else
		print(`Skipped updating {unitType}/{unitName} quantity because it does not exist in the backpack UI.`)
	end
end

return BackpackScreenController
