local WaveController = {}

-- Init Bridg Net
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local bridge = BridgeNet2.ReferenceBridge("WaveService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local player = Players.LocalPlayer

local currentWaveText
function WaveController:Init()
	WaveController:CreateReferences()
	WaveController:InitGameStatusListener()
end

function WaveController:Start(player: Player)
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "StartWave",
		data = {},
	})
end

function WaveController:CreateReferences()
	-- Botões referentes aos Teleports
	currentWaveText = UIReferences:GetReference("CURRENT_WAVE_TEXT")
end

function WaveController:InitGameStatusListener()
	player:GetAttributeChangedSignal("CURRENT_WAVE"):Connect(function()
		local currentWave = player:GetAttribute("CURRENT_WAVE")
		currentWaveText.Text = "Wave: " .. currentWave
	end)
end
return WaveController
