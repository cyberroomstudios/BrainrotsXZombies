local EggsAndCratesScreenController = {}

-- === SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("BrainrotEggService")
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
setmetatable(EggsAndCratesScreenController, {
	__index = function(_, key)
		return function(_, ...)
			return Wrapper[key](Wrapper, ...)
		end
	end,
})

-- === GLOBAL FUNCTIONS
function EggsAndCratesScreenController:Init(): ()
	EggsAndCratesScreenController:CreateReferences()
	EggsAndCratesScreenController:InitButtonListeners()
	EggsAndCratesScreenController:InitBridgeListener()
end

function EggsAndCratesScreenController:CreateReferences(): ()
	local screen = UIReferences:GetReference(Tags.EGGS_AND_CRATES_SCREEN)
	local itemsContainer = UIReferences:GetReference(Tags.EGGS_AND_CRATES_ITEMS_CONTAINER)
	local closeButton = UIReferences:GetReference(Tags.EGGS_AND_CRATES_CLOSE_BUTTON)

	if not screen or not itemsContainer or not closeButton then
		print("EggsAndCratesScreenController: Not implemented - missing UI references for BackpackScreenWrapper.")
		return
	end

	Wrapper = BackpackScreenWrapper.new(screen, itemsContainer, closeButton, ReplicatedStorage.GUI.Backpack.ITEM)
	Wrapper.OnOpen = function(): ()
		if not Wrapper.Items then
			EggsAndCratesScreenController:BuildScreen()
		end
		print("EggsAndCratesScreenController: Not implemented - custom OnOpen behaviour.")
	end
	Wrapper.OnClose = function(): ()
		print("EggsAndCratesScreenController: Not implemented - custom OnClose behaviour.")
	end
end

function EggsAndCratesScreenController:InitButtonListeners(): ()
	Wrapper.OnItemActivated = function(key: string): ()
		print(`EggsAndCratesScreenController: Not implemented - item activation for {key}.`)
	end
end

function EggsAndCratesScreenController:InitBridgeListener(): ()
	bridge:Connect(function(response: table): ()
		if typeof(response) ~= "table" then
			return
		end
		print("EggsAndCratesScreenController: Not implemented - bridge listener update.", response)
	end)
end

function EggsAndCratesScreenController:BuildScreen(): ()
	if Wrapper.Items then
		return
	end

	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetEggs",
	})

	if typeof(result) ~= "table" then
		warn("EggsAndCratesScreenController: unexpected response while building screen.")
		return
	end

	local entries: { BackpackScreenWrapper.Entry } = {}
	if #result > 0 then
		for _, item in ipairs(result) do
			if typeof(item) == "table" then
				local key = item.Key or item.Name or item.Id or item.ID
				if typeof(key) == "string" then
					local amount = item.Amount or item.Quantity
					table.insert(entries, {
						Key = key,
						Amount = typeof(amount) == "number" and amount or nil,
					})
				end
			elseif typeof(item) == "string" then
				table.insert(entries, { Key = item })
			end
		end
	else
		for key, amount in pairs(result) do
			if typeof(key) == "string" then
				local quantity = nil
				if typeof(amount) == "number" then
					quantity = amount
				elseif typeof(amount) == "table" then
					local maybeAmount = amount.Amount or amount.Quantity
					if typeof(maybeAmount) == "number" then
						quantity = maybeAmount
					end
				end
				table.insert(entries, {
					Key = key,
					Amount = quantity,
				})
			end
		end
	end

	if #entries == 0 then
		print("EggsAndCratesScreenController: Not implemented - map egg data into backpack entries.")
		return
	end

	Wrapper:BuildItems(entries)
end

return EggsAndCratesScreenController
