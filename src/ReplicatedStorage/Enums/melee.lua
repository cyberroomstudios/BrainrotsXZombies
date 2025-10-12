--LIGHTINING

local Melee = table.freeze({

	["cappuccinoAssassino"] = {
		Name = "cappuccinoAssassino",
		Life = 100,
		Price = 1000,
		ProductId = 3429149941,
		RestockProductId = 3429157417,
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
		Life = 100,
		Price = 1000,
		ProductId = 3429150292,
		RestockProductId = 3429180442,
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
		Life = 100,
		Price = 1000,
		ProductId = 3429181014,
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
})

return Melee
