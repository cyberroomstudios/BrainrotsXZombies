return {
	Name = script.Name,
	Aliases = { "GiveBrainrot" },
	Description = "Give Brainrot to Player",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "from",
			Description = "The player",
		},

		{
			Type = "string",
			Name = "name",
			Description = "The Name",
		},
	},
}
