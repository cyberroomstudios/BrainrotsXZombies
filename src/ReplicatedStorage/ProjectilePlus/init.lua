local _ProjectilePlus = {}
local ProjectilePlus = setmetatable({}, {
	__index = _ProjectilePlus,
	__newindex = function(_, key, value)
		_ProjectilePlus[key] = value
		if key == "GlobalTimeScale" then
			Broadcast("TimeScaleChanged", {
				GlobalTimeScale = value,
			})
		end
	end,
})

local HTTPService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Signal = require(script:WaitForChild("Signal"))
local Types = require(script:WaitForChild("Types"))
local Zones = require(script:WaitForChild("Zones"))
local Settings = require(script:WaitForChild("Settings"))

local Projectiles: { Types.Projectile } = {}
local Catchers: { [Types.Catcher]: true } = {}

local RemoteEvent = script:WaitForChild("Fire")

function Broadcast(eventName: string, data: table)
	RemoteEvent:FireAllClients(eventName, data)
end

local ProjectileAddedSignal = Signal.new()
local ProjectileDestroyedSignal = Signal.new()

ProjectilePlus.ProjectileAdded = ProjectileAddedSignal
ProjectilePlus.ProjectileDestroyed = ProjectileDestroyedSignal

ProjectilePlus.GlobalGravity = 1
ProjectilePlus.GlobalTimeScale = 1

