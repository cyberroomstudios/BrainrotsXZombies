local ServerScriptService = game:GetService("ServerScriptService")
local BrainrotEggService = require(ServerScriptService.Modules.BrainrotEggService)

return function(context: any, player: Player, name: string): string
	local success: boolean = BrainrotEggService:TryGiveEgg(player, name)
	return success and "Success!" or "Failed: no available slot"
end
