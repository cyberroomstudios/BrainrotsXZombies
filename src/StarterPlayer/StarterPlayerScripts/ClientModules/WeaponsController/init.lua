local WeaponsController = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- === LOCAL VARIABLES
local player = Players.LocalPlayer
local WeaponsSystem

-- === LOCAL FUNCTIONS
local function disableNativeBackpack(): ()
	pcall(function(): ()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
end

local function ensureWeaponsSystem(): any
	local weaponsFolder = ReplicatedStorage:WaitForChild("WeaponsSystem")
	local module = require(weaponsFolder:WaitForChild("WeaponsSystem"))

	if not module.didSetup and not module.doingSetup then
		module.setup()
	end

	while module.doingSetup do
		task.wait()
	end

	while not module.camera do
		task.wait()
	end

	return module
end

local function updateCameraState(): ()
	if not WeaponsSystem then
		return
	end

	local gameOn = player:GetAttribute("GAME_ON") == true

	if WeaponsSystem.camera then
		WeaponsSystem.camera:setEnabled(gameOn)
	end

	if WeaponsSystem.gui then
		local shouldEnableGui = gameOn and WeaponsSystem.currentWeapon ~= nil
		WeaponsSystem.gui:setEnabled(shouldEnableGui)
	end
end

local function onCharacterAdded(character: Model): ()
	disableNativeBackpack()

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Seated:Connect(function(): ()
			task.defer(disableNativeBackpack)
		end)
	end
end

-- === GLOBAL FUNCTIONS
function WeaponsController:Init(): ()
	WeaponsSystem = ensureWeaponsSystem()

	disableNativeBackpack()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	player:GetAttributeChangedSignal("GAME_ON"):Connect(updateCameraState)
	WeaponsSystem.CurrentWeaponChanged.Event:Connect(updateCameraState)

	updateCameraState()
end

return WeaponsController
