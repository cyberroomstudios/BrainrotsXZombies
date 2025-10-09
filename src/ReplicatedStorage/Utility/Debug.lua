local function foo(): () end

--[[
	@description
		- Returns a print and warn function that can be used to print debug messages.
		- The print and warn functions will be enabled or disabled based on the value of the instance's "IsDebugging" attribute.
		- If instance is nil, the print and warn functions will be disabled.
]]
return function(instance: BaseScript): { print: (...any) -> (), warn: (...any) -> () }
	local isDebugging: boolean = (instance ~= nil and instance:GetAttribute("IsDebugging")) or false
	if isDebugging == true then
		local tag: string = instance.Name
		return {
			print = function(...)
				debug.setmemorycategory(tag)
				debug.profilebegin(tag)
				print(...)
				debug.profileend()
			end,
			warn = function(...)
				debug.setmemorycategory(tag)
				debug.profilebegin(tag)
				warn(...)
				debug.profileend()
			end,
		}
	else
		return {
			print = foo,
			warn = foo,
		}
	end
end
