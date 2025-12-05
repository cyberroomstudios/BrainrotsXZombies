local WeaponService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local Response = require(ReplicatedStorage.Utility.Response)
local bridge = BridgeNet2.ReferenceBridge("WeaponService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

-- === ENUMS

-- === GLOBAL FUNCTIONS
function WeaponService:Init(): ()
	WeaponService:InitBridgeListener()
end

function WeaponService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): table
		if data[actionIdentifier] == "GetAllWeapons" then
			return PlayerDataHandler:Get(player, "weapons")
		elseif data[actionIdentifier] == "TryEquip" then
			local weaponName = data.WeaponName
			local success = WeaponService:TryEquip(player, weaponName)
			return success and {
				[statusIdentifier] = Response.STATUS.SUCCESS,
			} or {
				[statusIdentifier] = Response.STATUS.ERROR,
				[messageIdentifier] = Response.MESSAGES.UNAVAILABLE_WEAPON,
			}
		else
			return {
				[statusIdentifier] = Response.STATUS.ERROR,
				[messageIdentifier] = Response.MESSAGES.INVALID_ACTION,
			}
		end
	end
end

function WeaponService:Give(player: Player, weaponName: string): ()
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

function WeaponService:TryEquip(player: Player, weaponName: string): boolean
	local weapons: table = PlayerDataHandler:Get(player, "weapons")
	if not table.find(weapons, weaponName) then
		return false
	end
	PlayerDataHandler:Set(player, "equippedWeapon", weaponName)
	return true
end

return WeaponService
