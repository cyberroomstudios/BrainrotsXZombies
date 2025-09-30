local HudController = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local TeleportController = require(Players.LocalPlayer.PlayerScripts.ClientModules.TeleportController)
local WaveController = require(Players.LocalPlayer.PlayerScripts.ClientModules.WaveController)
local BlockScreenController = require(Players.LocalPlayer.PlayerScripts.ClientModules.BlockScreenController)

local storeButton
local fightButton
local stopButton
local baseButton

local currentWave
local baseLife
local backpackFrame

-- Bottom
local toolsButton

function HudController:Init()
	HudController:CreateReferences()
	HudController:InitButtonListerns()
	HudController:InitGameStatusListener()
end

function HudController:CreateReferences()
	-- Botões referentes aos Teleports
	storeButton = UIReferences:GetReference("STORE_BUTTON_HUD")
	fightButton = UIReferences:GetReference("FIGHT_BUTTON_HUD")
	stopButton = UIReferences:GetReference("STOP_BUTTON_HUD")
	baseButton = UIReferences:GetReference("BASE_BUTTON_HUD")

	currentWave = UIReferences:GetReference("CURRENT_WAVE_HUD")
	baseLife = UIReferences:GetReference("BASE_LIFE_HUD")
	backpackFrame = UIReferences:GetReference("BACKPACK_HUD")

	toolsButton = UIReferences:GetReference("SHOW_TOOLS_BUTTON_HUD")
end

function HudController:InitButtonListerns()
	baseButton.MouseButton1Click:Connect(function()
		TeleportController:ToBase()
	end)

	fightButton.MouseButton1Click:Connect(function()
		WaveController:Start(player)
	end)

	toolsButton.MouseButton1Click:Connect(function()
		BlockScreenController:Open()
	end)
end

function HudController:InitGameStatusListener()
	player:GetAttributeChangedSignal("GAME_ON"):Connect(function()
		local gameOn = player:GetAttribute("GAME_ON")

		if gameOn then
			fightButton.Visible = false
			baseButton.Visible = false
			storeButton.Visible = false
			backpackFrame.Visible = false

			stopButton.Visible = true
			currentWave.Visible = true
			baseLife.Visible = true
		else
			fightButton.Visible = true
			baseButton.Visible = true
			storeButton.Visible = true
			backpackFrame.Visible = true

			stopButton.Visible = false
			currentWave.Visible = false
			baseLife.Visible = false
		end
	end)
end

return HudController
