local YouDiedScreenController = {}

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local Tags = require(ReplicatedStorage.Enums.Tags)
local bridge = BridgeNet2.ReferenceBridge("DiedService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local Players = game:GetService("Players")

local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)

local screen
local closeButton

function YouDiedScreenController:Init()
	YouDiedScreenController:CreateReferences()
	YouDiedScreenController:InitButtonListerns()
	YouDiedScreenController:InitBridgeListener()
end

function YouDiedScreenController:CreateReferences()
	-- Botões referentes aos Teleports
	screen = UIReferences:GetReference(Tags.YOU_DIED_SCREEN)
	closeButton = UIReferences:GetReference(Tags.YOU_DIED_BUTTON_CLOSE)
end

function YouDiedScreenController:InitBridgeListener()
	bridge:Connect(function(response)
		if response[actionIdentifier] == "ShowYouDiedScreen" then
			YouDiedScreenController:Open()
		end
	end)
end

function YouDiedScreenController:Open()
	screen.Visible = true
end

function YouDiedScreenController:Close()
	screen.Visible = false
end

function YouDiedScreenController:InitButtonListerns()
	closeButton.MouseButton1Click:Connect(function()
		YouDiedScreenController:Close()
	end)
end

return YouDiedScreenController
