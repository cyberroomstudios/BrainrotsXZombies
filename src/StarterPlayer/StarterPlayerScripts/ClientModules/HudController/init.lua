local HudController = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local ClientModules = Players.LocalPlayer.PlayerScripts.ClientModules
local BackpackScreenController = require(ClientModules.BackpackScreenController)
local MeleeThreadController = require(ClientModules.MeleeThreadController)
local RangedController = require(ClientModules.RangedController)
local RangedTowerController = require(ClientModules.RangedTowerController)
local RemoveUnitController = require(ClientModules.RemoveUnitController)
local SpikesController = require(ClientModules.SpikesController)
local TeleportController = require(ClientModules.TeleportController)
local WaveController = require(ClientModules.WaveController)

local storeButton
local fightButton
local stopButton
local baseButton

local currentWave
local baseLife
local backpackFrame

-- Bottom
local OpenBackpackButton
local OpenRemoveUnitButton

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

	OpenBackpackButton = UIReferences:GetReference("SHOW_TOOLS_BUTTON_HUD")
	OpenRemoveUnitButton = UIReferences:GetReference("REMOVE_UNIT_BUTTON_HUD")
end

function HudController:InitButtonListerns()
	storeButton.MouseButton1Click:Connect(function()
		print("Click")
		TeleportController:ToBaseStore()
	end)

	baseButton.MouseButton1Click:Connect(function()
		TeleportController:ToBase()
	end)

	fightButton.MouseButton1Click:Connect(function()
		WaveController:Start(player)
		MeleeThreadController:StartThread()
		RangedController:StartThread()
		RangedTowerController:StartThread()
		SpikesController:Start()
	end)

	OpenBackpackButton.MouseButton1Click:Connect(function(): ()
		BackpackScreenController:ToggleVisibility()
		-- TODO use a generic approach later, after implementing all the 4 hotbar buttons
		if BackpackScreenController:IsOpen() and RemoveUnitController:IsActive() then
			RemoveUnitController:Stop()
		end
	end)

	OpenRemoveUnitButton.MouseButton1Click:Connect(function(): ()
		RemoveUnitController:Toggle()
		-- TODO use a generic approach later, after implementing all the 4 hotbar buttons
		if RemoveUnitController:IsActive() and BackpackScreenController:IsOpen() then
			BackpackScreenController:Close()
		end
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
