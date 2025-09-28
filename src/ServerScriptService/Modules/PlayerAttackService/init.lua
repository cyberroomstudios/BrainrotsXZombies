local PlayerAttackService = {}

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PlayerAttackService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

function PlayerAttackService:Init()
	PlayerAttackService:InitBridgeListener()
end

function PlayerAttackService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "Hit" then
			print("Teste")
			PlayerAttackService:OnPlayerAttack(player)
		end
	end
end

function PlayerAttackService:OnPlayerAttack(player: Player)
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }

	local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 4, params)

	for _, part in parts do
		local vCharacter = part.Parent
		if not vCharacter then
			continue
		end

		local vHumanoid = vCharacter:FindFirstChildOfClass("Humanoid")
		if not vHumanoid or vHumanoid.Health <= 0 then
			continue
		end

		-- Adiciona o evento só uma vez
		if not vCharacter:GetAttribute("RagdollConnected") then
			vCharacter:SetAttribute("RagdollConnected", true)
			vHumanoid.Died:Connect(function()
				PlayerAttackService:MakeRagdoll(vCharacter)
				task.delay(2, function()
					part.Parent:Destroy()
				end)
			end)
		end

		-- Aplica o dano
		vHumanoid:TakeDamage(1)
	end
end

function PlayerAttackService:MakeRagdoll(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
	end

	for _, motor in ipairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			local part0 = motor.Part0
			local part1 = motor.Part1

			local att0 = Instance.new("Attachment")
			att0.CFrame = motor.C0
			att0.Parent = part0

			local att1 = Instance.new("Attachment")
			att1.CFrame = motor.C1
			att1.Parent = part1

			local ballSocket = Instance.new("BallSocketConstraint")
			ballSocket.Attachment0 = att0
			ballSocket.Attachment1 = att1
			ballSocket.LimitsEnabled = true
			ballSocket.TwistLimitsEnabled = true
			ballSocket.UpperAngle = 90
			ballSocket.TwistLowerAngle = -45
			ballSocket.TwistUpperAngle = 45
			ballSocket.Parent = part0

			motor:Destroy()
		end
	end
end
return PlayerAttackService
