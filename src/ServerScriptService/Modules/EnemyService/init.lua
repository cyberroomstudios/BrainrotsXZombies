local EnemyService = {}
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(ServerScriptService.Modules.BaseService)
local UtilService = require(ServerScriptService.Modules.UtilService)

local ENEMY_STOP_DISTANCE = 0
function EnemyService:Init() end

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
		EnemyService:CreateOndiedListener(player, newEnemy)

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
					print("Tirando Vida ")
					local currentLife = player:GetAttribute("BASE_LIFE") or 100
					currentLife = currentLife - 10
					player:SetAttribute("BASE_LIFE", currentLife)
				end
			end

			task.wait(1)
		end
	end)
end

function EnemyService:CreateOndiedListener(player: Player, enemy: Model)
	local humanoid = enemy.Humanoid
	humanoid.Died:Connect(function()
		print("Morreu")
		EnemyService:MakeRagdoll(enemy)
		task.delay(2, function()
			humanoid.Parent:Destroy()
		end)
	end)
end

function EnemyService:ReportNewDied(player: Player)
	local enemysFolder = workspace.runtime[player.UserId].Enemys:GetChildren()
	local hasEnemy = true

	for _, value in enemysFolder:GetChildren() do
		
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
