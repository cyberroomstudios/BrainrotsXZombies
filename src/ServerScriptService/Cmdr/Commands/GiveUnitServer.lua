local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local UnitService = require(ServerScriptService.Modules.UnitService)

return function(context, player,unitType: string, unitName: string )
	UnitService:Give(player, unitName, unitType)

	return "Success!"
end
