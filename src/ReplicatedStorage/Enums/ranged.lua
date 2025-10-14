--LIGHTINING

local Ranged = table.freeze({
	["TowerLevel1"] = {
		Name = "TowerLevel1",
		IsBrainrot = false,
		Life = 100,
		Price = 1000,
		ProductId = 3430856070,
		RestockProductId = 3430856156,
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
		ProductId = 3430856077,
		RestockProductId = 3430856163,
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
		ProductId = 3430856085,
		RestockProductId = 3430856170,
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
		ProductId = 3430856093,
		RestockProductId = 3430856176,
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
		ProductId = 3430856100,
		RestockProductId = 3430856183,
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
		ProductId = 3430856104,
		RestockProductId = 3430856191,
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

	["tralaleroTralala"] = {
		Name = "tralaleroTralala",
		IsBrainrot = true,
		Life = 100,
		Price = 1000,
		ProductId = 3430856109,
		RestockProductId = 3430856198,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Tralalero Tralala",
			Description = "Field Tralalero Tralala to ricochet shots through the horde.",
			Order = 7,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["bombardinoCrocodilo"] = {
		Name = "bombardinoCrocodilo",
		IsBrainrot = true,
		Life = 100,
		Price = 1000,
		ProductId = 3430856114,
		RestockProductId = 3430856201,
		Rarity = "COMMON",
		Odd = 0.07,
		DetectionRange = {
			NumberOfStudsForward = 10,
			NumberOfStudsBehind = 10,
			NumberOfStudsLeft = 10,
			NumberOfStudsRight = 10,
		},
		GUI = {
			Name = "Bombardino Crocodilo",
			Description = "Deploy Bombardino Crocodilo to bombard enemies with explosive arcs.",
			Order = 8,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},
})

return Ranged
