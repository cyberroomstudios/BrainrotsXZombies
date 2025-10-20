export type VfxDefinition = {
	Key: string,
	Template: Instance?,
	Duration: number?,
}

export type VfxDefinitionBuilderObject = VfxDefinitionBuilderClass & VfxDefinitionBuilderModel

export type VfxDefinitionBuilderClass = {
	new: () -> VfxDefinitionBuilderObject,
	Reset: (self: VfxDefinitionBuilderObject) -> VfxDefinitionBuilderObject,
	SetKey: (self: VfxDefinitionBuilderObject, key: string) -> VfxDefinitionBuilderObject,
	SetTemplate: (self: VfxDefinitionBuilderObject, template: Instance) -> VfxDefinitionBuilderObject,
	SetDuration: (self: VfxDefinitionBuilderObject, duration: number?) -> VfxDefinitionBuilderObject,
	GetResult: (self: VfxDefinitionBuilderObject) -> VfxDefinition,
}

export type VfxDefinitionBuilderModel = {}

export type VfxRetrieveOptions = {
	Tag: string?,
	UserId: number?,
	PositionOffset: Vector3?,
	CanMove: boolean?,
}

return nil
