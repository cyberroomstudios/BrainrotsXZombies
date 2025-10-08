local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RangedController = {}

local ranged = require(ReplicatedStorage.Enums.ranged)

local player = Players.LocalPlayer
local PROCESS_PER_FRAME = 10
function RangedController:Init() end

function RangedController:PreCreateAnimations()
	local attackAnimation = {}
	local rangedModeList = workspace.runtime[player.UserId]["RANGED"]:GetChildren()

	-- Pré-carrega animações antes do loop principal
	for _, model in rangedModeList do
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
function RangedController:StartThread()
	-- Animações de Ataque
	local attackAnimation = RangedController:PreCreateAnimations()

	-- Armazena as regiões de verificação
	local regionCache = {}

	-- Params para a busca de inimigos
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local index = 1
	local rangedModeList = workspace.runtime[player.UserId]["RANGED"]:GetChildren()
	RunService.Heartbeat:Connect(function()
		for _ = 1, PROCESS_PER_FRAME do
			local model = rangedModeList[index]
			index += 1
			if index > #rangedModeList then
				index = 1
			end

			local def = ranged[model.Name]

			-- Cria a região de verificação ou pega do cache
			local regionSize = regionCache[model.Name]
			if not regionSize then
				--regionCache[model.Name] = MeleeThreadController:CreateRegion(def)
				regionSize = regionCache[model.Name]
			end

			local humanoidCooldowns = {}

			--local partsInRegion = MeleeThreadController:GetPartsInRegion(model, overlapParams, regionSize)

			--MeleeThreadController:VerifyPartsInRegion(model, humanoidCooldowns, partsInRegion, attackAnimation)
		end
	end)
end
return RangedController
