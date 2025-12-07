local Client = {}
print("ProjectilePlus Client Initialized")
local RunService = game:GetService("RunService")
local RemoteEvent = script.Parent:WaitForChild("Fire")

local Settings = require(script.Parent:WaitForChild("Settings"))
local ClientSignal = require(script:WaitForChild("ClientSignal"))

export type ClientProjectile = {
	ID: string,
	Velocity: Vector3,
	Speed: number,
	Position: Vector3,
	Radius: number,
	GravityEnabled: boolean,
	GravityForce: number,
	HomingTargetPosition: Vector3?,
	HomingStrength: number,
	TimeScale: number,
	Key: string,
	Part: BasePart,

	OnHitSomeone: typeof(ClientSignal.new()),
	OnHitMap: typeof(ClientSignal.new()),
	Destroying: typeof(ClientSignal.new()),

	WeldPart: (self: ClientProjectile, part: BasePart, offset: CFrame?) -> (),
	ClearWelds: (self: ClientProjectile) -> (),

	_weldedParts: { [BasePart]: CFrame }?,
	_weldConnection: RBXScriptConnection?,
	_simulationConnection: RBXScriptConnection?,
}

Client.ProjectileAdded = ClientSignal.new()
Client.ProjectileDestroying = ClientSignal.new()
Client.GlobalTimeScale = 1

local Visuals: { [string]: ClientProjectile } = {}

RemoteEvent.OnClientEvent:Connect(function(eventName: string, data: any)
	if eventName == "Create" then
		local proj: ClientProjectile = {
			ID = data.ID,
			Velocity = data.Velocity,
			TimeScale = data.TimeScale,
			Speed = data.Speed,
			Position = data.Position,
			Radius = data.Radius,
			GravityEnabled = data.GravityEnabled,
			GravityForce = data.GravityForce,
			HomingTargetPosition = data.HomingTargetPosition,
			HomingStrength = data.HomingStrength or 1,
			Key = data.Key or "",
			StartTime = data.StartTime or workspace:GetServerTimeNow(),
			OnHitSomeone = ClientSignal.new(),
			OnHitMap = ClientSignal.new(),
			Destroying = ClientSignal.new(),
			_weldedParts = {},
			_weldConnection = nil,
			_simulationConnection = nil,
		}

		proj.LastSimulatedTime = proj.StartTime
		proj.Part = {}

		if Settings.ClientVisualize then
			local part = Instance.new("Part")
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(proj.Radius, proj.Radius, proj.Radius)
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(21, 0, 255)
			part.Transparency = 0.4
			part.CFrame = CFrame.new(proj.Position)
			part.Parent = workspace
			proj.Part = part
		end

		proj._simulationConnection = RunService.Heartbeat:Connect(function()
			local now = workspace:GetServerTimeNow()
			local elapsed = now - proj.StartTime
			local dt = now - proj.LastSimulatedTime
			proj.LastSimulatedTime = now

			local scaledDt = dt * proj.TimeScale * Client.GlobalTimeScale

			-- Reset position from initial
			if elapsed == 0 then
				return
			end

			-- Apply gravity
			if proj.GravityEnabled and proj.GravityForce then
				proj.Velocity += Vector3.new(0, -proj.GravityForce * scaledDt, 0)
			end

			-- Apply homing
			if proj.HomingTargetPosition then
				local directionToTarget = (proj.HomingTargetPosition - proj.Position)
				if directionToTarget.Magnitude > 0 then
					local dirUnit = directionToTarget.Unit
					local currentDir = proj.Velocity.Unit
					local blendAlpha = math.clamp(proj.HomingStrength * scaledDt, 0, 1)
					local newDir = currentDir:Lerp(dirUnit, blendAlpha)
					local speed = proj.Velocity.Magnitude
					proj.Velocity = newDir.Unit * speed
				end
			end

			-- Update position from velocity
			proj.Position = proj.Position + proj.Velocity * proj.Speed * scaledDt

			-- Orientation
			local lookAt = proj.Position + proj.Velocity
			if proj.Velocity.Magnitude > 0 then
				proj.Part.CFrame = CFrame.lookAt(proj.Position, lookAt)
			else
				proj.Part.CFrame = CFrame.new(proj.Position)
			end

			-- Welded parts
			for p, offset in pairs(proj._weldedParts) do
				if p and p.Parent then
					p.CFrame = proj.Part.CFrame * offset
				else
					proj._weldedParts[p] = nil
				end
			end
		end)

		function proj:WeldPart(part: BasePart, offset: CFrame?)
			offset = offset or CFrame.new()
			if not self._weldConnection then
				self._weldConnection = true
			end
			self._weldedParts[part] = offset
		end

		function proj:ClearWelds()
			self._weldedParts = {}
			self._weldConnection = nil
		end

		Visuals[data.ID] = proj
		Client.ProjectileAdded:Fire(proj)
	elseif eventName == "Destroy" then
		local proj = Visuals[data.ID]
		if proj then
			proj.Destroying:Fire()
			Client.ProjectileDestroying:Fire(proj)

			if proj._simulationConnection then
				proj._simulationConnection:Disconnect()
				proj._simulationConnection = nil
			end

			if type(proj.Part) ~= "table" then
				proj.Part:Destroy()
				proj.Part = nil
			end

			proj:ClearWelds()
			Visuals[data.ID] = nil
		end
	elseif eventName == "HitPlayer" then
		local proj = Visuals[data.ID]
		if proj then
			proj.OnHitSomeone:Fire(data.Target, data.Position)
		end
	elseif eventName == "HitMap" then
		local proj = Visuals[data.ID]
		if proj then
			proj.OnHitMap:Fire(data.Part, data.Position)
		end
	elseif eventName == "Update" then
		local proj = Visuals[data.ID]
		if proj then
			for key, value in pairs(data.Properties) do
				if key == "Radius" and proj.Part then
					proj.Part.Size = Vector3.new(value, value, value)
				end

				if proj[key] ~= nil then
					proj[key] = value
				end
			end
		end
	elseif eventName == "TimeScaleChanged" then
		Client.GlobalTimeScale = data.GlobalTimeScale
	end
end)

return Client
