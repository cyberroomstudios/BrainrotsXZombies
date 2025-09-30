local EnemyService = {}
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("DiedService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local ENEMY_STOP_DISTANCE = 0

function EnemyService:Init() end

function EnemyService:SpawnEnemy(player: Player, currentWave: number)
	local base = BaseService:GetBase(player)
	local enemyFolder = UtilService:WaitForDescendants(base, "baseTemplate", "enemy")
	local enemySpawns = {}

	for _, value in enemyFolder:GetChildren() do
		table.insert(enemySpawns, value)
	end

	local oldSpawn = nil
	if base then
		for i = 1, currentWave do
			task.spawn(function()
				local enemySpawn = enemySpawns[math.random(1, #enemySpawns)]

				while oldSpawn and enemySpawn == oldSpawn do
					enemySpawn = enemySpawns[math.random(1, #enemySpawns)]
					task.wait()
				end
				oldSpawn = enemySpawn

				EnemyService:Create(player, enemySpawn)
			end)
			task.wait(0.2)
		end
	end
end

function EnemyService:Create(player: Player, enemySpawn: Part)
	task.spawn(function()
		-- Criando um novo Enemy
		local newEnemy = ReplicatedStorage.Model.Enemy.Zombie:Clone()
		local newEnemyHumanoidRootPart = newEnemy:WaitForChild("HumanoidRootPart")
		newEnemy.Parent = workspace.runtime[player.UserId].Enemys
		newEnemy:SetPrimaryPartCFrame(enemySpawn.CFrame)
		newEnemyHumanoidRootPart:SetNetworkOwner(player)

		-- Cria o objetivo do enemy
		local enemyTarget = EnemyService:GetEnemyTargert(player)
		task.wait(0.5)

		-- Cria o evento de ouvir quando o enemy morre
		EnemyService:CreateOnDiedListener(player, newEnemy)

		-- Cria a thread para ficar atacando
		EnemyService:StartAttackThread(player, newEnemy, newEnemyHumanoidRootPart)

		-- Colocando o Enemy para procurar o Objetivo
		EnemyService:MoveToTarget(newEnemy, enemyTarget, newEnemyHumanoidRootPart)
	end)
end

function EnemyService:GetCollidingParts(hrp: BasePart)
	return hrp:GetTouchingParts()
end

function EnemyService:StartAttackThread(player: Player, enemy: Model, hrp: BasePart)
	task.spawn(function()
		while enemy.Parent do
			local collidingParts = EnemyService:GetCollidingParts(hrp)

			for _, part in collidingParts do
				if part:GetAttribute("IS_HEART") then
					EnemyService:HitHeart(player, part)
				end
			end
			task.wait(1)
		end
	end)
end

function EnemyService:HitHeart(player: Player, heartPart: Part)
	local currentLife = player:GetAttribute("BASE_LIFE") or 100
	currentLife = currentLife - 10

	if currentLife < 0 then
		currentLife = 0
	end
	player:SetAttribute("BASE_LIFE", currentLife)

	if currentLife == 0 then
		EnemyService:KillPlayer(player)
	end
end

function EnemyService:KillPlayer(player: Player)
	player:SetAttribute("GAME_ON", false)
	player:SetAttribute("CURRENT_WAVE", 1)
	local enemysFolder = workspace.runtime[player.UserId].Enemys

	for _, value in enemysFolder:GetChildren() do
		value:Destroy()
	end

	bridge:Fire(player, {
		[actionIdentifier] = "ShowYouDiedScreen",
	})
end

function EnemyService:CreateOnDiedListener(player: Player, enemy: Model)
	local humanoid = enemy.Humanoid
	humanoid.Died:Connect(function()
		EnemyService:MakeRagdoll(enemy)
		task.delay(2, function()
			humanoid.Parent:Destroy()
			task.wait(1)
			EnemyService:ReportNewDied(player)
		end)
	end)
end

function EnemyService:ReportNewDied(player: Player)
	local enemysFolder = workspace.runtime[player.UserId].Enemys
	local hasEnemy = false

	for _, value in enemysFolder:GetChildren() do
		hasEnemy = true
	end

	if not hasEnemy then
		local currentWave = player:GetAttribute("CURRENT_WAVE") or 1
		currentWave = currentWave + 1

		player:SetAttribute("CURRENT_WAVE", currentWave)
		EnemyService:SpawnEnemy(player, currentWave)
	end
end

function EnemyService:MakeRagdoll(character)
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

function EnemyService:MoveToTarget(enemy: Model, enemyTarget: Part, newEnemyHumanoidRootPart: Part)
	local x = enemyTarget.Position.X
	local y = newEnemyHumanoidRootPart.Position.Y
	local z = enemyTarget.Position.Z

	local targetPosition = Vector3.new(x, y, z)

	enemy.Humanoid:MoveTo(targetPosition)
	enemy.Humanoid.MoveToFinished:Wait()

	-- Se estiver longe, tenta de novo
	while (newEnemyHumanoidRootPart.Position - targetPosition).Magnitude > 1 do
		enemy.Humanoid:MoveTo(targetPosition)
		enemy.Humanoid.MoveToFinished:Wait()
	end
end

function EnemyService:GetEnemyTargert(player: Player)
	local base = BaseService:GetBase(player)
	local heart = UtilService:WaitForDescendants(base, "baseTemplate", "Heart")
	return heart.PrimaryPart
end

return EnemyService
