local Facade = {}

-- === SERVICES
local RunService = game:GetService("RunService")

-- === CUSTOM TYPES
local T = require(script.Parent.Types)

-- === LOCAL VARIABLES
local Callback: ((methodName: string, ...any) -> ...any)?

-- === LOCAL FUNCTIONS
local function invoke(methodName: string, ...): ...any
	while Callback == nil do
		task.wait()
	end
	return Callback(methodName, ...)
end

function Facade.SetOnInvokeCallback(callback: (methodName: string, ...any) -> ...any): ()
	Callback = callback
end

function Facade.Retrieve(key: string, parent: Instance, options: T.VfxRetrieveOptions?): Instance?
	return invoke("Retrieve", key, parent, options)
end

function Facade.RetrieveParentless(key: string, position: Vector3, options: T.VfxRetrieveOptions?): Instance?
	return invoke("RetrieveParentless", key, position, options)
end

function Facade.RetrieveAndPlay(key: string, parent: Instance, options: T.VfxRetrieveOptions?): Instance?
	return invoke("RetrieveAndPlay", key, parent, options)
end

function Facade.RetrieveAndPlayParentless(key: string, position: Vector3, options: T.VfxRetrieveOptions?): Instance?
	return invoke("RetrieveAndPlayParentless", key, position, options)
end

function Facade.Play(key: string, instance: Instance): ()
	invoke("Play", key, instance)
end

function Facade.Enable(root: Instance): ()
	invoke("Enable", root)
end

function Facade.Disable(root: Instance): ()
	invoke("Disable", root)
end

function Facade.SetEnabled(root: Instance, enabled: boolean): ()
	invoke("SetEnabled", root, enabled)
end

function Facade.StopTracking(instance: Instance): ()
	invoke("StopTracking", instance)
end

function Facade.Release(instance: Instance): ()
	invoke("Release", instance)
end

function Facade.Cleanup(instance: Instance): ()
	invoke("Cleanup", instance)
end

function Facade.ReleaseAll(): ()
	invoke("ReleaseAll")
end

function Facade.ReleaseAllByTag(tag: string): ()
	invoke("ReleaseAllByTag", tag)
end

function Facade.ReleaseAllByOwner(userId: number): ()
	invoke("ReleaseAllByOwner", userId)
end

function Facade.Init(definitions: { [string]: T.VfxDefinition }): ()
	invoke("Init", definitions)
end

function Facade.InitAsync(definitions: { [string]: T.VfxDefinition }): ()
	invoke("InitAsync", definitions)
end

if RunService:IsServer() then
	function Facade.EnableFor(player: Player, root: Instance): ()
		invoke("EnableFor", player, root)
	end

	function Facade.DisableFor(player: Player, root: Instance): ()
		invoke("DisableFor", player, root)
	end
end

return Facade
