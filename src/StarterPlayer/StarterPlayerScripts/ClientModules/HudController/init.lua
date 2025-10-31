local HudController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local ClientModules = Players.LocalPlayer.PlayerScripts.ClientModules
local UnitsBackpackScreenController = require(ClientModules.UnitsBackpackScreenController)
local WeaponsBackpackScreenController = require(ClientModules.WeaponsBackpackScreenController)
local MeleeThreadController = require(ClientModules.MeleeThreadController)
local RangedController = require(ClientModules.RangedController)
local RangedTowerController = require(ClientModules.RangedTowerController)
local RemoveUnitController = require(ClientModules.RemoveUnitController)
local SpikesController = require(ClientModules.SpikesController)
local TeleportController = require(ClientModules.TeleportController)
local WaveController = require(ClientModules.WaveController)
local EggsAndCratesScreenController =
	require(Players.LocalPlayer.PlayerScripts.ClientModules.EggsAndCratesScreenController)
local Tags = require(ReplicatedStorage.Enums.Tags)

local HUD_SCREENS = {
	UnitsBackpack = UnitsBackpackScreenController,
	RemoveUnit = RemoveUnitController,
	WeaponsBackpack = WeaponsBackpackScreenController,
	EggsAndCrates = EggsAndCratesScreenController,
}

local storeButton
local fightButton
local stopButton
local baseButton

local currentWave
local baseLife

-- Bottom
local OpenBackpackButton: GuiButton
local OpenRemoveUnitButton: GuiButton
local OpenWeaponsBackpackButton: GuiButton
local toolsButton
local eggAndCratesButton

function HudController:Init()
	HudController:CreateReferences()
	HudController:InitButtonListerns()
	HudController:InitGameStatusListener()
end

function HudController:CreateReferences()
	-- Botões referentes aos Teleports
	storeButton = UIReferences:GetReference(Tags.HUD_BUTTON_SHOP)
	fightButton = UIReferences:GetReference(Tags.HUD_BUTTON_FIGHT)
	stopButton = UIReferences:GetReference(Tags.HUD_BUTTON_STOP_FIGHT)
	baseButton = UIReferences:GetReference(Tags.HUD_BUTTON_BASE)

	currentWave = UIReferences:GetReference(Tags.HUD_WAVE_CONTAINER)
	baseLife = UIReferences:GetReference(Tags.HUD_HEALTH_CONTAINER)

	OpenBackpackButton = UIReferences:GetReference(Tags.HUD_HOTBAR_BUTTON_UNITS_BACKPACK)
	OpenRemoveUnitButton = UIReferences:GetReference(Tags.HUD_HOTBAR_BUTTON_REMOVE_UNIT)
	OpenWeaponsBackpackButton = UIReferences:GetReference(Tags.HUD_HOTBAR_BUTTON_WEAPONS_BACKPACK)
	toolsButton = UIReferences:GetReference(Tags.HUD_HOTBAR_BUTTON_UNITS_BACKPACK)

	eggAndCratesButton = UIReferences:GetReference(Tags.HUD_HOTBAR_BUTTON_EGGS_AND_CRATES)
end

function HudController:InitButtonListerns()
	storeButton.MouseButton1Click:Connect(function()
		TeleportController:ToBaseShop()
	end)

	baseButton.MouseButton1Click:Connect(function()
		TeleportController:ToBase()
	end)

	stopButton.MouseButton1Click:Connect(function()
		WaveController:Stop(player)
	end)
	fightButton.MouseButton1Click:Connect(function()
		WaveController:Start(player)
		MeleeThreadController:StartThread()
		RangedController:StartThread()
		RangedTowerController:StartThread()
		SpikesController:Start()
	end)

	local function closeOthers(openedScreenController)
		if openedScreenController:IsOpen() then
			for _, screenController in pairs(HUD_SCREENS) do
				if screenController ~= openedScreenController and screenController:IsOpen() then
					screenController:Close()
				end
			end
		end
	end

	OpenBackpackButton.MouseButton1Click:Connect(function(): ()
		UnitsBackpackScreenController:Toggle()
		closeOthers(UnitsBackpackScreenController)
	end)

	OpenRemoveUnitButton.MouseButton1Click:Connect(function(): ()
		RemoveUnitController:Toggle()
		closeOthers(RemoveUnitController)
	end)

	OpenWeaponsBackpackButton.MouseButton1Click:Connect(function(): ()
		WeaponsBackpackScreenController:Toggle()
		closeOthers(WeaponsBackpackScreenController)
	end)

	eggAndCratesButton.MouseButton1Click:Connect(function(): ()
		EggsAndCratesScreenController:Toggle()
		closeOthers(EggsAndCratesScreenController)
	end)
end

function HudController:InitGameStatusListener()
	player:GetAttributeChangedSignal("GAME_ON"):Connect(function()
		local gameOn = player:GetAttribute("GAME_ON")

		if gameOn then
			fightButton.Visible = false
			baseButton.Visible = false
			storeButton.Visible = false

			stopButton.Visible = true
			currentWave.Visible = true
			baseLife.Visible = true
		else
			fightButton.Visible = true
			baseButton.Visible = true
			storeButton.Visible = true

			stopButton.Visible = false
			currentWave.Visible = false
			baseLife.Visible = false
		end
	end)
end

return HudController
