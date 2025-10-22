local BackpackScreenController = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("UnitService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === MODULES
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local BackpackScreenWrapper = require(Players.LocalPlayer.PlayerScripts.ClientModules.BackpackScreenWrapper)
local PreviewController = require(Players.LocalPlayer.PlayerScripts.ClientModules.PreviewController)

-- === LOCAL VARIABLES
local Wrapper: BackpackScreenWrapper.BackpackScreenWrapper?
local RemoveAllButton: GuiButton?

-- === LOCAL FUNCTIONS
local function encode(unitType: string, unitName: string): string
	return `{unitType}/{unitName}`
end

local function decode(key: string): (string, string)
	local split = key:split("/")
	return split[1], split[2]
end

-- === METATABLE --- Redirect module missing methods to Wrapper
setmetatable(BackpackScreenController, {
	__index = function(_, key)
		return function(_, ...)
			return Wrapper[key](Wrapper, ...)
		end
	end,
})

-- === GLOBAL FUNCTIONS
function BackpackScreenController:Init(): ()
	BackpackScreenController:CreateReferences()
	BackpackScreenController:InitButtonListeners()
	BackpackScreenController:InitBridgeListener()
end

function BackpackScreenController:CreateReferences(): ()
	Wrapper = BackpackScreenWrapper.new(
		UIReferences:GetReference("BACKPACK_SCREEN"),
		UIReferences:GetReference("BACKPACK_ITEMS_CONTAINER"),
		UIReferences:GetReference("BACKPACK_CLOSE_BUTTON"),
		ReplicatedStorage.GUI.Backpack.ITEM
	)
	RemoveAllButton = UIReferences:GetReference("BACKPACK_REMOVE_ALL_BUTTON")
	Wrapper.OnOpen = function(): ()
		if not Wrapper.Items then
			BackpackScreenController:BuildScreen()
		end
	end
	Wrapper.OnClose = function(): ()
		PreviewController:Stop()
	end
end

function BackpackScreenController:InitButtonListeners(): ()
	Wrapper.OnItemActivated = function(key: string): ()
		local unitType, unitName = decode(key)
		PreviewController:Start(unitType, unitName)
	end
	RemoveAllButton.MouseButton1Click:Connect(function(): ()
		PreviewController:RemoveAllItems()
	end)
end

function BackpackScreenController:InitBridgeListener(): ()
	bridge:Connect(function(response: table): ()
		if typeof(response) ~= "table" then
			return
		end
		local action = response[actionIdentifier]
		if action == "ItemQuantityChanged" or action == "ItemAdded" then
			local unitName: string = response.UnitName
			local unitType: string = response.UnitType
			local amount: number = response.Amount
			Wrapper:SetItemQuantity(encode(unitType, unitName), amount)
		end
	end)
end

function BackpackScreenController:BuildScreen(): ()
	if Wrapper.Items then
		return
	end
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetAllUnits",
		data = {},
	})
	if typeof(result) ~= "table" then
		warn("BackpackScreenController: unexpected response while building screen.")
		return
	end
	local entries: { BackpackScreenWrapper.Entry } = {}
	for _, item in pairs(result) do
		table.insert(entries, {
			Key = encode(item.UnitType, item.UnitName),
			Amount = item.Amount,
		})
	end
	print("Entries:", entries)
	Wrapper:BuildItems(entries)
end

return BackpackScreenController
