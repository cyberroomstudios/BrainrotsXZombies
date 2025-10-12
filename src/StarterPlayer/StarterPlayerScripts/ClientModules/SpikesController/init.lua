local SpikesController = {}
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("ThreadService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

function SpikesController:Init() end

function SpikesController:Start()
	task.spawn(function()
		local spikesModeList = workspace.runtime[player.UserId]["SPIKES"]:GetChildren()

		for _, value in spikesModeList do
			local touchedHumanoids = {}
			local primaryPart = value.PrimaryPart

			primaryPart.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then
					return
				end

				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				if not humanoid then
					return
				end

				local isEnemy = humanoid.Parent:GetAttribute("IS_ENEMY")

				if not isEnemy then
					return
				end

				if touchedHumanoids[humanoid] then
					return
				end

				touchedHumanoids[humanoid] = true

				local result = bridge:InvokeServerAsync({
					[actionIdentifier] = "TakeDamage",
					data = {
						Model = humanoid.Parent,
					},
				})
			end)
		end
	end)
end

return SpikesController
