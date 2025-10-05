--LIGHTINING

local Melee = table.freeze({

	["cappuccinoAssassino"] = {
		Name = "cappuccinoAssassino",
		Life = 100,
		Price = 1000,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 6,
			NumberOfStudsBehind = 6,
			NumberOfStudsLeft = 6,
			NumberOfStudsRight = 6,
		},
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
	["tungTungSahur"] = {
		Name = "tungTungSahur",
		Life = 100,
		Price = 1000,
		Rarity = "COMMON",
		Odd = 0.07,
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

return Melee
