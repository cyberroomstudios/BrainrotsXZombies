local TeleportController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

function TeleportController:Init() end

function TeleportController:ToBase()
	local base = Workspace.map.baseLocations[player:GetAttribute("BASE")]
	local character = player.Character

	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = base.baseTemplate.PrimaryPart.CFrame + Vector3.new(0, 10, 0)
	end
end

return TeleportController
