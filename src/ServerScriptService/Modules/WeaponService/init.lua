local UnitService = {}

-- === SERVICES
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("WeaponService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

-- === CONSTANTS
local WEAPON_TAG = "WeaponsSystemWeapon"
local EQUIPPED_ATTRIBUTE = "EQUIPPED_WEAPON"
local WEAPONS_FOLDER_NAME = "Weapons"

-- === LOCAL VARIABLES
local weaponsFolder = ServerStorage:FindFirstChild(WEAPONS_FOLDER_NAME)
local equippedWeapons: { [Player]: Tool? } = {}

-- === LOCAL FUNCTIONS
local function getWeaponsFolder(): Folder?
	if weaponsFolder and weaponsFolder.Parent then
		return weaponsFolder
	end

	local found = ServerStorage:FindFirstChild(WEAPONS_FOLDER_NAME)
	if found and found:IsA("Folder") then
		weaponsFolder = found
	else
		weaponsFolder = nil
	end

	return weaponsFolder
end

local function makeResponse(status: string, message: string?, extra: table?): table
	local response = {
		[statusIdentifier] = status,
		[messageIdentifier] = message,
	}

	if extra then
		for key, value in pairs(extra) do
			response[key] = value
		end
	end

	return response
end

local function playerOwnsWeapon(player: Player, weaponName: string): boolean
	local ownedWeapons = PlayerDataHandler:Get(player, "weapons")
	if typeof(ownedWeapons) ~= "table" then
		return false
	end

	for _, currentWeapon in ipairs(ownedWeapons) do
		if currentWeapon == weaponName then
			return true
		end
	end

	return false
end

local function setEquippedAttribute(player: Player, weaponName: string?): ()
	player:SetAttribute(EQUIPPED_ATTRIBUTE, weaponName or "")
end

local function isWeaponInstance(instance: Instance): boolean
	if not instance:IsA("Tool") then
		return false
	end

	if CollectionService:HasTag(instance, WEAPON_TAG) then
		return true
	end

	local folder = getWeaponsFolder()
	if folder and folder:FindFirstChild(instance.Name) then
		return true
	end

	return instance:FindFirstChild("WeaponType") ~= nil
end

local function cleanupTrackedWeapon(player: Player): ()
	local tracked = equippedWeapons[player]
	equippedWeapons[player] = nil

	if tracked then
		tracked:Destroy()
	end
end

local function cleanupWeaponInstances(player: Player, keep: Tool?): ()
	for _, container in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
		if not container then
			continue
		end

		for _, child in ipairs(container:GetChildren()) do
			if child == keep then
				continue
			end

			if isWeaponInstance(child) then
				child:Destroy()
			end
		end
	end
end

local function equipToolForPlayer(player: Player, tool: Tool): ()
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
		humanoid:EquipTool(tool)
	end
end

local function trackWeapon(player: Player, tool: Tool): ()
	equippedWeapons[player] = tool
	tool.AncestryChanged:Connect(function(_, parent)
		if parent == nil and equippedWeapons[player] == tool then
			equippedWeapons[player] = nil
			setEquippedAttribute(player, "")
		end
	end)
end

local function onCharacterAdded(player: Player)
	return function(_: Model): ()
		local equippedName = player:GetAttribute(EQUIPPED_ATTRIBUTE)
		if equippedName and equippedName ~= "" then
			UnitService:Equip(player, equippedName)
		else
			UnitService:Unequip(player)
		end
	end
end

local function onPlayerAdded(player: Player): ()
	setEquippedAttribute(player, player:GetAttribute(EQUIPPED_ATTRIBUTE))
	player.CharacterAdded:Connect(onCharacterAdded(player))
	player.CharacterRemoving:Connect(function(): ()
		cleanupTrackedWeapon(player)
	end)
end

-- === GLOBAL FUNCTIONS
function UnitService:Init(): ()
	UnitService:InitBridgeListener()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player): ()
		cleanupTrackedWeapon(player)
	end)
end

function UnitService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): table
		local action = data and data[actionIdentifier]
		if action == "GetAllWeapons" then
			return PlayerDataHandler:Get(player, "weapons")
		elseif action == "EquipWeapon" then
			local weaponName = data.data and data.data.WeaponName
			return UnitService:Equip(player, weaponName)
		elseif action == "UnequipWeapon" then
			return UnitService:Unequip(player)
		end

		return makeResponse("error", "Invalid action.")
	end
end

function UnitService:Give(player: Player, weaponName: string): ()
	PlayerDataHandler:Update(player, "weapons", function(current: table): table
		if table.find(current, weaponName) then
			warn(`Player {player.Name} already has weapon {weaponName}`)
			return current
		end
		table.insert(current, weaponName)
		return current
	end)

	bridge:Fire(player, {
		[actionIdentifier] = "WeaponAdded",
		WeaponName = weaponName,
	})
end

function UnitService:Equip(player: Player, weaponName: string?): table
	if typeof(weaponName) ~= "string" or weaponName == "" then
		return makeResponse("error", "Invalid weapon name.")
	end

	local folder = getWeaponsFolder()
	if not folder then
		return makeResponse("error", "Weapons folder not found in ServerStorage.")
	end

	if not playerOwnsWeapon(player, weaponName) then
		return makeResponse("error", "Player does not own this weapon.")
	end

	local template = folder:FindFirstChild(weaponName)
	if not template or not template:IsA("Tool") then
		return makeResponse("error", `Weapon "{weaponName}" not found.`)
	end

	local currentlyEquipped = equippedWeapons[player]
	if currentlyEquipped and currentlyEquipped.Parent and currentlyEquipped.Name == weaponName then
		cleanupWeaponInstances(player, currentlyEquipped)
		equipToolForPlayer(player, currentlyEquipped)
		setEquippedAttribute(player, weaponName)

		return makeResponse("success", "Weapon already equipped.", {
			EquippedWeapon = weaponName,
		})
	end

	cleanupTrackedWeapon(player)
	cleanupWeaponInstances(player)

	local tool = template:Clone()
	tool.CanBeDropped = false
	CollectionService:AddTag(tool, WEAPON_TAG)

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		tool:Destroy()
		return makeResponse("error", "Backpack not found.")
	end

	tool.Parent = backpack
	trackWeapon(player, tool)
	equipToolForPlayer(player, tool)
	setEquippedAttribute(player, weaponName)

	return makeResponse("success", "Weapon equipped.", {
		EquippedWeapon = weaponName,
	})
end

function UnitService:Unequip(player: Player): table
	cleanupTrackedWeapon(player)
	cleanupWeaponInstances(player)
	setEquippedAttribute(player, "")

	return makeResponse("success", "Weapon unequipped.", {
		EquippedWeapon = "",
	})
end

return UnitService
