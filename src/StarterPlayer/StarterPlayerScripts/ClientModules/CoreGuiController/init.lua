local CoreGuiController = {}

-- === CONSTANTS
local BLOCK_ACTION: string = "BlockBackpackHotkeys"

-- === SERVICES
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")

-- === GLOBAL FUNCTIONS
function CoreGuiController:Init(): ()
	-- Hide Roblox default backpack UI
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)

	-- Sink default number hotkeys (1-0) that equip tools from Backpack
	local keys = {
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Five,
		Enum.KeyCode.Six,
		Enum.KeyCode.Seven,
		Enum.KeyCode.Eight,
		Enum.KeyCode.Nine,
		Enum.KeyCode.Zero,
	}
	ContextActionService:BindAction(BLOCK_ACTION, function(_, _state)
		-- Always consume these inputs
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keys))
end

return CoreGuiController
