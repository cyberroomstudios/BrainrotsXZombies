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

function TeleportController:ToBaseStore()
	local spawnCFrame = player:GetAttribute("SPAWN_BASE_STORE_CFRAME")

	local character = player.Character

	if spawnCFrame and character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = spawnCFrame
	end
end

return TeleportController
