local EnemyService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)
local MapService = require(ServerScriptService.Modules.MapService)

local Utility = ReplicatedStorage:WaitForChild("Utility")
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("DiedService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")

local ENEMY_STOP_DISTANCE = 0
local animationAttackTrack = {}
local animationWalkTrack = {}

function EnemyService:Init()
	task.spawn(function()
		EnemyService:Warmup()
		local preloadStart = os.clock()

		local zombie = ReplicatedStorage:WaitForChild("Model"):WaitForChild("Enemy"):WaitForChild("Zombie")
		local animations = ReplicatedStorage:WaitForChild("animations"):WaitForChild("zombie")

		-- Pré-carrega o modelo e animações
		ContentProvider:PreloadAsync({
			zombie,
			animations.attack,
			animations.walk,
		})

		print(string.format("[EnemyService] Assets pré-carregados em %.3fs", os.clock() - preloadStart))
	end)
end

function EnemyService:Warmup()
	task.spawn(function()
		local dummy = ReplicatedStorage.Model.Enemy.Zombie:Clone()
		dummy.Parent = workspace.TemporaryCache
		dummy:PivotTo(CFrame.new(0, -100, 0)) -- fora da tela
		local hum = dummy:WaitForChild("Humanoid")
		local animator = hum:WaitForChild("Animator")
		animator:LoadAnimation(ReplicatedStorage.animations.zombie.walk):Play()
		task.wait(2)
		dummy:Destroy()
	end)
end

