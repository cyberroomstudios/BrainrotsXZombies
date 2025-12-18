local WeaponService = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local Response = require(ReplicatedStorage.Utility.Response)
local bridge = BridgeNet2.ReferenceBridge("WeaponService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === ENUMS
local Weapons = require(ReplicatedStorage.Enums.weapons)

-- === MODULES
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)

-- === STATE
local ToolsTemplatesFolder: Folder?

-- === HELPERS
local function getToolsTemplatesFolder(): Folder?
	if ToolsTemplatesFolder and ToolsTemplatesFolder.Parent then
		return ToolsTemplatesFolder
	end

	local developerFolder = ReplicatedStorage:FindFirstChild("developer")
	if not developerFolder then
		warn("WeaponService: developer folder not found in ReplicatedStorage")
		return nil
	end

	local weaponsFolder = developerFolder:FindFirstChild("weapons")
	if not weaponsFolder then
		warn("WeaponService: weapons folder not found in developer")
		return nil
	end

	ToolsTemplatesFolder = weaponsFolder
	return ToolsTemplatesFolder
end

-- === LOCAL FUNCTIONS
local function cleanupCharacterTools(player: Player): ()
	local character = player.Character
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end
	end
end

local function cleanupPlayerBackpackTools(player: Player): ()
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end
end

local function tryAutoEquipWeapon(player: Player): ()
	local equippedWeapon = PlayerDataHandler:Get(player, "equippedWeapon")
	if equippedWeapon then
		cleanupCharacterTools(player)
		cleanupPlayerBackpackTools(player)
		WeaponService:EquipTool(player, equippedWeapon)
	end
end

-- === GLOBAL FUNCTIONS
function WeaponService:Init(): ()
	WeaponService:InitBridgeListener()
	WeaponService:InitEquipObserver()
	WeaponService:InitCharacterAutoEquip()
end

function WeaponService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player: Player, data: table): table
		if data[actionIdentifier] == "GetAllWeapons" then
			return PlayerDataHandler:Get(player, "weapons")
		elseif data[actionIdentifier] == "GetEquipped" then
			return PlayerDataHandler:Get(player, "equippedWeapon")
		elseif data[actionIdentifier] == "TryEquip" then
			local weaponName = data.data.WeaponName
			if WeaponService:TryEquip(player, weaponName) then
				return {
					[statusIdentifier] = Response.STATUS.SUCCESS,
				}
			else
				return {
					[statusIdentifier] = Response.STATUS.ERROR,
					[messageIdentifier] = Response.MESSAGES.UNAVAILABLE_WEAPON,
				}
			end
		else
			return {
				[statusIdentifier] = Response.STATUS.ERROR,
				[messageIdentifier] = Response.MESSAGES.INVALID_ACTION,
			}
		end
	end
end

function WeaponService:Give(player: Player, weaponName: string): ()
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
		data = {
			WeaponName = weaponName,
		},
	})
end

function WeaponService:InitCharacterAutoEquip(): ()
	local function onPlayerAdded(player: Player): ()
		if player.Character then
			task.defer(tryAutoEquipWeapon, player)
		end
		player.CharacterAdded:Connect(function(character: Model): ()
			task.defer(tryAutoEquipWeapon, player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

function WeaponService:TryEquip(player: Player, weaponName: string): boolean
	local weapons: table = PlayerDataHandler:Get(player, "weapons")
	if not table.find(weapons, weaponName) then
		return false
	end
	PlayerDataHandler:Set(player, "equippedWeapon", weaponName)
	return true
end

function WeaponService:InitEquipObserver(): ()
	PlayerDataHandler:Observe("equippedWeapon", function(player: Player, key: string): ()
		cleanupCharacterTools(player)
		cleanupPlayerBackpackTools(player)
		local equippedWeapon = PlayerDataHandler:Get(player, "equippedWeapon")
		if equippedWeapon then
			WeaponService:EquipTool(player, equippedWeapon)
		end
	end)
end

function WeaponService:EquipTool(player: Player, weaponName: string): ()
	local character = player.Character
	if not character then
		return
	end

	-- Do not equip a Tool for the default "Fist" weapon
	if weaponName == Weapons.Fist.Name then
		return
	end

	-- Get weapon from cached templates folder (same pattern as units)
	local weapons = getToolsTemplatesFolder()
	if not weapons then
		return
	end

	local weaponTool = weapons:FindFirstChild(weaponName)
	if not weaponTool then
		warn(`WeaponService: Tool "{weaponName}" not found in ReplicatedStorage.developer.weapons`)
		return
	end

	local toolClone = weaponTool:Clone()
	-- Prevent default tool behavior, we drive activation ourselves
	toolClone.CanBeDropped = false
	pcall(function(): ()
		toolClone.ManualActivationOnly = true
	end)
	toolClone.Parent = character -- Equip directly to character so it shows in hand

	-- Notify clients
	bridge:Fire(player, {
		[actionIdentifier] = "ToolEquipped",
		data = {
			WeaponName = weaponName,
		},
	})
end

return WeaponService
