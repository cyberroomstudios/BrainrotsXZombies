--LIGHTINING

local Ranged = table.freeze({
	["TowerLevel1"] = {
		Name = "TowerLevel1",
		IsBrainrot = false,
		Life = 100,
		Price = 1000,
		ProductId = 3429151285,
		RestockProductId = 3429183309,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Tower Level 1",
			Description = "Deploy Tower Level 1 to guard the perimeter.",
			Order = 1,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["TowerLevel2"] = {
		Name = "TowerLevel2",
		IsBrainrot = false,
		Life = 100,
		Price = 1000,
		ProductId = 3429151681,
		RestockProductId = 3429183403,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Tower Level 2",
			Description = "Upgrade to Tower Level 2 for stronger defense.",
			Order = 2,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["TowerLevel3"] = {
		Name = "TowerLevel3",
		IsBrainrot = false,
		Life = 100,
		Price = 1000,
		ProductId = 3429151972,
		RestockProductId = 3429183562,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Tower Level 3",
			Description = "Tower Level 3 keeps zombies at bay from afar.",
			Order = 3,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["TowerLevel4"] = {
		Name = "TowerLevel4",
		IsBrainrot = false,
		Life = 100,
		Price = 1000,
		ProductId = 3429152288,
		RestockProductId = 3429183660,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Tower Level 4",
			Description = "Tower Level 4 dominates long-range battles.",
			Order = 4,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["bobritoBandito"] = {
		Name = "bobritoBandito",
		IsBrainrot = true,
		Life = 100,
		Price = 1000,
		ProductId = 3429152642,
		RestockProductId = 3429183813,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Bobrito Bandito",
			Description = "Let Bobrito Bandito rain explosive shots.",
			Order = 5,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["Noobini"] = {
		Name = "Noobini",
		IsBrainrot = true,
		Life = 100,
		Price = 1000,
		ProductId = 3429152990,
		RestockProductId = 3429183943,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Noobini",
			Description = "Station Noobini to slow enemies with precise shots.",
			Order = 6,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},
})

return Ranged
