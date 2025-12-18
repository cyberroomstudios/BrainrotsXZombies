local PlayerAttackService = {}

-- === CONSTANTS
local DEFAULT_PROJECTILE_SPEED: number = 250 -- studs per second
local LASER_RADIUS: number = 0.25 -- studs
local DEFAULT_FIRE_RATE: number = 0.1 -- seconds
local DEFAULT_DAMAGE: number = 25 -- hit damage

-- === SERVICES
local HTTPService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PlayerAttackService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local ProjectilePlus = require(ReplicatedStorage.ProjectilePlus)
local Weapons = require(ReplicatedStorage.Enums.weapons)
local UnitType = require(ReplicatedStorage.Enums.unitType)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

-- === LOCAL VARIABLES
local LastRangedShotTime: { [number]: number } = {}

-- === GLOBAL FUNCTIONS
function PlayerAttackService:Init(): ()
	PlayerAttackService:InitBridgeListener()
end

function PlayerAttackService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: any): ()
		if data[actionIdentifier] == "AttackMelee" then
			PlayerAttackService:OnPlayerAttackMelee(player)
		elseif data[actionIdentifier] == "AttackRangedFire" then
			local fireData = data.data
			if not fireData then
				print("[PlayerAttackService] No fire data")
				return
			end

			local origin: Vector3 = fireData.Origin
			local target: Vector3 = fireData.Target
			PlayerAttackService:OnPlayerAttackRangedFire(player, origin, target)
		end
	end
end

function PlayerAttackService:OnPlayerAttackRangedFire(player: Player, origin: Vector3, target: Vector3): ()
	if typeof(origin) ~= "Vector3" or typeof(target) ~= "Vector3" then
		print(`[PlayerAttackService] Invalid types: origin={typeof(origin)}, target={typeof(target)}`)
		return
	end

	local equipped: string? = PlayerDataHandler:Get(player, "equippedWeapon")
	if not equipped then
		print("[PlayerAttackService] No equipped weapon")
		return
	end

	local def = Weapons[equipped]
	if not def or def.Type ~= UnitType.Ranged then
		print(`[PlayerAttackService] Equipped weapon is not ranged: {equipped}`)
		return
	end

	local character = player.Character
	if not character then
		print("[PlayerAttackService] No character found")
		return
	end

	local dir = (target - origin)
	if dir.Magnitude < 1e-3 then
		print("[PlayerAttackService] Direction magnitude too small")
		return
	end
	dir = dir.Unit

	-- Fire rate gate
	local now: number = os.clock()
	local last = LastRangedShotTime[player.UserId]
	if last and (now - last) < (def.FireRate or DEFAULT_FIRE_RATE) then
		return
	end
	LastRangedShotTime[player.UserId] = now

	local speed = DEFAULT_PROJECTILE_SPEED
	local range = def.Range or 100
	local lifetime = math.clamp(range / speed, 0.05, 8)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = { character }
	-- Also ignore the equipped tool/weapon to prevent self-collision
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		table.insert(filterList, tool)
	end
	rayParams.FilterDescendantsInstances = filterList

	local projectile = ProjectilePlus.CreateProjectile(
		character,
		(equipped .. "_" .. tostring(now)),
		LASER_RADIUS,
		dir,
		origin,
		lifetime,
		speed,
		rayParams
	)

	-- Configure laser-like behavior
	projectile.DestroyOnHit = true
	projectile.DestroyOnMapHit = true
	projectile.CheckForPeople = true
	projectile.CheckForMap = true
	projectile.UseRaycastingForPeople = true
	projectile.UseRaycastingForMap = true
	projectile.GravityEnabled = false

	-- Damage handling
	projectile.OnHitSomeone = function(hitModel: Model): ()
		local humanoid = hitModel and hitModel:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local damage = def.Damage or DEFAULT_DAMAGE
			print(
				`[PlayerAttackService] {equipped} hit {hitModel.Name}, dealing {damage} damage (Health: {humanoid.Health} → {humanoid.Health - damage})`
			)
			humanoid:TakeDamage(damage)
		else
			warn(`[PlayerAttackService] Hit {hitModel.Name} but no valid Humanoid found or already dead`)
		end
	end

	projectile.OnHitMap = function(_hitPart: BasePart)
		-- TODO add impact VFX here using VfxService if available
	end
end

function PlayerAttackService:OnPlayerAttackMelee(player: Player): ()
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 4, params)
	for _, part in parts do
		local hitModel = part.Parent
		if not hitModel then
			continue
		end

		local humanoid = hitModel:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local damage = Weapons.Fist.Damage or DEFAULT_DAMAGE
			print(
				`[PlayerAttackService] Melee attack hit {hitModel.Name}, dealing {damage} damage (Health: {humanoid.Health} → {humanoid.Health - damage})`
			)
			humanoid:TakeDamage(damage)
		else
			warn(`[PlayerAttackService] Melee attack hit {hitModel.Name} but no valid Humanoid found or already dead`)
		end
	end
end

return PlayerAttackService
