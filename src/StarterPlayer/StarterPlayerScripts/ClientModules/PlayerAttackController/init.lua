local PlayerAttackController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local tracks: { AnimationTrack } = {}
local isAttack = false
local currentAttack = 1

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PlayerAttackService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net


function PlayerAttackController:Init()
	PlayerAttackController:ConfigureButtonListners()
	PlayerAttackController:Configure()
end

function PlayerAttackController:Configure()
	local player: Player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid: Humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator: Animator = humanoid:FindFirstChildOfClass("Animator")

	local rightPlayerAttackAnimation = ReplicatedStorage.animations.rightPlayerAttack
	local leftPlayerAttackAnimation = ReplicatedStorage.animations.leftPlayerAttack

	table.insert(tracks, animator:LoadAnimation(rightPlayerAttackAnimation))
	table.insert(tracks, animator:LoadAnimation(leftPlayerAttackAnimation))
end

function PlayerAttackController:ConfigureButtonListners()
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or isAttack then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			isAttack = true
			local track = tracks[currentAttack]
			track:Play()

			track:GetMarkerReachedSignal("HIT"):Once(function(param: number)
				local result = bridge:InvokeServerAsync({
					[actionIdentifier] = "Hit",
					data = {},
				})
			end)

			track.Stopped:Once(function()
				currentAttack += 1
				isAttack = false

				if currentAttack > #tracks then
					currentAttack = 1
				end
			end)
			print("Attack")
		end
	end)
end

return PlayerAttackController
