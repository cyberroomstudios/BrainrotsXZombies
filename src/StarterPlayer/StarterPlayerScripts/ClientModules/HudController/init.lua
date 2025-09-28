local HudController = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local TeleportController = require(Players.LocalPlayer.PlayerScripts.ClientModules.TeleportController)
local WaveController = require(Players.LocalPlayer.PlayerScripts.ClientModules.WaveController)
local BlockScreenController = require(Players.LocalPlayer.PlayerScripts.ClientModules.BlockScreenController)

local baseButton
local startButton

-- Bottom
local blockButton

function HudController:Init()
	HudController:CreateReferences()
	HudController:InitButtonListerns()
end

function HudController:CreateReferences()
	-- Botões referentes aos Teleports
	baseButton = UIReferences:GetReference("BASE_BUTTON_HUD")
	startButton = UIReferences:GetReference("START_BUTTON_HUD")
	blockButton = UIReferences:GetReference("SHOW_BLOCK_HUD")
end

function HudController:InitButtonListerns()
	baseButton.MouseButton1Click:Connect(function()
		TeleportController:ToBase()
	end)

	startButton.MouseButton1Click:Connect(function()
		WaveController:Start(player)
	end)

	blockButton.MouseButton1Click:Connect(function()
		BlockScreenController:Open()
	end)
end

return HudController
