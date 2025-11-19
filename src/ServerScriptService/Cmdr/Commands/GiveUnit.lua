return {
	Name = script.Name,
	Aliases = { "GiveUnit" },
	Description = "Give Unit to target player",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Target player",
		},

		{
			Type = "string",
			Name = "category",
			Description = "Unit category",
		},

		{
			Type = "string",
			Name = "name",
			Description = "Unit name",
		},
	},
}
