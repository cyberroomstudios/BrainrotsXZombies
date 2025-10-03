return {
	Name = script.Name,
	Aliases = { "GiveUnit" },
	Description = "Give Unit to PLayer",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "from",
			Description = "Player",
		},

		{
			Type = "string",
			Name = "type",
			Description = "Unit Type",
		},

		{
			Type = "string",
			Name = "unit",
			Description = "Unit Name",
		},

		
	},
}
