local UnitService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("WeaponService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

-- === ENUMS

-- === GLOBAL FUNCTIONS
function UnitService:Init(): ()
	UnitService:InitBridgeListener()
end

function UnitService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): table
		if data[actionIdentifier] == "GetAllWeapons" then
			return PlayerDataHandler:Get(player, "weapons")
		end
	end
end

function UnitService:Give(player: Player, weaponName: string): ()
	PlayerDataHandler:Update(player, "weapons", function(current: table): table
		if table.find(current, weaponName) then
			warn(`Player {player.Name} already has weapon {weaponName}`)
			return current
		end
		table.insert(current, weaponName)
		return current
	end)

	bridge:Fire(player, {
		[actionIdentifier] = "WeaponAdded",
		WeaponName = weaponName,
	})
end

return UnitService