--Used to activate projectile system. Automatically triggered when module is required. This behavior can be changed in the module settings.
function ProjectilePlus:Initialize()
	print("ProjectilePlus Server Initialized")
	local function UpdateProjectiles()
		for _, Projectile in Projectiles do
			local currentTime = workspace:GetServerTimeNow()
			local DeltaT = (currentTime - Projectile.LastTime)
			local LT = currentTime - Projectile.StartTime
			local S = Projectile.Speed
			local TS = Projectile.TimeScale or 1
			local ScaledDeltaT = DeltaT * TS * ProjectilePlus.GlobalTimeScale

			if Projectile.GravityEnabled then
				local gravityForce = Projectile.GravityForce * ProjectilePlus.GlobalGravity
				Projectile.Velocity += Vector3.new(0, -gravityForce * ScaledDeltaT, 0)
			end

			local targetPos
			if Projectile.HomingTarget and Projectile.HomingTarget:IsDescendantOf(workspace) then
				targetPos = Projectile.HomingTarget.Position
			elseif Projectile.HomingTargetPosition then
				targetPos = Projectile.HomingTargetPosition
			end

			if targetPos then
				local directionToTarget = (targetPos - Projectile.Position).Unit
				local currentDir = Projectile.Velocity.Unit
				local blendAlpha = math.clamp((Projectile.HomingStrength or 1) * ScaledDeltaT, 0, 1)
				local newDirection = currentDir:Lerp(directionToTarget, blendAlpha)
				local speed = Projectile.Velocity.Magnitude
				Projectile.Velocity = newDirection.Unit * speed
			end

			local displacement = Projectile.Velocity * S * ScaledDeltaT
			local CalculatedCFrame =
				CFrame.lookAt(Projectile.Position + displacement, Projectile.Position + Projectile.Velocity)
			local Magnitude = math.clamp(displacement.Magnitude, 0, 1023)

			if Projectile.CheckForMap and Projectile.UseRaycastingForMap then
				local MapCast = workspace:Raycast(
					Projectile.Position,
					(CFrame.lookAt(Projectile.Position, CalculatedCFrame.Position) * CFrame.new(0, 0, Magnitude)).LookVector
						* math.clamp((Magnitude * 2), 0, 1023.999),
					Projectile.raycastParams
				)
				if
					MapCast
					and not (
						MapCast.Instance.Parent:FindFirstChild("Humanoid") and MapCast.Instance.Parent:IsA("Model")
					)
				then
					Projectile:FireHitMap(MapCast.Instance, MapCast.Position)
					if Projectile.DestroyOnMapHit then
						Projectile:Destroy()
					end
				end
			end

			local Cast
			if Projectile.CheckForPeople then
				if Projectile.UseRaycastingForPeople then
					Cast = workspace:Raycast(
						Projectile.Position,
						(CFrame.lookAt(Projectile.Position, CalculatedCFrame.Position) * CFrame.new(0, 0, Magnitude)).LookVector
							* math.clamp((Magnitude * 2), 0, 1023.999),
						Projectile.raycastParams
					)
				else
					local Direction = (CFrame.lookAt(Projectile.Position, CalculatedCFrame.Position) * CFrame.new(
						0,
						0,
						Magnitude
					)).LookVector * math.clamp((Magnitude * 2), 0, 1023.999)
					if Direction.X == Direction.X then
						Cast = workspace:Spherecast(
							Projectile.Position,
							math.clamp(Projectile.Radius / 2, 0, 255.999),
							(
								CFrame.lookAt(Projectile.Position, CalculatedCFrame.Position)
								* CFrame.new(0, 0, Magnitude)
							).LookVector * math.clamp((Magnitude * 2), 0, 1023.999),
							Projectile.raycastParams
						)
					end
				end
			end

			if Cast and (not Cast.Instance:IsDescendantOf(Projectile.Owner) or not Projectile.Owner) then
				if Projectile.ReflectEnabled then
					local incoming = Projectile.Velocity.Unit
					local normal = Cast.Normal
					local reflected = incoming - 2 * incoming:Dot(normal) * normal
					Projectile.Velocity = reflected.Unit * Projectile.Velocity.Magnitude
					Projectile.Position = Cast.Position + reflected.Unit * 0.05
					Projectile.LastTime = currentTime
					continue
				end

				if
					Cast.Instance.Parent:FindFirstChild("Humanoid")
					and Cast.Instance.Parent:IsA("Model")
					and not table.find(Projectile.HitList, Cast.Instance.Parent)
				then
					Projectile:FireHitSomeone(Cast.Instance.Parent, Cast.Position)
					if Projectile.DestroyOnHit then
						Projectile:Destroy()
					end
				elseif not Projectile.UseRaycastingForMap then
					Projectile:FireHitMap(Cast.Instance, Cast.Position)
					if Projectile.DestroyOnMapHit then
						Projectile:Destroy()
					end
				end
			end

			if not Cast and (Projectile.CheckForPeople or Projectile.CheckForMap) then
				local SecondCast =
					workspace:GetPartBoundsInRadius(Projectile.Position, Projectile.Radius, Projectile.OParams)
				if SecondCast then
					local HitAnything = false
					local PlayerFound = false
					for _, Part in SecondCast do
						if
							Part.Parent:FindFirstChild("Humanoid")
							and Part.Parent:IsA("Model")
							and (not Part:IsDescendantOf(Projectile.Owner) or not Projectile.Owner)
							and not table.find(Projectile.HitList, Part.Parent)
						then
							Projectile:FireHitSomeone(Part.Parent, Projectile.Position)
							PlayerFound = true
							HitAnything = true
							break
						end
					end
					if not PlayerFound and not Projectile.UseRaycastingForMap then
						for _, Part in SecondCast do
							if not Part:IsDescendantOf(Projectile.Owner) or not Projectile.Owner then
								Projectile:FireHitMap(Part, Projectile.Position)
								HitAnything = true
								if Projectile.DestroyOnMapHit then
									Projectile:Destroy()
								end
								break
							end
						end
					end
					if Projectile.DestroyOnHit and Projectile.DestroyOnMapHit and HitAnything then
						Projectile:Destroy()
					end
				end
			end
			if Projectile.Part then
				Projectile.Part.CFrame = CalculatedCFrame
			end
			Projectile.Position = CalculatedCFrame.Position
			Projectile.CFrame = CalculatedCFrame
			Projectile.LastTime = currentTime

			if Projectile.Lifetime and Projectile.Lifetime > 0 and LT >= Projectile.Lifetime then
				Projectile:Destroy()
			end
		end
	end

	RunService.PostSimulation:Connect(UpdateProjectiles)
end

if Settings.StartOnRequire then
	ProjectilePlus:Initialize()
end

