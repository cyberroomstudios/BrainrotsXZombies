local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local UnitService = require(ServerScriptService.Modules.UnitService)

return function(context, player, unitName: string)
	UnitService:Give(player, unitName)

	return "Success!"
end
