local PlayerAttackController = {}

-- === CONSTANTS
local DEFAULT_PROJECTILE_SPEED: number = 250 -- studs per second
local LASER_RADIUS: number = 0.25 -- studs
local DEFAULT_FIRE_RATE: number = 0.1 -- seconds
local DEFAULT_DAMAGE: number = 25 -- hit damage

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PlayerAttackService")
local weaponsBridge = BridgeNet2.ReferenceBridge("WeaponService") -- TODO use WeaponsController instead
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
-- Ensure ProjectilePlus client initializes for client-side sync/visual hooks
pcall(function(): ()
	require(ReplicatedStorage.ProjectilePlus.Client)
end)

-- === ENUMS
local Weapons = require(ReplicatedStorage.Enums.weapons)
local UnitType = require(ReplicatedStorage.Enums.unitType)

-- === LOCAL VARIABLES
local AnimationTracks: { AnimationTrack } = {}
local CurrentAnimationTrackIndex: number = 1
local IsMeleeAttacking: boolean = false
local LastRangedShotTime: number = 0
local IsRangedFiring: boolean = false
local AutoFireConnection: RBXScriptConnection? = nil

-- === GLOBAL FUNCTIONS
function PlayerAttackController:Init(): ()
	PlayerAttackController:ConfigureButtonListeners()
	PlayerAttackController:Configure()
end

function PlayerAttackController:Configure(): ()
	local player: Player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid: Humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator: Animator = humanoid:FindFirstChildOfClass("Animator")
	local rightPlayerAttackAnimation = ReplicatedStorage.animations.rightPlayerAttack
	local leftPlayerAttackAnimation = ReplicatedStorage.animations.leftPlayerAttack
	table.insert(AnimationTracks, animator:LoadAnimation(rightPlayerAttackAnimation))
	table.insert(AnimationTracks, animator:LoadAnimation(leftPlayerAttackAnimation))
end

function PlayerAttackController:FireRangedWeapon(equippedWeapon: string): boolean
	local weapon = Weapons[equippedWeapon]
	local now: number = os.clock()
	local fireRate: number = weapon.FireRate or DEFAULT_FIRE_RATE
	if (now - LastRangedShotTime) < fireRate then
		return false
	end
	LastRangedShotTime = now

	local player: Player = Players.LocalPlayer
	local character: Model = player.Character or player.CharacterAdded:Wait()
	local tool: Tool? = character:FindFirstChildOfClass("Tool")
	if not tool or not tool:FindFirstChild("Handle") then
		return false
	end

	local mouse: Mouse = player:GetMouse()
	-- Find a Muzzle attachment anywhere under the tool (common rigging)
	local origin: Vector3
	local muzzle: Attachment? = tool:FindFirstChild("Muzzle", true)
	if muzzle and muzzle:IsA("Attachment") then
		origin = muzzle.WorldPosition
	elseif tool:FindFirstChild("Handle") then
		origin = tool.Handle.Position
	else
		-- Ultimate fallback: use tool position
		warn(`[PlayerAttackController] Tool {tool.Name} has no Muzzle or Handle, using its position as origin`)
		origin = tool.Position
	end

	local target: Vector3 = mouse.Hit.Position
	bridge:InvokeServerAsync({
		[actionIdentifier] = "AttackRangedFire",
		data = {
			Origin = origin,
			Target = target,
		},
	})
	return true
end

function PlayerAttackController:ConfigureButtonListeners(): ()
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean): ()
		if gameProcessedEvent or IsMeleeAttacking or IsRangedFiring then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			-- Query equipped weapon from server:
			local equippedWeapon: string? = weaponsBridge:InvokeServerAsync({
				[actionIdentifier] = "GetEquipped",
			})

			if equippedWeapon and Weapons[equippedWeapon] and Weapons[equippedWeapon].Type == UnitType.Ranged then
				local weapon = Weapons[equippedWeapon]
				-- If weapon is automatic, set up continuous firing
				if weapon.IsAutomatic then
					IsRangedFiring = true

					-- Disconnect previous auto-fire if it exists
					if AutoFireConnection then
						AutoFireConnection:Disconnect()
					end

					-- Set up continuous firing on RenderStepped
					AutoFireConnection = RunService.RenderStepped:Connect(function(): ()
						if IsRangedFiring then
							PlayerAttackController:FireRangedWeapon(equippedWeapon)
						end
					end)
				else
					-- Fire immediately
					PlayerAttackController:FireRangedWeapon(equippedWeapon)
				end
			else
				IsMeleeAttacking = true
				local track: AnimationTrack = AnimationTracks[CurrentAnimationTrackIndex]
				if track then
					track:Play()
					track:GetMarkerReachedSignal("HIT"):Once(function(param: number): ()
						bridge:InvokeServerAsync({
							[actionIdentifier] = "AttackMelee",
							data = {},
						})
					end)
					track.Stopped:Once(function(): ()
						CurrentAnimationTrackIndex += 1
						IsMeleeAttacking = false
						if CurrentAnimationTrackIndex > #AnimationTracks then
							CurrentAnimationTrackIndex = 1
						end
					end)
				else -- Fallback if no animations are loaded:
					bridge:InvokeServerAsync({
						[actionIdentifier] = "AttackMelee",
						data = {},
					})
					IsMeleeAttacking = false
				end
			end
		end
	end)

	-- Listen for button release to stop automatic firing
	UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean): ()
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			IsRangedFiring = false
			if AutoFireConnection then
				AutoFireConnection:Disconnect()
				AutoFireConnection = nil
			end
		end
	end)
end

return PlayerAttackController