--Returns all active Projectiles
function ProjectilePlus:GetProjectiles()
	return Projectiles
end

--Destroys all active projectiles.
function ProjectilePlus:ClearProjectiles()
	for _, Projectile in Projectiles do
		Projectile:Destroy()
	end
end

--Method used to clear all projectiles belonging to a specific player. Automatically fired when player leaves game, though this behavior can be toggled in the module Settings.
function ProjectilePlus:PlayerCleanup(Player: Player)
	local Character = Player.Character
	assert(Character, "Character not found.")
	for _, Projectile in Projectiles do
		if Projectile.Owner == Character then
			Projectile:Destroy()
		end
	end
end

if Settings.AutoPlayerCleanup then
	game.Players.PlayerRemoving:Connect(function(Player)
		ProjectilePlus:PlayerCleanup(Player)
	end)
end

--Creates a projectile catcher, which will fire .Caught when a projectile hits it.
function ProjectilePlus.CreateCatcher(Size: Vector3, Cframe: CFrame, Shape: Enum.PartType): Types.Catcher
	local Catcher: Types.Catcher = {}
	local CatcherSignal = Signal.new()
	local DestroyedSignal = Signal.new()
	Catcher.Destroyed = DestroyedSignal
	Catcher.Caught = CatcherSignal
	Catcher.CFrame = Cframe
	Catcher.Position = Cframe.Position
	Catcher.Size = Size
	Catcher.Shape = Shape
	Catcher.Debounce = 0.2
	Catcher.CaughtList = {}
	Catchers[Catcher] = true

	if Settings.ServerVisualize then
		local part = Instance.new("Part")
		part.Parent = workspace
		part.CanQuery = false
		part.CanCollide = false
		part.Anchored = true
		part.Size = Size
		part.Material = Enum.Material.Neon
		part.CastShadow = false
		part.CFrame = Cframe
		part.Shape = Shape
		part.Transparency = 0.5
		Catcher.Part = part
	end

	local CatcherZone = Zones.positionZone(Catcher)
	CatcherZone.Targets = Projectiles
	CatcherZone.Entered = function(Projectile)
		if not table.find(Catcher.CaughtList, Projectile) then
			Catcher:FireCaught(Projectile)
			table.insert(Catcher.CaughtList, Projectile)
			task.delay(Catcher.Debounce, function()
				table.remove(Catcher.CaughtList, table.find(Catcher.CaughtList, Projectile))
			end)
		end
	end

	function Catcher:WeldTo(Base: BasePart | Types.Projectile, Offset: CFrame?)
		local offset = Offset or CFrame.new()
		self._conn = RunService.Stepped:Connect(function()
			local cf = (Base.CFrame * offset)
			self.CFrame = cf
			self.Position = cf.Position

			if self.Part then
				self.Part.CFrame = cf
			end
		end)
	end

	function Catcher:UnWeld()
		if self._conn then
			self._conn:Disconnect()
		end
	end

	function Catcher:FireCaught(Projectile: Types.Projectile)
		self.Caught:Fire(Projectile)
		if self.OnCaught then
			self.OnCaught(Projectile)
		end
	end
	function Catcher:Destroy()
		self.Destroyed:Fire()
		CatcherZone:Destroy()
		Catcher:UnWeld()
		Catchers[self] = nil
		if Catcher.Part then
			Catcher.Part:Destroy()
		end
	end

	return Catcher
end

local function ConvertRaycastToOverlapParams(rayParams: RaycastParams): OverlapParams
	local overlapParams = OverlapParams.new()

	overlapParams.FilterType = rayParams.FilterType
	overlapParams.FilterDescendantsInstances = rayParams.FilterDescendantsInstances
	overlapParams.IgnoreWater = rayParams.IgnoreWater

	pcall(function()
		overlapParams.CollisionGroup = rayParams.CollisionGroup
	end)

	return overlapParams
end

