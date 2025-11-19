local ServerScriptService = game:GetService("ServerScriptService")
local UnitService = require(ServerScriptService.Modules.UnitService)

return function(context: any, player: Player, category: string, name: string): string
	UnitService:Give(player, name, category)
	return "Success!"
end
