local UnitService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("UnitService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

-- === ENUMS
local Blocks = require(ReplicatedStorage.Enums.blocks)
local Melee = require(ReplicatedStorage.Enums.melee)
local Ranged = require(ReplicatedStorage.Enums.ranged)
local Spikes = require(ReplicatedStorage.Enums.spikes)

local ENUM_BY_UNIT_TYPE = table.freeze({
	BLOCK = Blocks,
	MELEE = Melee,
	RANGED = Ranged,
	SPIKES = Spikes,
})

-- === GLOBAL FUNCTIONS
function UnitService:Init(): ()
	UnitService:InitBridgeListener()
end

function UnitService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "GetAllUnits" then
			return PlayerDataHandler:Get(player, "unitsBackpack")
		end
	end
end

function UnitService:Give(player: Player, unitName: string, unitType: string, amount: number?): ()
	local module = ENUM_BY_UNIT_TYPE[unitType]
	if not module then
		warn(`Enum not found for type {unitType}`)
		return
	end

	if not module[unitName] then
		warn(`Unit {unitName} not found in type {unitType}`)
		return
	end

	amount = amount or 1
	PlayerDataHandler:Update(player, "unitsBackpack", function(current)
		-- Update existing item
		for _, value in ipairs(current) do
			if value.UnitName == unitName then
				value.Amount += amount
				amount = value.Amount
				return current
			end
		end
		-- Add new item
		table.insert(current, {
			UnitName = unitName,
			UnitType = unitType,
			Amount = amount,
			IsBrainrot = module[unitName].IsBrainrot,
		})
		return current
	end)
	print(
		`[UnitService] Given unit {unitName} to player {player.Name}. Backpack: `,
		PlayerDataHandler:Get(player, "unitsBackpack")
	)
	bridge:Fire(player, {
		[actionIdentifier] = "ItemAdded",
		UnitName = unitName,
		UnitType = unitType,
		Amount = amount,
	})
end

function UnitService:Consume(player: Player, unitName: string, unitType: string): boolean
	local consumed: boolean = false
	local amount: number = 0
	PlayerDataHandler:Update(player, "unitsBackpack", function(current: table): table
		for _, value in ipairs(current) do
			if value.UnitName == unitName then
				if value.Amount < 1 then
					warn(`Tried to consume unit {unitName} amount that player {player.Name} does not have`)
					return current -- Can't consume
				end
				value.Amount -= 1
				amount = value.Amount
				consumed = true
				return current -- consumed one unit
			end
		end

		warn(`Tried to consume unit {unitName} that's not present in player {player.Name}'s backpack`)
		return current
	end)
	if consumed then
		bridge:Fire(player, {
			[actionIdentifier] = "ItemQuantityChanged",
			UnitName = unitName,
			UnitType = unitType,
			Amount = amount,
		})
	end
	return consumed
end

return UnitService