--Creates a new projectile. Owner is the Character that the projectile belongs to, and will be filtered out of hit detection.
function ProjectilePlus.CreateProjectile(
	Owner: Model,
	Key: string,
	Radius: number,
	Velocity: Vector3,
	StartPosition: Vector3,
	Lifetime: number,
	Speed: number,
	raycastParams: RaycastParams
): Types.Projectile
	local Raw = {}

	if not Key then
		error("Projectile must have a key.")
	end

	local function sync(propertyOrTable, value)
		if typeof(propertyOrTable) == "table" then
			Broadcast("Update", {
				ID = Raw.ID,
				Properties = propertyOrTable,
			})
		else
			if propertyOrTable == "Radius" and Raw.Part then
				Raw.Part.Size = Vector3.new(value, value, value)
			end

			Broadcast("Update", {
				ID = Raw.ID,
				Properties = {
					[propertyOrTable] = value,
				},
			})
		end
	end

	local syncableKeys = {
		Speed = true,
		Velocity = true,
		GravityEnabled = true,
		GravityForce = true,
		TimeScale = true,
		Radius = true,
		Position = Settings.ImprovedClientAccuracy,
	}

	local DestroySignal = Signal.new()
	Raw.Destroying = DestroySignal
	local PlayerSignal = Signal.new()
	Raw.HitSomeone = PlayerSignal
	local MapSignal = Signal.new()
	Raw.HitMap = MapSignal

	local Proxy = setmetatable({}, {
		__index = function(_, key)
			if key == "Destroying" then
				return DestroySignal
			end
			return Raw[key]
		end,
		__newindex = function(_, key, value)
			Raw[key] = value
			if syncableKeys[key] then
				sync(key, value)
			end
		end,
	})

	ProjectileAddedSignal:Fire(Proxy)

	Raw.Key = Key or ""
	Raw.Owner = Owner
	Raw.Radius = Radius
	Raw.Velocity = Velocity
	Raw.Position = StartPosition
	Raw.Lifetime = Lifetime
	Raw.Speed = Speed
	Raw.RaycastParams = raycastParams
	Raw.DestroyOnMapHit = false
	Raw.DestroyOnHit = false
	Raw.Debounce = 0.2
	Raw.LastTime = workspace:GetServerTimeNow()
	Raw.StartTime = workspace:GetServerTimeNow()
	Raw.TimeScale = 1
	Raw.GravityEnabled = false
	Raw.GravityForce = 1
	Raw.ID = HTTPService:GenerateGUID()
	Raw.HitList = {}
	Raw.CheckForPeople = true
	Raw.CheckForMap = true
	Raw.ReflectEnabled = false
	Raw.CFrame = CFrame.new()
	Raw.UseRaycastingForMap = false
	Raw.UseRaycastingForPeople = false
	Raw.LastMapHit = nil
	Raw.LastMapHitTime = 0
	Raw.MapHitDebounce = 0.5

	if Settings.ServerVisualize then
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(Radius, Radius, Radius)
		part.Parent = workspace
		part.Transparency = 0.4
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(255, 0, 0)
		Raw.Part = part
	end

	if raycastParams then
		Raw.OParams = ConvertRaycastToOverlapParams(raycastParams)
	end

	function Raw:FireHitSomeone(Hit: Model, HitPosition: Vector3?)
		self.HitSomeone:Fire(Hit, HitPosition)
		table.insert(self.HitList, Hit)
		task.delay(self.Debounce, function()
			table.remove(self.HitList, table.find(self.HitList, Hit))
		end)
		if self.OnHitSomeone then
			self.OnHitSomeone(Hit, HitPosition)
		end
		Broadcast("HitPlayer", { ID = self.ID, Target = Hit, Position = HitPosition })
	end

	function Raw:FireHitMap(Hit: BasePart, HitPosition: Vector3?)
		if Hit ~= self.LastMapHit or (workspace:GetServerTimeNow() - Raw.LastMapHitTime) > Raw.MapHitDebounce then
			Raw.LastMapHit = Hit
			Raw.LastMapHitTime = workspace:GetServerTimeNow()
			self.HitMap:Fire(Hit, HitPosition)
			if self.OnHitMap then
				self.OnHitMap(Hit, HitPosition)
			end
			Broadcast("HitMap", { ID = self.ID, Part = Hit, Position = HitPosition })
		end
	end

	function Raw:Homing(Target, Strength)
		if typeof(Target) == "Instance" and Target:IsA("BasePart") then
			self.HomingTarget = Target
			self.HomingTargetPosition = nil
		elseif typeof(Target) == "Vector3" then
			self.HomingTarget = nil
			self.HomingTargetPosition = Target
		else
			error("Homing target must be a BasePart or Vector3")
		end
		self.HomingStrength = Strength or 1
	end

	function Raw:StopHoming()
		self.HomingTarget = nil
		self.HomingTargetPosition = nil
		self.HomingStrength = 1
	end

	function Raw:Destroy()
		if self.Destroying then
			self.Destroying:Fire()
		end
		ProjectileDestroyedSignal:Fire(Proxy)
		table.remove(Projectiles, table.find(Projectiles, Proxy))
		if self.Part then
			self.Part:Destroy()
		end
		Broadcast("Destroy", { ID = self.ID })
	end

	Broadcast("Create", {
		ID = Raw.ID,
		Position = Raw.Position,
		Velocity = Raw.Velocity,
		Speed = Raw.Speed,
		Radius = Raw.Radius,
		GravityEnabled = Raw.GravityEnabled,
		GravityForce = Raw.GravityForce,
		HomingTargetPosition = Raw.HomingTargetPosition,
		HomingStrength = Raw.HomingStrength or 1,
		TimeScale = Raw.TimeScale or 1,
		Key = Raw.Key,
		StartTime = workspace:GetServerTimeNow(),
	})

	table.insert(Projectiles, Proxy)

	return Proxy
