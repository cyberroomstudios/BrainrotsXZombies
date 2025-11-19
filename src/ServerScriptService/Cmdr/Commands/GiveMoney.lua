return {
	Name = script.Name,
	Aliases = { "GiveMoney" },
	Description = "Give money to target player",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Target player",
		},

		{
			Type = "number",
			Name = "amount",
			Description = "Money amount",
		},
	},
}
