local Wrapper = {}

-- === SERVICES
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- === MODULES
local Types = require(script.Parent.Types)

-- === CUSTOM TYPES
type VfxDefinition = Types.VfxDefinition
type VfxRetrieveOptions = Types.VfxRetrieveOptions
type ActiveInstance = {
	Key: string,
	Tag: string?,
	UserId: number?,
}

-- === LOCAL VARIABLES
local Definitions: { [string]: VfxDefinition } = {}
local ActiveInstances: { [Instance]: ActiveInstance } = {}
local Connections: { [Instance]: RBXScriptConnection } = {}

-- === ON START
local Folder: Folder = Workspace:FindFirstChild("VfxFolder") or Instance.new("Folder")
Folder.Name = "VfxFolder"
Folder.Parent = Workspace

-- === LOCAL FUNCTIONS
local function stopTracking(instance: Instance): ()
	local connection = Connections[instance]
	if connection then
		connection:Disconnect()
		Connections[instance] = nil
	end
end

local function setDescendantEmittersEnabled(root: Instance, enabled: boolean): ()
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = enabled
		end
	end
end

local function getReferenceCFrame(parent: Instance): CFrame?
	if parent == nil then
		return nil
	end
	if parent:IsA("Model") then
		local primary = parent.PrimaryPart
		if primary then
			return primary.CFrame
		end
		return parent:GetPivot()
	elseif parent:IsA("BasePart") then
		return parent.CFrame
	elseif parent:IsA("Attachment") then
		return CFrame.new(parent.WorldPosition)
	end
	return nil
end

local function applyOffset(base: CFrame, positionOffset: Vector3?): CFrame
	if positionOffset then
		return base * CFrame.new(positionOffset)
	end
	return base
end

local function updateInstanceTransform(instance: Instance, parent: Instance, positionOffset: Vector3?): ()
	local reference = getReferenceCFrame(parent)
	if reference == nil then
		return
	end
	local adjustedCFrame = applyOffset(reference, positionOffset)
	if instance:IsA("BasePart") then
		instance.CFrame = adjustedCFrame
	elseif instance:IsA("Model") then
		local primary = instance.PrimaryPart
		if primary then
			instance:PivotTo(adjustedCFrame)
		else
			instance:MoveTo(adjustedCFrame.Position)
		end
	end
end

local function storeActive(instance: Instance, key: string, tag: string?, userId: number?): ()
	ActiveInstances[instance] = { Key = key, Tag = tag, UserId = userId }
end

local function cloneTemplate(key: string): Instance | Model | nil
	if not Definitions[key] then
		warn(`[VfxWrapper] No definition registered for key {key}`)
		return nil
	end

	local template = Definitions[key].Template
	if not template then
		warn(`[VfxWrapper] Missing template for key {key}`)
		return nil
	end

	local instance = template:Clone()
	instance.Parent = Folder
	return instance
end

-- === GLOBAL FUNCTIONS
function Wrapper.Init(definitions: { [string]: VfxDefinition }): ()
	Wrapper.ReleaseAll()
	Definitions = definitions
	ActiveInstances = {}
end

function Wrapper.InitAsync(definitions: { [string]: VfxDefinition }): ()
	task.defer(function(): ()
		Wrapper.Init(definitions)
	end)
end

function Wrapper.Retrieve(key: string, parent: Instance, options: VfxRetrieveOptions?): Instance?
	assert(type(key) == "string", "VfxWrapper.Retrieve expects a key")
	assert(typeof(parent) == "Instance", "VfxWrapper.Retrieve expects a valid parent instance")

	local instance = cloneTemplate(key)
	if instance == nil then
		return nil
	end

	updateInstanceTransform(instance, parent, options.PositionOffset)

	if options.CanMove then
		Connections[instance] = RunService.Heartbeat:Connect(function(): ()
			if parent.Parent == nil or instance.Parent == nil then
				Wrapper.Release(instance)
				return
			end
			updateInstanceTransform(instance, parent, options.PositionOffset)
		end)
	end

	storeActive(instance, key, options.Tag, options.UserId)
	return instance
end

