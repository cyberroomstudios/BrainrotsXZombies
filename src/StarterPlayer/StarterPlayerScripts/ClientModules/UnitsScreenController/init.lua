local UnitsScreenController = {}

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

-- === GLOBAL VARIABLES
function UnitsScreenController:Init(): ()
	UnitsScreenController:CreateReferences()
	UnitsScreenController:InitButtonListeners()
end

function UnitsScreenController:CreateReferences(): ()
	Screen = UIReferences:GetReference("BACKPACK_SCREEN")
	ItemsContainer = UIReferences:GetReference("BACKPACK_ITEMS_CONTAINER")
	ItemTemplate = ReplicatedStorage.GUI.Backpack.ITEM
	CloseButton = UIReferences:GetReference("BACKPACK_CLOSE_BUTTON")
end

function UnitsScreenController:InitButtonListeners(): ()
	CloseButton.MouseButton1Click:Connect(function(): ()
		UnitsScreenController:Close()
	end)
end

function UnitsScreenController:Open(): ()
	Screen.Visible = true
	UnitsScreenController:BuildScreen()
end

function UnitsScreenController:Close(): ()
	Screen.Visible = false
	for _, item in ItemsContainer:GetChildren() do
		if not item:IsA("UIGridLayout") then
			item:Destroy()
		end
	end
end

function UnitsScreenController:BuildScreen(): ()
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetAllUnits",
		data = {},
	})
	print(result)
	for _, unit in pairs(result) do
		local unitName: string = unit.UnitName
		local unitType: string = unit.UnitType
		local unitAmount: number = unit.Amount
		local itemButton: TextButton = ItemTemplate:Clone()
		itemButton.Parent = ItemsContainer
		itemButton.Visible = true
		itemButton.MouseButton1Click:Connect(function(): ()
			PreviewController:Start(unitType, unitName)
		end)
		local quantityLabel: TextLabel = itemButton:FindFirstChild("Quantity", true)
		quantityLabel.Text = tostring(unitAmount)
		-- TODO implement the 3D preview using ViewportFrame
	end
end

return UnitsScreenController
