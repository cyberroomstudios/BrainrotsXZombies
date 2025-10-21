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

local screen

function EggsAndCratesScreenController:Init()
	EggsAndCratesScreenController:CreateReferences()
end

function EggsAndCratesScreenController:CreateReferences()
	-- Botões referentes aos Teleports
	screen = UIReferences:GetReference("EGGS_AND_CRATES")
end

function EggsAndCratesScreenController:Open()
	screen.Visible = not screen.Visible
	EggsAndCratesScreenController:BuildEggs()
end

function EggsAndCratesScreenController:BuildEggs()
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetEggs",
	})

	print(result)
end

return EggsAndCratesScreenController
