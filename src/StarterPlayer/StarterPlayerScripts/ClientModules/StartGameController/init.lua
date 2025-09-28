local StartGameController = {}

-- Init Bridg Net
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local PreviewController = require(Players.LocalPlayer.PlayerScripts.ClientModules.PreviewController)
local bridge = BridgeNet2.ReferenceBridge("StartGameService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

function StartGameController:Init(data)
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "Start",
		data = {},
	})
end
return StartGameController
