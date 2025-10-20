local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VfxDefinitionBuilder = require(script.Parent.VfxDefinitionBuilder)
local Builder = VfxDefinitionBuilder.new()
local Parent = ReplicatedStorage:WaitForChild("developer"):WaitForChild("VFX")

local Resources = {
	Fireworks = Builder --
		:Reset()
		:SetKey("Fireworks")
		:SetTemplate(Parent:WaitForChild("Fireworks"))
		:SetDuration(1.5)
		:GetResult(),
	Explosion = Builder --
		:Reset()
		:SetKey("Explosion")
		:SetTemplate(Parent:WaitForChild("Explosion"))
		:SetDuration(1.0)
		:GetResult(),
	Money = Builder --
		:Reset()
		:SetKey("Money")
		:SetTemplate(Parent:WaitForChild("Money"))
		:SetDuration(2.0)
		:GetResult(),
}

return Resources
