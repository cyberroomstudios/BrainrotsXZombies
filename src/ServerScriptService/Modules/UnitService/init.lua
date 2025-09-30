local UnitService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local units = require(ReplicatedStorage.Enums.units)

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("UnitService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

function UnitService:Init()
	UnitService:InitBridgeListener()
end

function UnitService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "GetAllUnits" then
			return PlayerDataHandler:Get(player, "unitsBackpack")
		end
	end
end

function UnitService:Give(player: Player, unitName: string)
	if not units[unitName] then
		warn("Unit not found:" .. unitName)
		return
	end

	PlayerDataHandler:Update(player, "unitsBackpack", function(current)
		local data = {
			UnitName = unitName,
			UnitType = units[unitName].Type,
			Amount = 1,
		}

		for _, value in ipairs(current) do
			if value.UnitName == unitName then
				value.Amount = value.Amount + 1
				return current -- já encontrou, pode retornar
			end
		end

		-- Se não encontrou, adiciona novo
		table.insert(current, data)
		return current
	end)
end

function UnitService:Consome(player: Player, unitName: string)
	if not units[unitName] then
		warn("Unit not found: " .. unitName)
		return
	end

	PlayerDataHandler:Update(player, "unitsBackpack", function(current)
		for _, value in ipairs(current) do
			if value.UnitName == unitName then
				if value.Amount <= 0 then
					warn("Unit without amount: " .. unitName)
					return current -- não consome, pois não há quantidade
				end

				value.Amount = value.Amount - 1
				return current -- consumiu uma unidade
			end
		end

		-- Se não encontrou a unidade no backpack
		warn("Unit not in backpack: " .. unitName)
		return current
	end)
end

return UnitService
