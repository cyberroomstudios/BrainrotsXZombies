--LIGHTINING

local UnitsRarity = table.freeze({

	["COMMON"] = {
		Odd = 1,
		GUI = {
			Order = 1,
		}
	},

	["UNCOMMON"] = {
		Odd = 0.5,
		GUI = {
			Order = 2,
		}
	},
	["MYTHIC"] = {
		Odd = 0.2,
		GUI = {
			Order = 3,
		}
	},
})

return UnitsRarity
