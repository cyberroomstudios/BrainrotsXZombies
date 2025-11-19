return {
	Name = script.Name,
	Aliases = { "GiveBrainrot" },
	Description = "Give Brainrot to target player",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Target player",
		},

		{
			Type = "string",
			Name = "name",
			Description = "Brainrot name",
		},
	},
}
