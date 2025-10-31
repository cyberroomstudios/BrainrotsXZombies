local EggsAndCratesScreenController = {}

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("BrainrotEggService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net
local Players = game:GetService("Players")

local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local Tags = require(ReplicatedStorage.Enums.Tags)

local screen

function EggsAndCratesScreenController:Init()
	EggsAndCratesScreenController:CreateReferences()
end

function EggsAndCratesScreenController:CreateReferences()
	-- Botões referentes aos Teleports
	screen = UIReferences:GetReference(Tags.EGGS_AND_CRATES_SCREEN)
end

function EggsAndCratesScreenController:Open()
	screen.Visible = not screen.Visible
	EggsAndCratesScreenController:BuildEggs()
end

function EggsAndCratesScreenController:Close()
	screen.Visible = false
end

function EggsAndCratesScreenController:IsOpen(): boolean
	return screen.Visible
end

function EggsAndCratesScreenController:Toggle()
	if EggsAndCratesScreenController:IsOpen() then
		EggsAndCratesScreenController:Close()
	else
		EggsAndCratesScreenController:Open()
	end
end

function EggsAndCratesScreenController:BuildEggs()
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetEggs",
	})

	print(result)
end

return EggsAndCratesScreenController
