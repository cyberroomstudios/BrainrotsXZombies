local WeaponVisualController = {}

-- === SERVICES
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- === MODULES
local ProjectilePlusClient = require(ReplicatedStorage.ProjectilePlus.Client)

-- === ENUMS
local Weapons = require(ReplicatedStorage.Enums.weapons)

-- === GLOBAL FUNCTIONS
function WeaponVisualController:Init(): ()
	WeaponVisualController:SetupProjectileVisuals()
end

function WeaponVisualController:CreateLaserPart(): Part
	local laser = Instance.new("Part")
	laser.Name = "Laser"
	laser.Anchored = false -- must be false so WeldPart moves it
	laser.CanCollide = false
	laser.CanQuery = false
	laser.CanTouch = false
	laser.Material = Enum.Material.Neon
	laser.Color = Color3.fromRGB(82, 166, 255) -- TODO set from Weapon projectileColor
	laser.Size = 0.2 * Vector3.one -- TODO set from Weapon projectileDiameter
	laser.Shape = Enum.PartType.Ball
	laser.CastShadow = false
	laser.TopSurface = Enum.SurfaceType.Smooth
	laser.BottomSurface = Enum.SurfaceType.Smooth

	-- Attachments (positions taken from sample)
	local att1 = Instance.new("Attachment")
	att1.Name = "AttachmentOne"
	att1.Position = Vector3.new(0, 0, -0.11000061) -- TODO set from Weapon projectileDiameter
	att1.Parent = laser

	local att2 = Instance.new("Attachment")
	att2.Name = "AttachmentTwo"
	att2.Position = Vector3.new(0, 0, 0.11000061) -- TODO set from Weapon projectileDiameter
	att2.Parent = laser

	-- Trail matching sample
	local trail = Instance.new("Trail")
	trail.Name = "Trail"
	trail.Attachment0 = att1
	trail.Attachment1 = att2
	trail.Brightness = 100
	trail.Color = ColorSequence.new(Color3.fromRGB(82, 166, 255)) -- TODO set from Weapon projectileTrailColor
	trail.Enabled = true
	trail.FaceCamera = true
	trail.Lifetime = 0.3 -- TODO set from Weapon projectileTrailLifetime
	trail.LightEmission = 1
	trail.LightInfluence = 1
	trail.MaxLength = 0
	trail.MinLength = 0.1
	trail.TextureMode = Enum.TextureMode.Stretch
	trail.TextureLength = 1
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Parent = att1

	-- Beam matching sample
	-- local beam = Instance.new("Beam")
	-- beam.Name = "Beam"
	-- beam.Attachment0 = att1
	-- beam.Attachment1 = att2
	-- beam.Width0 = 0.25
	-- beam.Width1 = 0.25
	-- beam.Brightness = 100
	-- beam.Color = ColorSequence.new(Color3.fromRGB(0, 179, 255)) -- Set from Weapon projectileBeamColor
	-- beam.LightEmission = 1
	-- beam.LightInfluence = 0
	-- beam.FaceCamera = true
	-- beam.Segments = 1
	-- beam.Texture = "rbxassetid://72134380"
	-- beam.TextureLength = 5
	-- beam.TextureMode = Enum.TextureMode.Wrap
	-- beam.TextureSpeed = 20
	-- beam.Transparency = NumberSequence.new({
	-- 	NumberSequenceKeypoint.new(0, 0),
	-- 	NumberSequenceKeypoint.new(0.027, 1),
	-- 	NumberSequenceKeypoint.new(1, 0),
	-- })
	-- beam.Enabled = true
	-- beam.Parent = laser

	return laser
end

function WeaponVisualController:SetupProjectileVisuals(): ()
	-- Listen for new projectiles from weapons
	ProjectilePlusClient.ProjectileAdded:Connect(function(projectile): ()
		-- Treat any ranged weapon projectile as laser-like (LaserGun style)
		local weaponName = projectile.Key:match("([^_]+)_") or projectile.Key
		local weapon = Weapons[weaponName]
		local unitType = require(ReplicatedStorage.Enums.unitType)
		if not weapon or weapon.Type ~= unitType.Ranged then
			return
		end

		local laser = WeaponVisualController:CreateLaserPart()
		laser.Parent = workspace
		projectile:WeldPart(laser)

		-- Create explosion effect on hit
		local function createImpactEffect(_: Model, position: Vector3): ()
			-- Expanding neon ring:
			local ring = Instance.new("Part")
			ring.Name = "ImpactRing"
			ring.Anchored = true
			ring.CanCollide = false
			ring.CanQuery = false
			ring.Size = 0.2 * Vector3.one
			ring.Shape = Enum.PartType.Cylinder
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(140, 240, 255) -- TODO should be a Script constant
			ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
			ring.Transparency = 0.2 -- TODO should be a Script constant
			ring.Parent = workspace
			local tweenOut = TweenService:Create(
				ring,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- TODO should be a Script constant
				{ Size = Vector3.new(0.2, 0.2, 4), Transparency = 1 } -- TODO should be a Script constant
			)
			tweenOut:Play()
			tweenOut.Completed:Once(function(): ()
				if ring.Parent then
					ring:Destroy()
				end
			end)

			-- Sparks burst:
			local impact = Instance.new("Part")
			impact.Name = "Impact"
			impact.Anchored = true
			impact.CanCollide = false
			impact.CanQuery = false
			impact.Transparency = 1
			impact.CFrame = CFrame.new(position)
			impact.Parent = workspace
			local attachment = Instance.new("Attachment")
			attachment.Parent = impact
			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds" -- TODO should be a Script constant
			particles.Rate = 0
			particles.Lifetime = NumberRange.new(0.15, 0.25) -- TODO should be a Script constant
			particles.Speed = NumberRange.new(8, 14) -- TODO should be a Script constant
			particles.SpreadAngle = Vector2.new(180, 180) -- TODO should be a Script constant
			particles.Color = ColorSequence.new(Color3.fromRGB(180, 230, 255)) -- TODO should be a Script constant
			particles.Size = NumberSequence.new(0.2, 0) -- TODO should be a Script constant
			particles.Parent = attachment
			particles:Emit(12) -- TODO should be a Script constant
			task.delay(0.4, function(): ()
				impact:Destroy()
			end)
		end

		projectile.OnHitSomeone:Connect(createImpactEffect)
		projectile.OnHitMap:Connect(createImpactEffect)

		-- Clean up when projectile is destroyed:
		projectile.Destroying:Connect(function(): ()
			projectile:ClearWelds()
			local trail = laser:FindFirstChild("Trail", true)
			if trail then
				trail.Enabled = false
			end
			Debris:AddItem(laser, 0.4)
		end)
	end)
end

return WeaponVisualController
