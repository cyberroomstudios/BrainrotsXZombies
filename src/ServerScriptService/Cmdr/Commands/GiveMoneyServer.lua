local ServerScriptService = game:GetService("ServerScriptService")
local MoneyService = require(ServerScriptService.Modules.MoneyService)

return function(context: any, player: Player, amount: number): string
	MoneyService:GiveMoney(player, amount)
	return "Success!"
end
