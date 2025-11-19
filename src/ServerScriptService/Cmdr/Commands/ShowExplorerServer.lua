local ServerStorage = game:GetService("ServerStorage")

return function(context: any, players: { Player }): string
	local returnMessage: string = ""
	for _, player in players do
		ServerStorage.Debugging.Dex_Explorer:Clone().Parent = player.PlayerGui
	end
	return returnMessage
end
