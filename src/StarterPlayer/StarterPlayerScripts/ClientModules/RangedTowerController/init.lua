local RangedTowerController = {}

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

local ranged = require(ReplicatedStorage.Enums.ranged)

local player = Players.LocalPlayer
local PROCESS_PER_FRAME = 10
local ATTACK_COOLDOWN = 0.6
local rangedCooldowns = {}

function RangedTowerController:Init() end

function RangedTowerController:LookAt(model: Model, targetPos: Vector3)
	local primary = model.PrimaryPart
	if not primary then
		return
	end

	local pos = primary.Position

	local flatTarget = Vector3.new(targetPos.X, pos.Y, targetPos.Z)

	local lookCF = CFrame.lookAt(pos, flatTarget)

	local _, yRot, _ = lookCF:ToOrientation()
	local _, currentY, _ = primary.CFrame:ToOrientation()

	local newCF = CFrame.new(pos) * CFrame.Angles(0, yRot, 0) 
	model:SetPrimaryPartCFrame(newCF)
end

function RangedTowerController:GetOrCreateBeam(model: Model)
	local head = model:WaitForChild("Head")
	local hitRef = head:WaitForChild("hitRef")
	local primary = model.PrimaryPart

	local beam = primary:FindFirstChild("Beam")
	if not beam then
		local a0 = RangedTowerController:GetOrCreateAttachment(hitRef, "A0")

		beam = Instance.new("Beam")
		beam.Name = "Beam"
		beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		beam.Width0 = 0.2
		beam.Width1 = 0.2
		beam.Transparency = NumberSequence.new(0)

		beam.FaceCamera = true
		beam.Enabled = false
		beam.Attachment0 = a0
		beam.Parent = primary
	end

	return beam
end

function RangedTowerController:GetOrCreateAttachment(part: BasePart, name: string)
	local att = part:FindFirstChild(name)
	if not att then
		att = Instance.new("Attachment")
		att.Name = name
		att.Parent = part
	end
	return att
end

function RangedTowerController:Attack(model: Model, enemy: Model)
	local now = os.clock()
	if rangedCooldowns[model] and now - rangedCooldowns[model] < ATTACK_COOLDOWN then
		return
	end
	rangedCooldowns[model] = now

	local beam = RangedTowerController:GetOrCreateBeam(model)
	local a1 = RangedTowerController:GetOrCreateAttachment(enemy.PrimaryPart, "A1")

	beam.Attachment1 = a1
	beam.Enabled = true

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	task.delay(0.25, function()
		if beam then
			beam.Enabled = false
		end
	end)
	if humanoid and humanoid.Health > 0 then
		local result = bridge:InvokeServerAsync({
			[actionIdentifier] = "TakeDamage",
			data = {
				Model = enemy,
			},
		})
	end
end

function RangedTowerController:CreateRegion(ranged)
	local regionSize = Vector3.new(
		ranged.DetectionRange.NumberOfStudsLeft + ranged.DetectionRange.NumberOfStudsRight + 2,
		12,
		ranged.DetectionRange.NumberOfStudsForward + ranged.DetectionRange.NumberOfStudsBehind + 2
	)

	return regionSize
end

function RangedTowerController:GetPartsInRegion(meleesModek: Model, overlapParams: OverlapParams, regionSize)
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

function RangedTowerController:VerifyPartsInRegion(model, humanoidCooldowns, partsInRegion)
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
					now = os.clock()
					humanoidCooldowns[humanoid] = now

					RangedTowerController:LookAt(model.Head, ancestor.PrimaryPart.Position)
					RangedTowerController:Attack(model, ancestor)
				end
				break
			end
		end
	end
end

function RangedTowerController:StartThread()
	-- Animações de Ataque

	-- Armazena as regiões de verificação
	local regionCache = {}

	-- Params para a busca de inimigos
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local index = 1
	local allrangedModeList = workspace.runtime[player.UserId]["RANGED"]:GetChildren()
	local rangedModeList = {}

	for _, value in allrangedModeList do
		if not value:GetAttribute("IS_BRAINROT") then
			table.insert(rangedModeList, value)
		end
	end
	if next(rangedModeList) then
		local humanoidCooldowns = {}
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
					regionCache[model.Name] = RangedTowerController:CreateRegion(def)
					regionSize = regionCache[model.Name]
				end

				local partsInRegion = RangedTowerController:GetPartsInRegion(model, overlapParams, regionSize)

				RangedTowerController:VerifyPartsInRegion(model, humanoidCooldowns, partsInRegion)
			end
		end)
	end
end
return RangedTowerController