function EnemyService:SpawnEnemy(player: Player, currentWave: number)
	local base = BaseService:GetBase(player)
	if not base then
		return
	end

	local enemyFolder = UtilService:WaitForDescendants(base, "baseTemplate", "enemy")
	local enemySpawns = enemyFolder:GetChildren()
	if #enemySpawns == 0 then
		return
	end

	local oldSpawn

	for i = 1, currentWave do
		task.spawn(function()
			local enemySpawn = enemySpawns[math.random(1, #enemySpawns)]
			while oldSpawn and enemySpawn == oldSpawn do
				print("Procurando")
				enemySpawn = enemySpawns[math.random(1, #enemySpawns)]
				task.wait(1)
			end
			oldSpawn = enemySpawn
			EnemyService:Create(player, enemySpawn)
		end)
	end
end

function EnemyService:Create(player: Player, enemySpawn: Part)
	task.spawn(function()
		local createStart = os.clock()
		local newEnemy = ReplicatedStorage.Model.Enemy.Zombie:Clone()
		local hrp = newEnemy:WaitForChild("HumanoidRootPart")
		local humanoid = newEnemy:WaitForChild("Humanoid")

		newEnemy:SetAttribute("IS_ENEMY", true)
		newEnemy.Parent = workspace.runtime[player.UserId].Enemys
		newEnemy:SetPrimaryPartCFrame(enemySpawn.CFrame)

		-- Define o Network Owner (somente se o player existir)
		pcall(function()
			hrp:SetNetworkOwner(player)
		end)

		EnemyService:CreateWalkAnimation(newEnemy)
		EnemyService:CreateOnDiedListener(player, newEnemy)

		task.defer(function()
			local target = EnemyService:GetEnemyTarget(player)
			if target then
				EnemyService:MoveToTarget(newEnemy, target, hrp)
				EnemyService:StartAttackThread(player, newEnemy)
			end
		end)

		print(string.format("[EnemyService] Enemy criado em %.3fs", os.clock() - createStart))
	end)
end

function EnemyService:CreateWalkAnimation(enemy: Model)
	local humanoid: Humanoid = enemy:FindFirstChildOfClass("Humanoid")
	local animator: Animator = humanoid:FindFirstChildOfClass("Animator")

	local attack = animator:LoadAnimation(ReplicatedStorage.animations.zombie.attack)
	local walk = animator:LoadAnimation(ReplicatedStorage.animations.zombie.walk)

	animationAttackTrack[enemy] = attack
	animationWalkTrack[enemy] = walk
	walk:Play()
end

function EnemyService:StartAttackThread(player: Player, enemy: Model)
	task.spawn(function()
		local leftArm = enemy:WaitForChild("Left Arm")
		local attack = animationAttackTrack[enemy]

		local base = BaseService:GetBase(player)
		local heart = base.baseTemplate.Heart.HitBox
		local blocks = workspace.runtime[player.UserId].BLOCK:GetDescendants()
		local ranged = workspace.runtime[player.UserId].RANGED:GetDescendants()

		local attackable = {}
		for _, obj in ipairs(blocks) do
			if obj:GetAttribute("IS_UNIT") then
				table.insert(attackable, obj)
			end
		end
		for _, obj in ipairs(ranged) do
			if obj:GetAttribute("IS_UNIT") then
				table.insert(attackable, obj)
			end
		end
		table.insert(attackable, heart)

		while enemy.Parent do
			for _, part in attackable do
				if not part.Parent then
					continue
				end
				local dist = (leftArm.Position - part.Position).Magnitude
				if dist <= 4 then
					if attack and not attack.IsPlaying then
						attack:Play()
					end

					if part:GetAttribute("IS_UNIT") then
						EnemyService:HitUnit(player, part)
					elseif part:GetAttribute("IS_HEART") then
						EnemyService:HitHeart(player, part)
					end
				end
			end
			task.wait(1)
		end
	end)
end

function EnemyService:HitHeart(player: Player, heartPart: Part)
	local life = player:GetAttribute("BASE_LIFE") or 100
	life = math.max(life - 10, 0)
	player:SetAttribute("BASE_LIFE", life)
	if life == 0 then
		EnemyService:KillPlayer(player)
	end
end

function EnemyService:HitUnit(player: Player, part: Part)
	local model = part.Parent
	if not model then
		return
	end

	local life = (model:GetAttribute("LIFE") or 100) - 10
	model:SetAttribute("LIFE", life)

	if life <= 0 then
		model:Destroy()
	else
		local factor
		if life <= 30 then
			factor = 0.75
		elseif life <= 60 then
			factor = 0.5
		elseif life <= 90 then
			factor = 0.25
		end
		if factor then
			for _, child in ipairs(model:GetDescendants()) do
				if child:IsA("BasePart") then
					child.Color = child.Color:Lerp(Color3.new(0, 0, 0), factor)
				end
			end
		end
	end
end

function EnemyService:CreateOnDiedListener(player: Player, enemy: Model)
	local humanoid = enemy:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		task.spawn(function()
			EnemyService:MakeRagdoll(enemy)
			task.wait(2)

			if enemy and enemy.Parent then
				enemy:Destroy()
			end

			animationWalkTrack[enemy] = nil
			animationAttackTrack[enemy] = nil

			task.wait(0.5)
			EnemyService:ReportNewDied(player)
		end)
	end)
end

function EnemyService:ReportNewDied(player: Player)
	local enemiesFolder = workspace.runtime[player.UserId].Enemys
	if #enemiesFolder:GetChildren() == 0 then
		local wave = (player:GetAttribute("CURRENT_WAVE") or 1) + 1
		player:SetAttribute("CURRENT_WAVE", wave)
		EnemyService:SpawnEnemy(player, wave)
	end
end

function EnemyService:KillPlayer(player: Player)
	player:SetAttribute("GAME_ON", false)
	player:SetAttribute("CURRENT_WAVE", 1)

	for _, enemy in ipairs(workspace.runtime[player.UserId].Enemys:GetChildren()) do
		enemy:Destroy()
	end

	bridge:Fire(player, { [actionIdentifier] = "ShowYouDiedScreen" })
	MapService:RestartBaseMap(player)
end

function EnemyService:MakeRagdoll(char: Model)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
	end

	for _, motor in ipairs(char:GetDescendants()) do
		if motor:IsA("Motor6D") then
			local att0 = Instance.new("Attachment", motor.Part0)
			att0.CFrame = motor.C0

			local att1 = Instance.new("Attachment", motor.Part1)
			att1.CFrame = motor.C1

			local socket = Instance.new("BallSocketConstraint", motor.Part0)
			socket.Attachment0 = att0
			socket.Attachment1 = att1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.UpperAngle = 90
			socket.TwistLowerAngle = -45
			socket.TwistUpperAngle = 45

			motor:Destroy()
		end
	end
end

function EnemyService:MoveToTarget(enemy: Model, target: Part, hrp: Part)
	task.spawn(function()
		local humanoid = enemy:WaitForChild("Humanoid")
		while enemy.Parent and (hrp.Position - target.Position).Magnitude > 2 do
			humanoid:MoveTo(Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z))
			task.wait(0.2)
		end

		local walk = animationWalkTrack[enemy]
		if walk then
			walk:Stop()
		end
	end)
end

function EnemyService:GetEnemyTarget(player: Player)
	local base = BaseService:GetBase(player)
	local heart = UtilService:WaitForDescendants(base, "baseTemplate", "Heart")
	return heart.PrimaryPart
end

return EnemyService
