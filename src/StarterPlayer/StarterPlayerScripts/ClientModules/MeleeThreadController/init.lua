local MeleeThreadController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("ThreadService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local melee = require(ReplicatedStorage.Enums.melee)

local player = Players.LocalPlayer
local PROCESS_PER_FRAME = 10

function MeleeThreadController:Init() end

function MeleeThreadController:CreateRegion(meleeDef)
	local regionSize = Vector3.new(
		meleeDef.DetectionRange.NumberOfStudsLeft + meleeDef.DetectionRange.NumberOfStudsRight + 2,
		12,
		meleeDef.DetectionRange.NumberOfStudsForward + meleeDef.DetectionRange.NumberOfStudsBehind + 2
	)

	return regionSize
end

function MeleeThreadController:GetPartsInRegion(meleesModek: Model, overlapParams: OverlapParams, regionSize)
	local cf = meleesModek:GetBoundingBox()

	-- Cria a Part de visualização
	local visualPart = Instance.new("Part")
	visualPart.Size = regionSize
	visualPart.CFrame = CFrame.new(cf.Position)
	visualPart.Anchored = true
	visualPart.CanCollide = false
	visualPart.Transparency = 0.9
	visualPart.Color = Color3.fromRGB(255, 0, 0)

	visualPart.Name = "DetectionRegionPreview"
	--visualPart.Parent = workspace

	overlapParams.FilterDescendantsInstances = { meleesModek }
	local parts = workspace:GetPartBoundsInBox(CFrame.new(cf.Position), regionSize, overlapParams)
	return parts
end

function MeleeThreadController:PreCreateAnimations()
	local attackAnimation = {}
	local meleesModeList = workspace.runtime[player.UserId]["MELEE"]:GetChildren()

	-- Pré-carrega animações antes do loop principal
	for _, model in meleesModeList do
		local animCtrl = model:FindFirstChildOfClass("AnimationController")
		if animCtrl and model:FindFirstChild("Animations") then
			local attack = animCtrl:LoadAnimation(model.Animations.Attack)
			attack.Priority = Enum.AnimationPriority.Action
			--attack:AdjustSpeed(1.5)
			attackAnimation[model] = attack
		end
		model:SetAttribute("LOADED_ATTACK_ANIMATION", true)
	end

	return attackAnimation
end

function MeleeThreadController:VerifyPartsInRegion(model, humanoidCooldowns, partsInRegion, attackAnimation)
	for _, part in partsInRegion do
		local ancestor = part:FindFirstAncestorOfClass("Model")
		if ancestor and ancestor:GetAttribute("IS_ENEMY") then
			local humanoid = ancestor:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				-- Verifica se o humanoid está em cooldown
				local lastHit = humanoidCooldowns[humanoid]
				local now = os.clock()

				if not lastHit or now - lastHit >= 2 then
					-- Atualiza o tempo do último hit
					humanoidCooldowns[humanoid] = now

					local anim = attackAnimation[model]
					if anim and not anim.IsPlaying then
						anim:Play()
						anim:AdjustSpeed(1.5)
						local result = bridge:InvokeServerAsync({
							[actionIdentifier] = "TakeDamage",
							data = {
								Model = ancestor,
							},
						})
					end
				end
				break
			end
		end
	end
end

function MeleeThreadController:StartThread()
	-- Animações de Ataque
	local attackAnimation = MeleeThreadController:PreCreateAnimations()

	-- Armazena as regiões de verificação
	local regionCache = {}

	-- Params para a busca de inimigos
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local index = 1
	local meleesModeList = workspace.runtime[player.UserId]["MELEE"]:GetChildren()
	RunService.Heartbeat:Connect(function()
		for _ = 1, PROCESS_PER_FRAME do
			local model = meleesModeList[index]
			index += 1
			if index > #meleesModeList then
				index = 1
			end

			local def = melee[model.Name]

			-- Cria a região de verificação ou pega do cache
			local regionSize = regionCache[model.Name]
			if not regionSize then
				regionCache[model.Name] = MeleeThreadController:CreateRegion(def)
				regionSize = regionCache[model.Name]
			end

			local humanoidCooldowns = {}

			local partsInRegion = MeleeThreadController:GetPartsInRegion(model, overlapParams, regionSize)

			MeleeThreadController:VerifyPartsInRegion(model, humanoidCooldowns, partsInRegion, attackAnimation)
		end
	end)
end

return MeleeThreadController
