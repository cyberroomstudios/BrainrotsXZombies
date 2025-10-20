local VfxController = {}

-- === SERVICES
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

-- === LOCAL FUNCTIONS
local function onInvoke(methodName: string, ...): ...any
	local payload = {
		[actionIdentifier] = methodName,
		data = table.pack(...),
	}
	local response = bridge:InvokeServerAsync(payload)
	if typeof(response) ~= "table" then
		return response
	end
	if response[statusIdentifier] == "error" then
		Debug.warn("Server rejected VFX invoke:", response[messageIdentifier])
		return nil
	end
	local data = response.data
	if typeof(data) == "table" then
		return table.unpack(data)
	end
	return data
end

-- === GLOBAL FUNCTIONS
function VfxController:Init(): ()
	Facade.SetOnInvokeCallback(onInvoke)
end

return VfxController
