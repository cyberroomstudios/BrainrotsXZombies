local MoneyService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local VfxFacade = require(ReplicatedStorage.Vfx.VfxFacade)

function MoneyService:GiveMoney(player: Player, amount: number)
	PlayerDataHandler:Update(player, "money", function(current)
		local newMoney = current + amount
		player:SetAttribute("MONEY", newMoney)
		return newMoney
	end)
	-- TODO it's just a testing mock. It should be called from where :GiveMoney is called, since it might be attached to different instances than the player's character primary part
	VfxFacade.RetrieveAndPlay("Money", player.Character.PrimaryPart, {
		UserId = player.UserId,
	})
end

function MoneyService:ConsumeMoney(player: Player, amount: number)
	if not MoneyService:HasMoney(player, amount) then
		return
	end

	PlayerDataHandler:Update(player, "money", function(current)
		local newMoney = current - amount

		player:SetAttribute("MONEY", newMoney)

		return newMoney
	end)
end

function MoneyService:ConsumeAllMoney(player: Player)
	PlayerDataHandler:Set(player, "money", 0)
	player:SetAttribute("MONEY", 0)
end

function MoneyService:HasMoney(player: Player, amount: number)
	local currentMoney = PlayerDataHandler:Get(player, "money")

	return amount <= currentMoney
end

function MoneyService:GiveInitialMoney(player: Player)
	if PlayerDataHandler:Get(player, "totalPlaytime") == 0 then
		MoneyService:GiveMoney(player, 20)
	end
end
return MoneyService
