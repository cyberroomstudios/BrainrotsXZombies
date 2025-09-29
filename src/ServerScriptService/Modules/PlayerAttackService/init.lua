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

		-- Aplica o dano
		vHumanoid:TakeDamage(50)
	end
end

return PlayerAttackService
