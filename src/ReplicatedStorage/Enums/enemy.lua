local Enemy = table.freeze({

	["Base"] = {
		Name = "Base",
		Hp = 100,
		DamagePerSecond = 5,
		Speed = 1,
		DropMoney = 10,
	},
	["Tank"] = {
		Name = "Tank",
		Hp = 250,
		DamagePerSecond = 12,
		Speed = 0.6,
		DropMoney = 25,
	},
	["Fast"] = {
		Name = "Fast",
		Hp = 70,
		DamagePerSecond = 4,
		Speed = 2,
		DropMoney = 12,
	},
	["Elite"] = {
		Name = "Elite",
		Hp = 400,
		DamagePerSecond = 20,
		Speed = 0.8,
		DropMoney = 50,
	},
    ["BasePlus"] = {
		Name = "BasePlus",
		Hp = 150,
		DamagePerSecond = 7,
		Speed = 1.2,
		DropMoney = 15,
	},
})

return Enemy