function Wrapper.RetrieveParentless(key: string, position: Vector3, options: VfxRetrieveOptions?): Instance?
	assert(type(key) == "string", "VfxWrapper.RetrieveParentless expects a key")
	assert(typeof(position) == "Vector3", "VfxWrapper.RetrieveParentless expects a Vector3 position")

	local instance = cloneTemplate(key)
	if instance == nil then
		return nil
	end

	local adjustedCFrame = CFrame.new(position)
	if instance:IsA("Model") then
		if instance.PrimaryPart then
			instance:PivotTo(adjustedCFrame)
		else
			instance:MoveTo(position)
		end
	elseif instance:IsA("BasePart") then
		instance.CFrame = adjustedCFrame
	end

	storeActive(instance, key, options.Tag, options.UserId)
	return instance
end

function Wrapper.RetrieveAndPlay(key: string, parent: Instance, options: VfxRetrieveOptions?): Instance?
	local instance = Wrapper.Retrieve(key, parent, options)
	if instance then
		Wrapper.Play(key, instance)
	end
	return instance
end

function Wrapper.RetrieveAndPlayParentless(key: string, position: Vector3, options: VfxRetrieveOptions?): Instance?
	local instance = Wrapper.RetrieveParentless(key, position, options)
	if instance then
		Wrapper.Play(key, instance)
	end
	return instance
end

function Wrapper.StopTracking(instance: Instance): ()
	stopTracking(instance)
end

function Wrapper.SetEnabled(root: Instance, enabled: boolean): ()
	setDescendantEmittersEnabled(root, enabled)
end

function Wrapper.Enable(root: Instance): ()
	Wrapper.SetEnabled(root, true)
end

function Wrapper.Disable(root: Instance): ()
	Wrapper.SetEnabled(root, false)
end

function Wrapper.Play(key: string, instance: Instance): ()
	local definition = Definitions[key]
	if definition == nil then
		warn(`[VfxWrapper] Attempted to play unregistered key {key}`)
		return
	end

	local duration = definition.Duration
	if duration then
		task.spawn(function(): ()
			Wrapper.Enable(instance)
			task.wait(duration)
			Wrapper.Disable(instance)
			local active = ActiveInstances[instance]
			if active then
				Wrapper.Release(instance)
			end
		end)
	else
		Wrapper.Enable(instance)
	end
end

function Wrapper.Release(instance: Instance): ()
	if instance == nil then
		return
	end
	local active = ActiveInstances[instance]
	if active == nil then
		stopTracking(instance)
		if instance.Parent then
			instance.Parent = nil
		end
		pcall(function(): ()
			instance:Destroy()
		end)
		return
	end

	Wrapper.Disable(instance)
	local emitters = instance:GetDescendants()
	local delaySeconds = 0
	for _, descendant in ipairs(emitters) do
		if descendant:IsA("ParticleEmitter") then
			delaySeconds = math.max(delaySeconds, descendant.Lifetime.Max)
		end
	end

	task.delay(delaySeconds, function(): ()
		stopTracking(instance)
		if instance.Parent then
			instance.Parent = nil
		end
		pcall(function(): ()
			instance:Destroy()
		end)
		ActiveInstances[instance] = nil
	end)
end

function Wrapper.Cleanup(instance: Instance): ()
	if instance == nil then
		return
	end
	local active = ActiveInstances[instance]
	if active then
		Wrapper.Release(instance)
	else
		stopTracking(instance)
		if instance.Parent ~= nil then
			instance.Parent = nil
		end
		pcall(function(): ()
			instance:Destroy()
		end)
	end
end

function Wrapper.ReleaseAll(): ()
	for instance in pairs(ActiveInstances) do
		Wrapper.Release(instance)
	end
	ActiveInstances = {}
end

function Wrapper.ReleaseAllByTag(tag: string): ()
	assert(type(tag) == "string", "VfxWrapper.ReleaseAllByTag Tag must be a string")
	local instances = {}
	for instance, data in pairs(ActiveInstances) do
		if data.Tag == tag then
			table.insert(instances, instance)
		end
	end
	for _, instance in ipairs(instances) do
		Wrapper.Release(instance)
	end
end

function Wrapper.ReleaseAllByOwner(userId: number): ()
	assert(type(userId) == "number", "VfxWrapper.ReleaseAllByOwner UserId must be a number")
	local instances = {}
	for instance, data in pairs(ActiveInstances) do
		if data.UserId == userId then
			table.insert(instances, instance)
		end
	end
	for _, instance in ipairs(instances) do
		Wrapper.Release(instance)
	end
end

return Wrapper
