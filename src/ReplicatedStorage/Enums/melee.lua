--LIGHTINING

local Melee = table.freeze({

	["cappuccinoAssassino"] = {
		Name = "cappuccinoAssassino",
		HP = 1000,
		Damege = 40,
		Price = 1000,
		Cadence = 1.8,
		ProductId = 3430856048,
		RestockProductId = 3430856132,
		Rarity = "COMMON",
		Odd = 0.07,
		IsBrainrot = true,
		DetectionRange = {
			NumberOfStudsForward = 5,
			NumberOfStudsBehind = 5,
			NumberOfStudsLeft = 5,
			NumberOfStudsRight = 5,
		},
		GUI = {
			Name = "Cappuccino Assassino",
			Description = "Unleash the Cappuccino Assassino for rapid melee strikes.",
			Order = 1,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["tungTungSahur"] = {
		Name = "tungTungSahur",
		HP = 700,
		Damege = 30,
		Price = 1000,
		Cadence = 1.5,
		ProductId = 3430856054,
		RestockProductId = 3430856135,
		Rarity = "COMMON",
		Odd = 0.07,
		IsBrainrot = true,
		DetectionRange = {
			NumberOfStudsForward = 5,
			NumberOfStudsBehind = 0,
			NumberOfStudsLeft = 1,
			NumberOfStudsRight = 1,
		},
		GUI = {
			Name = "Tung Tung Sahur",
			Description = "Summon Tung Tung Sahur to stagger nearby foes.",
			Order = 2,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["odin"] = {
		Name = "odin",
		HP = 1400,
		Damege = 80,
		Price = 1000,
		Cadence = 1.3,
		ProductId = 3430856058,
		RestockProductId = 3430856142,
		Rarity = "COMMON",
		Odd = 0.07,
		IsBrainrot = true,
		DetectionRange = {
			NumberOfStudsForward = 5,
			NumberOfStudsBehind = 2,
			NumberOfStudsLeft = 2,
			NumberOfStudsRight = 5,
		},
		GUI = {
			Name = "Odin",
			Description = "Command Odin to cleave through enemy lines.",
			Order = 3,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},

	["Lirili"] = {
		Name = "Lirili",
		HP = 6000,
		Damege = 200,
		Price = 1000,
		Cadence = 1.2,
		ProductId = 3430856062,
		RestockProductId = 3430856149,
		Rarity = "COMMON",
		Odd = 0.07,
		IsBrainrot = true,

		DetectionRange = {
			NumberOfStudsForward = 5,
			NumberOfStudsBehind = 2,
			NumberOfStudsLeft = 2,
			NumberOfStudsRight = 5,
		},
		GUI = {
			Name = "Lirili",
			Description = "Deploy Lirili to swiftly eliminate threats.",
			Order = 4,
		},
		Stock = {
			Min = 1,
			Max = 5,
		},
	},
})

return Melee
