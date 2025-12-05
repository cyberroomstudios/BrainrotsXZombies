local WeaponsBackpackScreenController = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
		print(`Activated weapon item: {key}`)
		local result = weaponsBridge:InvokeServerAsync({
			[actionIdentifier] = "TryEquip",
			data = {
				WeaponName = key,
			},
		})
		if typeof(result) ~= "table" then
			warn("WeaponsBackpackScreenController: unexpected response while trying to equip weapon.")
			return
		end
		if result[statusIdentifier] == Response.STATUS.ERROR then
			warn(`Failed to equip weapon {key}: {result[messageIdentifier]}`)
		else
			print(`Equipped weapon: {key}`)
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
end

return WeaponsBackpackScreenController
