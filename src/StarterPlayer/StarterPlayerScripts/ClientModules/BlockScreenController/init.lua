local Players = game:GetService("Players")

local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local PreviewController = require(Players.LocalPlayer.PlayerScripts.ClientModules.PreviewController)

local BlockScreenController = {}

local blocksScreen

function BlockScreenController:Init()
	BlockScreenController:CreateReferences()
	BlockScreenController:InitButtonListerns()
end

function BlockScreenController:Open()
	blocksScreen.Visible = not blocksScreen.Visible
end

function BlockScreenController:InitButtonListerns()
	local items = blocksScreen:GetChildren()

	for _, valeu in items do
		valeu.MouseButton1Click:Connect(function()
			local blockName = valeu:GetAttribute("BLOCK_NAME")
			

            PreviewController:Start(blockName)
		end)
	end
end

function BlockScreenController:CreateReferences()
	-- Botões referentes aos Teleports
	blocksScreen = UIReferences:GetReference("BLOCKS_SCREEN")
end
return BlockScreenController
