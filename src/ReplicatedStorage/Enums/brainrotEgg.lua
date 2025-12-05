local UnitType = require(script.Parent.unitType)
local BrainrotEgg = table.freeze({

	["CappuccinoAssassino"] = {
		Name = "CappuccinoAssassino",
		TimeToHatch = 20,
		Type = UnitType.Melee,
	},

	["TungTungSahur"] = {
		Name = "TungTungSahur",
		TimeToHatch = 30,
		Type = UnitType.Melee,
	},

	["Odin"] = {
		Name = "Odin",
		TimeToHatch = 40,
		Type = UnitType.Melee,
	},

	["Lirili"] = {
		Name = "Lirili",
		TimeToHatch = 50,
		Type = UnitType.Melee,
	},

	["BobritoBandito"] = {
		Name = "BobritoBandito",
		TimeToHatch = 20,
		Type = UnitType.Ranged,
	},

	["Noobini"] = {
		Name = "Noobini",
		TimeToHatch = 30,
		Type = UnitType.Ranged,
	},

	["TralaleroTralala"] = {
		Name = "TralaleroTralala",
		TimeToHatch = 40,
		Type = UnitType.Ranged,
	},

	["BombardinoCrocodilo"] = {
		Name = "BombardinoCrocodilo",
		TimeToHatch = 50,
		Type = UnitType.Ranged,
	},
})

return BrainrotEgg
