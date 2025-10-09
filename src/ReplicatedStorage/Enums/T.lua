export type ItemGUI = {
	Name: string,
	Description: string,
	Order: number,
}

export type ItemStock = {
	Min: number,
	Max: number,
}

export type Item = {
	Name: string,
	Price: number,
	Rarity: string,
	Odd: number,
	GUI: ItemGUI,
	Stock: ItemStock,
}

export type BlockItem = Item & {
	Life: number,
}

export type Block = {
	[string]: BlockItem,
}

export type MeleeDetectionRange = {
	NumberOfStudsForward: number,
	NumberOfStudsBehind: number,
	NumberOfStudsLeft: number,
	NumberOfStudsRight: number,
}

export type MeleeItem = Item & {
	Life: number,
	DetectionRange: MeleeDetectionRange,
}

export type Melee = {
	[string]: MeleeItem,
}

export type RangedItem = Item & {
	Life: number,
}

export type Ranged = {
	[string]: RangedItem,
}

export type UnitsRarityGUI = {
	Order: number,
}

export type UnitsRarityItem = {
	Odd: number,
	GUI: UnitsRarityGUI,
}

export type UnitsRarity = {
	[string]: UnitsRarityItem,
}

return nil
