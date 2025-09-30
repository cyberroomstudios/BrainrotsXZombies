local UnitsScreenController = {}

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("UnitService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local Players = game:GetService("Players")

local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local PreviewController = require(Players.LocalPlayer.PlayerScripts.ClientModules.PreviewController)

local blocksScreen

function UnitsScreenController:Init()
	UnitsScreenController:CreateReferences()
	UnitsScreenController:InitButtonListerns()
end

function UnitsScreenController:Open()
	blocksScreen.Visible = not blocksScreen.Visible
	UnitsScreenController:BuildScreen()
end

function UnitsScreenController:InitButtonListerns() end

function UnitsScreenController:BuildScreen()
	for _, child in ipairs(blocksScreen:GetChildren()) do
		if child:IsA("TextButton") and not child:GetAttribute("IS_TEMPLATE") then
			child:Destroy()
		end
	end

	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetAllUnits",
		data = {},
	})

	for _, unit in result do
		local unitName = unit.UnitName
		local unitType = unit.UnitType
		local unitAmount = unit.Amount

		local itemButton = blocksScreen.UnitTemplate:Clone()
		itemButton.Parent = blocksScreen
		itemButton.Visible = true
		itemButton.Text = unitName .. "(" .. unitAmount .. ")"

		itemButton:SetAttribute("IS_TEMPLATE", false)
		itemButton.MouseButton1Click:Connect(function()
			PreviewController:Start(unitType, unitName)
		end)
	end
end

function UnitsScreenController:CreateReferences()
	-- Botões referentes aos Teleports
	blocksScreen = UIReferences:GetReference("BLOCKS_SCREEN")
end
return UnitsScreenController
