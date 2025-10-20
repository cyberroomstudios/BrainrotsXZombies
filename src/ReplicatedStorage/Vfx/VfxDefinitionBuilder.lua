local T = require(script.Parent.Types)

local Builder: T.VfxDefinitionBuilderClass = {}
Builder.__index = Builder

local __: { [T.VfxDefinitionBuilderObject]: T.VfxDefinition } = setmetatable({}, { __mode = "k" })

function Builder.new(): T.VfxDefinitionBuilderObject
	return setmetatable({}, Builder):Reset()
end

function Builder:Reset(): T.VfxDefinitionBuilderObject
	__[self] = {}
	return self
end

function Builder:SetKey(key: string): T.VfxDefinitionBuilderObject
	__[self].Key = key
	return self
end

function Builder:SetTemplate(template: Instance): T.VfxDefinitionBuilderObject
	__[self].Template = template
	return self
end

function Builder:SetDuration(duration: number?): T.VfxDefinitionBuilderObject
	__[self].Duration = duration
	return self
end

function Builder:GetResult(): T.VfxDefinition
	return table.clone(__[self])
end

return Builder
