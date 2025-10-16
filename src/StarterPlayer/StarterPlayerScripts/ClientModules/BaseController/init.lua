local BaseController = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)

local player = Players.LocalPlayer
local lifeContent
local lifeText

function BaseController:Init(): ()
	BaseController:CreateReferences()
	BaseController:InitBaseLifeListener()
end

function BaseController:CreateReferences(): ()
	-- Botões referentes aos Teleports
	lifeContent = UIReferences:GetReference("LIFE_CONTENT")
	lifeText = UIReferences:GetReference("LIFE_TEXT")
end

function BaseController:GetBase(): Part
	local baseNumber = player:GetAttribute("BASE")
	if baseNumber then
		local base = ClientUtil:WaitForDescendants(workspace, "map", "baseLocations", baseNumber)
		if base then
			return base
		end
	end
end

function BaseController:InitBaseLifeListener(): ()
	player:GetAttributeChangedSignal("BASE_LIFE"):Connect(function()
		local baseLife = tonumber(player:GetAttribute("BASE_LIFE")) or 0
		local newSize = UDim2.fromScale(baseLife / 100, 1)

		local tween = TweenService:Create(lifeContent, TweenInfo.new(0.3, Enum.EasingStyle.Linear), { Size = newSize })
		tween:Play()

		lifeText.Text = "BASE LIFE: " .. baseLife .. "%"
	end)
end

return BaseController
