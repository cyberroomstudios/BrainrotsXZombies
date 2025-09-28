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
		newEnemy.Parent = workspace.runtime[player.UserId]
		newEnemy:SetPrimaryPartCFrame(enemySpawn.CFrame)
		newEnemyHumanoidRootPart:SetNetworkOwner(player)
		-- Procurando o Objetivo
		local enemyTarget = EnemyService:GetEnemyTargert(player)
		task.wait(0.5)

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

function EnemyService:MoveToTarget(enemy: Model, enemyTarget: Part, newEnemyHumanoidRootPart: Part)
	print(enemyTarget.Position)

	local targetPosition =
		Vector3.new(enemyTarget.Position.X, newEnemyHumanoidRootPart.Position.Y, enemyTarget.Position.Z)

	enemy.Humanoid:MoveTo(targetPosition)
	enemy.Humanoid.MoveToFinished:Wait()

	-- Se estiver longe, tenta de novo
	while (newEnemyHumanoidRootPart.Position - targetPosition).Magnitude > 1 do
		enemy.Humanoid:MoveTo(targetPosition)
		enemy.Humanoid.MoveToFinished:Wait()
	end

	print("Chegou")
end

function EnemyService:GetEnemyTargert(player: Player)
	local base = BaseService:GetBase(player)
	local heart = UtilService:WaitForDescendants(base, "baseTemplate", "Heart")
	return heart.PrimaryPart
end

return EnemyService
