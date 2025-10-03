local BaseStoreScreenController = {}

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)

local screen
local timeRestockTextLabel
function BaseStoreScreenController:Init()
	BaseStoreScreenController:CreateReferences()
	BaseStoreScreenController:ConfigureProximity()
	BaseStoreScreenController:InitAttributeListener()
end

function BaseStoreScreenController:CreateReferences()
	screen = UIReferences:GetReference("BASE_SHOP_SCREEN")
	timeRestockTextLabel = UIReferences:GetReference("BASE_STORE_TIME_TEXTLABEL")
end

function BaseStoreScreenController:ConfigureProximity()
	local proximityPart = ClientUtil:WaitForDescendants(workspace, "map", "stores", "base", "store", "ProximityPart")
	local proximityPrompt = proximityPart.ProximityPrompt

	proximityPrompt.PromptShown:Connect(function()
		BaseStoreScreenController:Open()
		local result = bridge:InvokeServerAsync({
			[actionIdentifier] = "GetStock",
		})

		print(result)
	end)

	proximityPrompt.PromptHidden:Connect(function()
		BaseStoreScreenController:Close()
	end)
end

function BaseStoreScreenController:Open()
	screen.Visible = true
end

function BaseStoreScreenController:Close()
	screen.Visible = false
end

function BaseStoreScreenController:InitAttributeListener()
	workspace:GetAttributeChangedSignal("TIME_TO_RELOAD_RESTOCK"):Connect(function()
		local leftTime = workspace:GetAttribute("TIME_TO_RELOAD_RESTOCK")
		timeRestockTextLabel.Text = "Shop Restock In:" .. ClientUtil:FormatSecondsToMinutes(leftTime)
	end)
end

return BaseStoreScreenController