end

--Built in Hitscan function. Checks for Catchers first, then Players, then Map, and returns one of the three.
--MaxRange is how far the scan can reach. Can be intercepted by Catchers, but only currently works with Ball and Block shaped catchers.
function ProjectilePlus:Hitscan(
	Origin: Vector3,
	EndPoint: Vector3,
	MaxRange: number,
	raycastParams: RaycastParams
): Model | BasePart | nil
	local Direction = CFrame.lookAt(Origin, EndPoint).LookVector
	local rayDirection = Direction * MaxRange

	for catcher in pairs(Catchers) do
		local pos = catcher.Position
		local size = catcher.Size
		local shape = catcher.Shape
		local hit = false

		if shape == Enum.PartType.Ball then
			local radius = size.X / 2
			local toCatcher = pos - Origin
			local projection = toCatcher:Dot(rayDirection.Unit)
			local closestPoint = Origin + rayDirection.Unit * math.clamp(projection, 0, MaxRange)
			local distanceToCatcher = (closestPoint - pos).Magnitude

			if distanceToCatcher <= radius then
				hit = true
			end
		else
			local cf = catcher.CFrame
			local localOrigin = cf:PointToObjectSpace(Origin)
			local localDirection = cf:VectorToObjectSpace(rayDirection)

			local min = -catcher.Size / 2
			local max = catcher.Size / 2

			local function rayIntersectsAABB(origin, dir)
				local t1 = (min - origin) / dir
				local t2 = (max - origin) / dir
				local tmin = math.max(math.min(t1.X, t2.X), math.min(t1.Y, t2.Y), math.min(t1.Z, t2.Z))
				local tmax = math.min(math.max(t1.X, t2.X), math.max(t1.Y, t2.Y), math.max(t1.Z, t2.Z))
				return tmax >= math.max(tmin, 0)
			end

			if rayIntersectsAABB(localOrigin, localDirection) then
				hit = true
			end
		end

		if hit then
			catcher:FireCaught({
				Position = pos,
				Direction = Direction,
				Origin = Origin,
				IsHitscan = true,
				Destroy = function() end,
			})
			return catcher
		end
	end

	local result = workspace:Raycast(Origin, rayDirection)
	if not result then
		return nil
	end

	local hitInstance = result.Instance
	local hitModel = hitInstance:FindFirstAncestorOfClass("Model")

	if hitModel and hitModel:FindFirstChild("Humanoid") then
		return hitModel
	end

	return hitInstance
end

return ProjectilePlus
