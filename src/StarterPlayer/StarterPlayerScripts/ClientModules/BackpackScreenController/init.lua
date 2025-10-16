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

-- === GLOBAL VARIABLES
function BackpackScreenController:Init(): ()
	BackpackScreenController:CreateReferences()
	BackpackScreenController:InitButtonListeners()
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

function BackpackScreenController:ToggleVisibility(): ()
	if Screen.Visible then
		BackpackScreenController:Close()
	else
		BackpackScreenController:Open()
	end
end

function BackpackScreenController:Open(): ()
	Screen.Visible = true
	BackpackScreenController:BuildScreen()
end

function BackpackScreenController:Close(): ()
	Screen.Visible = false
	for _, item in ItemsContainer:GetChildren() do
		if not item:IsA("UIGridLayout") then
			item:Destroy()
		end
	end
	PreviewController:Stop()
end

function BackpackScreenController:BuildScreen(): ()
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
		quantityLabel.Text = `x{unitAmount}`
		-- TODO implement the 3D preview using ViewportFrame
	end
end

return BackpackScreenController
