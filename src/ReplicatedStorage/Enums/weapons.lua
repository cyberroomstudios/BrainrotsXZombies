local Weapons = table.freeze({
	Fist = {
		Name = "Fist",
		Damage = 5,
		Range = 3,
		FireRate = 1,
		AmmoCapacity = math.huge, -- Use -1 or nil instead for unlimited?
		ReloadTime = 0,
	},
	Pistol = {
		Name = "Pistol",
		Damage = 15,
		Range = 50,
		FireRate = 0.5,
		AmmoCapacity = 12,
		ReloadTime = 1.5,
	},
})

return Weapons
