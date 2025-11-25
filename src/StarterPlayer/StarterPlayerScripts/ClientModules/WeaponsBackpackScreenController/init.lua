local WeaponsBackpackScreenController = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local weaponsBridge = BridgeNet2.ReferenceBridge("WeaponService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local BackpackScreenWrapper = require(Players.LocalPlayer.PlayerScripts.ClientModules.BackpackScreenWrapper)
local Tags = require(ReplicatedStorage.Enums.Tags)

-- === LOCAL VARIABLES
local Wrapper: BackpackScreenWrapper.BackpackScreenWrapper?
local equippedWeapon: string?
local EQUIPPED_ATTRIBUTE = "EQUIPPED_WEAPON"

-- === LOCAL FUNCTIONS
local function normalizeEquipped(value: any): string?
	if typeof(value) ~= "string" then
		return nil
	end

	if value == "" then
		return nil
	end

	return value
end

local function updateEquippedWeapon(newValue: string?): ()
	equippedWeapon = newValue
	if Wrapper then
		WeaponsBackpackScreenController:RefreshEquippedVisual()
	end
end

local function syncEquippedFromAttribute(): ()
	updateEquippedWeapon(normalizeEquipped(player:GetAttribute(EQUIPPED_ATTRIBUTE)))
end

local function invokeWeaponAction(action: string, weaponName: string): ()
	local success, response = pcall(function(): any
		return weaponsBridge:InvokeServerAsync({
			[actionIdentifier] = action,
			data = {
				WeaponName = weaponName,
			},
		})
	end)

	if not success then
		warn(`WeaponsBackpackScreenController: failed to invoke {action}: {response}`)
		return
	end

	if typeof(response) ~= "table" then
		return
	end

	if response[statusIdentifier] == "error" then
		warn(response[messageIdentifier] or `WeaponsBackpackScreenController: {action} failed`)
		return
	end

	if response.EquippedWeapon ~= nil then
		updateEquippedWeapon(normalizeEquipped(response.EquippedWeapon))
	end
end

-- === METATABLE --- Redirect module missing methods to Wrapper
setmetatable(WeaponsBackpackScreenController, {
	__index = function(_, key)
		return function(_, ...)
			return Wrapper[key](Wrapper, ...)
		end
	end,
})

-- === GLOBAL FUNCTIONS
function WeaponsBackpackScreenController:Init(): ()
	WeaponsBackpackScreenController:CreateReferences()
	WeaponsBackpackScreenController:InitButtonListeners()
	WeaponsBackpackScreenController:InitBridgeListener()
	player:GetAttributeChangedSignal(EQUIPPED_ATTRIBUTE):Connect(syncEquippedFromAttribute)
	syncEquippedFromAttribute()
end

function WeaponsBackpackScreenController:CreateReferences(): ()
	Wrapper = BackpackScreenWrapper.new(
		UIReferences:GetReference(Tags.WEAPONS_BACKPACK_SCREEN),
		UIReferences:GetReference(Tags.WEAPONS_BACKPACK_ITEMS_CONTAINER),
		UIReferences:GetReference(Tags.WEAPONS_BACKPACK_CLOSE_BUTTON),
		ReplicatedStorage.GUI.Backpack.ITEM
	)
	Wrapper.OnOpen = function(): ()
		if not Wrapper.Items then
			WeaponsBackpackScreenController:BuildScreen()
		end
		-- TODO start weapon preview
	end
	Wrapper.OnClose = function(): ()
		-- TODO stop weapon preview
	end
end

function WeaponsBackpackScreenController:InitButtonListeners(): ()
	Wrapper.OnItemActivated = function(key: string): ()
		if equippedWeapon == key then
			invokeWeaponAction("UnequipWeapon", key)
		else
			invokeWeaponAction("EquipWeapon", key)
		end
	end
end

function WeaponsBackpackScreenController:InitBridgeListener(): ()
	weaponsBridge:Connect(function(response: table): ()
		if typeof(response) ~= "table" then
			return
		end
		local action = response[actionIdentifier]
		if action == "WeaponAdded" then
			Wrapper:SetItemQuantity(response.WeaponName)
			WeaponsBackpackScreenController:RefreshEquippedVisual()
		end
	end)
end

function WeaponsBackpackScreenController:BuildScreen(): ()
	if Wrapper.Items then
		return
	end
	local result = weaponsBridge:InvokeServerAsync({
		[actionIdentifier] = "GetAllWeapons",
		data = {},
	})
	if typeof(result) ~= "table" then
		warn("WeaponsBackpackScreenController: unexpected response while building screen.")
		return
	end
	local entries = {}
	for _, weaponKey in pairs(result) do
		table.insert(entries, { Key = weaponKey })
	end
	Wrapper:BuildItems(entries)
	WeaponsBackpackScreenController:RefreshEquippedVisual()
end

function WeaponsBackpackScreenController:RefreshEquippedVisual(): ()
	if not Wrapper or not Wrapper.Items then
		return
	end

	for key in pairs(Wrapper.Items) do
		local label = key == equippedWeapon and "Equipped" or ""
		Wrapper:SetItemQuantityText(key, label)
	end
end

return WeaponsBackpackScreenController
