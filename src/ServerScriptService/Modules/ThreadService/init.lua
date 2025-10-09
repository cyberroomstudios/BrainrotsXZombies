local ThreadService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local MapService = require(ServerScriptService.Modules.MapService)
local melee = require(ReplicatedStorage.Enums.melee)

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("ThreadService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net
function ThreadService:Init()
	ThreadService:InitBridgeListener()
end

function ThreadService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "TakeDamage" then
			print("Ataque")
			local model = data.data.Model
			print(model)
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			print(humanoid)
			if humanoid and humanoid.Health > 0 then
				print("Tirando Dano")
				humanoid:TakeDamage(20)
			end
		end
	end
end
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
		local attf = part:FindFirstChild(name)
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
			humanoid:TakeDamage(20)
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

function ThreadService:StartRanged(player: Player)
	task.spawn(function()
	--	ThreadService:InitThreadRanged(player)
	end)
end

return ThreadService
