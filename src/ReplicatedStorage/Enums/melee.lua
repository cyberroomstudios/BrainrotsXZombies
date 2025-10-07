--LIGHTINING

local Melee = table.freeze({

	["cappuccinoAssassino"] = {
		Name = "cappuccinoAssassino",
		Life = 100,
		Price = 1000,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 5,
			NumberOfStudsBehind = 5,
			NumberOfStudsLeft = 5,
			NumberOfStudsRight = 5,
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
		DetectionRange = {
			NumberOfStudsForward = 5,
			NumberOfStudsBehind = 0,
			NumberOfStudsLeft = 1,
			NumberOfStudsRight = 1,
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

	["odin"] = {
		Name = "odin",
		Life = 100,
		Price = 1000,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 5,
			NumberOfStudsBehind = 2,
			NumberOfStudsLeft = 2,
			NumberOfStudsRight = 5,
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
})

return Melee
