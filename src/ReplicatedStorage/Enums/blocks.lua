--LIGHTINING

local Blocks = table.freeze({
	["blue"] = {
		Name = "blue",
		Life = 100,
		Price = 1000,
		ProductId = 3429139794,
		RestockProductId = 3429156191,
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

	["orange"] = {
		Name = "orange",
		Life = 100,
		Price = 1500,
		ProductId = 3429149073,
		RestockProductId = 3429156473,
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

	["yellow"] = {
		Name = "yellow",
		Life = 100,
		Price = 10000,
		ProductId = 3429149577,
		RestockProductId = 3429156837,
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
