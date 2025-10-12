--LIGHTINING

local Spikes = table.freeze({

	["SpikesLevel1"] = {
		Name = "SpikesLevel1",
		Life = 100,
		Price = 1000,
		Rarity = "COMMON",
		Odd = 0.07,
		IsBrainrot = false,
		GUI = {
			Name = "Blue Block",
			Description = "Defend Your Base With 100 XP",
			Order = 1,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},
})

return Spikes
