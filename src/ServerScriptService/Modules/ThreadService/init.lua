local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

local ThreadService = {}

function ThreadService:Init() end

function ThreadService:ShootLaser(fromPart, targetPosition, duration)
	local laser = Instance.new("Part")
	laser.Anchored = true
	laser.CanCollide = false
	laser.Material = Enum.Material.Neon
	laser.BrickColor = BrickColor.new("Bright red")

	-- Direção e distância
	local direction = targetPosition - fromPart.Position
	local distance = direction.Magnitude
	local midPoint = fromPart.Position + direction / 2

	-- Tamanho do laser
	laser.Size = Vector3.new(0.2, 0.2, distance)

	-- CFrame alinhado do início ao fim
	laser.CFrame = CFrame.lookAt(midPoint, targetPosition)

	laser.Parent = workspace

	return laser
end

function ThreadService:StartRanged(player: Player)
	local rangedModelEnemy = {}

	local function getEnemyInArea(rangedModel: Model)
		local cf, size = rangedModel:GetBoundingBox()

		local xOffset = 30
		local zOffset = 30
		local yHeight = 3
		local regionSize = Vector3.new(xOffset * 2, yHeight, zOffset * 2)
		local regionCFrame = CFrame.new(cf.Position)

		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { rangedModel }

		local partsInArea = workspace:GetPartBoundsInBox(regionCFrame, regionSize, params)

		for _, part in ipairs(partsInArea) do
			local character = part:FindFirstAncestorOfClass("Model")
			if character and character:GetAttribute("IS_ENEMY") then
				local humanoid = character:FindFirstChild("Humanoid")
				return character
			end
		end
	end

	local function attack(headRanged: Model, enemy: Model)
		-- Criar um attachment no Head
		local attachmentHead = headRanged.PrimaryPart:FindFirstChild("Attachment")
		if not attachmentHead then
			attachmentHead = Instance.new("Attachment")
			attachmentHead.Name = "Attachment"
			attachmentHead.Parent = headRanged.PrimaryPart
		end

		-- Criar um attachment no inimigo
		local attachmentEnemy = enemy.PrimaryPart:FindFirstChild("Attachment")
		if not attachmentEnemy then
			attachmentEnemy = Instance.new("Attachment")
			attachmentEnemy.Name = "Attachment"
			attachmentEnemy.Parent = enemy.PrimaryPart
		end

		-- Criar ou reaproveitar o Beam
		local beam = headRanged.PrimaryPart:FindFirstChild("Beam")
		if not beam then
			beam = Instance.new("Beam")
			beam.Name = "Beam"
			beam.Parent = headRanged.PrimaryPart
			beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 76)) -- cor do raio
			beam.Width0 = 0.2
			beam.Width1 = 0.2
			beam.FaceCamera = true
		end

		beam.Attachment0 = attachmentHead
		beam.Attachment1 = attachmentEnemy
		local vHumanoid = enemy:FindFirstChildOfClass("Humanoid")
		vHumanoid:TakeDamage(20)

		-- Duração do raio
		task.delay(0.3, function()
			if beam then
				beam:Destroy()
			end
		end)
	end

	local function lookEnemy(headRanged, targetPos, currentPos)
		local direction = (targetPos - currentPos).Unit

		local cf = CFrame.new(currentPos, currentPos + direction)

		cf = cf * CFrame.Angles(0, math.rad(180), 0)

		headRanged:SetPrimaryPartCFrame(cf)
	end

	task.spawn(function()
		while player:GetAttribute("GAME_ON") do
			local items = workspace.runtime[player.UserId]["ranged"]:GetChildren()

			for _, model in ipairs(items) do
				if model:IsA("Model") then
					local headRanged = model:FindFirstChild("Head")
					local cf, size = model:GetBoundingBox()

					if rangedModelEnemy[model] then
						local enemy = rangedModelEnemy[model]

						if enemy.Parent then
							local targetPos = enemy.PrimaryPart.Position
							local currentPos = headRanged.PrimaryPart.Position

							-- Direção para o inimigo
							lookEnemy(headRanged, targetPos, currentPos)

							-- Ataca!
							attack(headRanged, enemy)
							continue
						end
					end

					rangedModelEnemy[model] = nil
					local enemy = getEnemyInArea(model)
					if enemy then
						rangedModelEnemy[model] = enemy
					end
				end
			end
			task.wait(1)
		end
	end)
end

return ThreadService
