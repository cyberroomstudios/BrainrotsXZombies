local VfxService = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("VfxService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local Debug = require(Utility.Debug)(script)
local Facade = require(ReplicatedStorage.Vfx.VfxFacade)
local Wrapper = require(ReplicatedStorage.Vfx.VfxWrapper)
local Definitions = require(ReplicatedStorage.Vfx.Definitions)

-- === LOCAL FUNCTIONS
local function runWrapper(methodName: string, ...): ...any
	local callback = Wrapper[methodName]
	if typeof(callback) ~= "function" then
		error(`VfxService: Unknown wrapper method "{methodName}"`)
	end
	return callback(...)
end

local function onFacadeInvoke(methodName: string, ...): ...any
	if methodName:sub(-3) == "For" then
		local args = table.pack(...)
		local player = args[1]
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			error(`VfxService: Invalid player provided to "{methodName}"`)
		end

		local targetMethod = methodName:sub(1, -4)
		local payload = {
			[actionIdentifier] = targetMethod,
			data = table.pack(table.unpack(args, 2)),
		}
		bridge:Fire(player, payload)
		return
	end
	return runWrapper(methodName, ...)
end

local function onClientInvoke(player: Player, payload: any): any
	if typeof(payload) ~= "table" then
		return {
			[statusIdentifier] = "error",
			[messageIdentifier] = "Payload must be a table",
		}
	end

	local methodName = payload[actionIdentifier]
	local args = payload.data

	if typeof(methodName) ~= "string" then
		return {
			[statusIdentifier] = "error",
			[messageIdentifier] = "Method must be a string",
		}
	end

	local callback = Wrapper[methodName]
	if typeof(callback) ~= "function" then
		return {
			[statusIdentifier] = "error",
			[messageIdentifier] = `Unknown method "{methodName}"`,
		}
	end
	local success, results
	if typeof(args) == "table" then
		success, results = pcall(function(): ()
			return table.pack(callback(table.unpack(args)))
		end)
	else
		success, results = pcall(function(): ()
			return table.pack(callback())
		end)
	end
	if not success then
		Debug.warn("Failed to execute client invoke:", results)
		return {
			[statusIdentifier] = "error",
			[messageIdentifier] = "Execution failed",
		}
	end

	return {
		[statusIdentifier] = "ok",
		data = results,
	}
end

-- === GLOBAL FUNCTIONS
function VfxService:Init(): ()
	Facade.SetOnInvokeCallback(onFacadeInvoke)
	Facade.Init(Definitions)
	bridge.OnServerInvoke = onClientInvoke
	Players.PlayerRemoving:Connect(function(player: Player): ()
		Wrapper.ReleaseAllByOwner(player.UserId)
	end)
end

return VfxService
