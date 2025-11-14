--LIGHTINING

local Blocks = table.freeze({

	["Blue"] = {
		Name = "Blue",
		HP = 350,
		Price = 1000,
		ProductId = 3430682566,
		RestockProductId = 3430856119,
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

	["Orange"] = {
		Name = "Orange",
		HP = 200,
		Price = 1500,
		ProductId = 3430731014,
		RestockProductId = 3430856125,
		Rarity = "COMMON",
		Odd = 0.1,
		IsBrainrot = false,
		GUI = {
			Name = "Orange Block",
			Description = "Defend Your Base With 200 XP",
			Order = 2,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["Yellow"] = {
		Name = "Yellow",
		HP = 500,
		Price = 10000,
		ProductId = 3430856042,
		RestockProductId = 3430856129,
		Rarity = "UNCOMMON",
		Odd = 1,
		IsBrainrot = false,
		GUI = {
			Name = "Yellow Block",
			Description = "Defend Your Base With 300 XP",
			Order = 3,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},
})

return Blocks
