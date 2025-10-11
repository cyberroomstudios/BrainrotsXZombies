return {
	Name = script.Name,
	Aliases = { "GiveMoney" },
	Description = "Give Money to Player",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "from",
			Description = "The player",
		},

		{
			Type = "number",
			Name = "amount",
			Description = "The Amount",
		},
	},
}
