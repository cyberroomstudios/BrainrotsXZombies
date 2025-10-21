local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local BrainrotEggService = require(ServerScriptService.Modules.BrainrotEggService)

return function(context, player, type: string)
	BrainrotEggService:GiveEgg(player, type)
	return "Success!"
end
