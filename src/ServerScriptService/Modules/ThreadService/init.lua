local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local MapService = require(ServerScriptService.Modules.MapService)
local melee = require(ReplicatedStorage.Enums.melee)

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

function ThreadService:InitThreadRanged2(player: Player)
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
			local items = workspace.runtime[player.UserId]["RANGED"]:GetChildren()

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

function ThreadService:InitThreadRanged(player: Player)
	local runtimeFolder = workspace.runtime[player.UserId]
	local rangedFolder = runtimeFolder and runtimeFolder:FindFirstChild("RANGED")
	if not rangedFolder then
		return
	end

	local rangedModelEnemy = {}
	local towerCooldowns = {}
	local lastScan = {}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local DETECTION_RANGE = Vector3.new(60, 3, 60)
	local ATTACK_COOLDOWN = 0.6 -- tempo entre ataques de uma torre
	local SCAN_COOLDOWN = 1.2 -- tempo entre buscas de inimigo
	local PROCESS_PER_FRAME = 10 -- quantas torres atualizar por frame

	-- Pool de attachments e beams
	local function getOrCreateAttachment(part: BasePart, name: string)
		local att = part:FindFirstChild(name)
		if not att then
			att = Instance.new("Attachment")
			att.Name = name
			att.Parent = part
		end
		return att
	end

	local function getOrCreateBeam(model: Model)
		local primary = model.PrimaryPart
		if not primary then
			return nil
		end

		local beam = primary:FindFirstChild("Beam")
		if not beam then
			local a0 = getOrCreateAttachment(primary, "A0")

			beam = Instance.new("Beam")
			beam.Name = "Beam"
			beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 76))
			beam.Width0 = 0.2
			beam.Width1 = 0.2
			beam.FaceCamera = true
			beam.Enabled = false
			beam.Attachment0 = a0
			beam.Parent = primary
		end

		return beam
	end

	-- Busca inimigo próximo (só a cada SCAN_COOLDOWN)
	local function getEnemyInArea(model: Model)
		local now = os.clock()
		if lastScan[model] and now - lastScan[model] < SCAN_COOLDOWN then
			return rangedModelEnemy[model]
		end
		lastScan[model] = now

		params.FilterDescendantsInstances = { model }
		local cf = model:GetPivot()
		local parts = workspace:GetPartBoundsInBox(cf, DETECTION_RANGE, params)

		for _, part in ipairs(parts) do
			local enemy = part:FindFirstAncestorOfClass("Model")
			if enemy and enemy:GetAttribute("IS_ENEMY") then
				local humanoid = enemy:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					return enemy
				end
			end
		end
	end

	-- Faz a torre olhar pro inimigo
	local function lookAt(model: Model, targetPos: Vector3)
		local primary = model.PrimaryPart
		if not primary then
			return
		end

		local cf = CFrame.lookAt(primary.Position, targetPos) * CFrame.Angles(0, math.rad(180), 0)
		model:PivotTo(cf)
	end

	-- Ataca inimigo
	local function attack(model: Model, enemy: Model)
		local now = os.clock()
		if towerCooldowns[model] and now - towerCooldowns[model] < ATTACK_COOLDOWN then
			return
		end
		towerCooldowns[model] = now

		local beam = getOrCreateBeam(model)
		local a1 = getOrCreateAttachment(enemy.PrimaryPart, "A1")

		beam.Attachment1 = a1
		beam.Enabled = true

		-- aplica dano (server side seguro)
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(20/10)
		end

		task.delay(0.25, function()
			if beam then
				beam.Enabled = false
			end
		end)
	end

	-- Processa 1 torre por chamada (para distribuir carga)
	local towers = rangedFolder:GetChildren()
	local index = 1

	game:GetService("RunService").Heartbeat:Connect(function()
		if not player:GetAttribute("GAME_ON") then
			return
		end
		if #towers == 0 then
			towers = rangedFolder:GetChildren()
			return
		end

		for _ = 1, PROCESS_PER_FRAME do
			local model = towers[index]
			index += 1
			if index > #towers then
				index = 1
			end

			if not (model and model:IsA("Model") and model.PrimaryPart) then
				continue
			end

			local enemy = rangedModelEnemy[model]

			-- inimigo válido?
			if enemy and enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
				local headRanged = model:FindFirstChild("Head")
				lookAt(headRanged, enemy.PrimaryPart.Position)
				attack(headRanged, enemy)
			else
				-- procurar novo
				rangedModelEnemy[model] = getEnemyInArea(model)
			end
		end
	end)
end
function ThreadService:InitThreadMelee(player: Player)
	local attackAnimations = {}

	function MapService:CreateOrPlayAttackAnimation(melee: Model)
		if not melee:GetAttribute("ATTACK_ANIMATION_LOADED") then
			melee:SetAttribute("ATTACK_ANIMATION_LOADED", true)
			local AnimationController: AnimationController = melee:FindFirstChild("AnimationController")
			local attackAnimation = AnimationController:LoadAnimation(melee.Animations.Attack)
			attackAnimation.Priority = Enum.AnimationPriority.Action

			attackAnimations[melee] = attackAnimation
			print("Carregou Animação")
		end
		attackAnimations[melee]:Play()
	end

	local function getEnemyInArea(rangedModel: Model)
		local rangedDef = melee[rangedModel.Name]

		-- Pega o centro do modelo
		local cf, _ = rangedModel:GetBoundingBox()

		-- Calcula o tamanho da região baseado no DetectionRange
		local xSize = rangedDef.DetectionRange.NumberOfStudsLeft + rangedDef.DetectionRange.NumberOfStudsRight
		local zSize = rangedDef.DetectionRange.NumberOfStudsForward + rangedDef.DetectionRange.NumberOfStudsBehind
		local yHeight = 6 -- altura da área (ajuste conforme quiser)

		local regionSize = Vector3.new(xSize, yHeight, zSize)
		local regionCFrame = CFrame.new(cf.Position)

		-- Configura os parâmetros para ignorar o próprio rangedModel
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { rangedModel }

		-- Obtém todas as partes na área
		local partsInArea = workspace:GetPartBoundsInBox(regionCFrame, regionSize, params)

		for _, part in ipairs(partsInArea) do
			print(part)
			local character = part:FindFirstAncestorOfClass("Model")
			if character and character:GetAttribute("IS_ENEMY") then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					MapService:CreateOrPlayAttackAnimation(rangedModel)
					humanoid:TakeDamage(20)
					return character -- retorna o primeiro inimigo válido encontrado
				end
			end
		end

		return nil -- nenhum inimigo encontrado
	end

	task.spawn(function()
		while player:GetAttribute("GAME_ON") do
			local items = workspace.runtime[player.UserId]["MELEE"]:GetChildren()
			print("Ataque!")

			for _, item in items do
				getEnemyInArea(item)
			end
			task.wait(1)
		end
	end)
end

function ThreadService:StartRanged(player: Player)
	ThreadService:InitThreadRanged(player)
	ThreadService:InitThreadMelee(player)
end

return ThreadService
