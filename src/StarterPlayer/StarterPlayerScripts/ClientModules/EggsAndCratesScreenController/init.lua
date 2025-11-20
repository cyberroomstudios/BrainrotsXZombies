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

		-- Rely on server `TimePassed` events to update countdown timers (no client thread)
	end
	Wrapper.OnClose = function(): ()
		-- Stop the update timer when screen closes
		-- Nothing to cancel; server pushes updates via TimePassed events
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

		local action = response[actionIdentifier]
		print(`[EggsAndCratesScreenController] Received bridge action: {action}`)

		if not Wrapper or not Wrapper.Items then
			print(`[EggsAndCratesScreenController] Screen not built yet, will build on next open`)
			return
		end

		-- Server pushes periodic TimePassed events with current egg data for this player
		if action == "TimePassed" then
			local eggs = response.eggs
			if typeof(eggs) ~= "table" then
				return
			end

			for _, eggEntry in ipairs(eggs) do
				if typeof(eggEntry) == "table" and eggEntry.UnitName and eggEntry.slotIndex then
					local uniqueKey = string.format("%s_Slot%d", eggEntry.UnitName, eggEntry.slotIndex)
					local currentTime = DateTime.now().UnixTimestamp
					local timeRemaining = math.max(0, (eggEntry.HatchTimestamp or 0) - currentTime)
					local isHatched = eggEntry.IsHatched or timeRemaining <= 0

					local timeDisplay
					if isHatched then
						timeDisplay = "Ready!"
					else
						local minutes = math.floor(timeRemaining / 60)
						local seconds = math.floor(timeRemaining % 60)
						timeDisplay = string.format("%d:%02d", minutes, seconds)
					end

					if Wrapper.Items[uniqueKey] then
						Wrapper:SetItemQuantityText(uniqueKey, timeDisplay)
					else
						Wrapper:CreateItem(uniqueKey)
						Wrapper:SetItemQuantityText(uniqueKey, timeDisplay)
					end
				end
			end

			return
		end

		local slotIndex = response.slotIndex
		local eggData = response.eggData

		if action == "EggAdded" or action == "EggHatched" then
			if not eggData or not eggData.UnitName or not slotIndex then
				warn(`[EggsAndCratesScreenController] Missing egg data in {action} event`)
				return
			end

			local uniqueKey = string.format("%s_Slot%d", eggData.UnitName, slotIndex)
			local currentTime = DateTime.now().UnixTimestamp
			local timeRemaining = math.max(0, eggData.HatchTimestamp - currentTime)
			local isHatched = timeRemaining <= 0

			local timeDisplay
			if isHatched then
				timeDisplay = "Ready!"
			else
				local minutes = math.floor(timeRemaining / 60)
				local seconds = math.floor(timeRemaining % 60)
				timeDisplay = string.format("%d:%02d", minutes, seconds)
			end

			if Wrapper.Items[uniqueKey] then
				-- Update existing item
				print(`[EggsAndCratesScreenController] Updating egg {uniqueKey}`)
				Wrapper:SetItemQuantityText(uniqueKey, timeDisplay)
			else
				-- Create new item
				print(`[EggsAndCratesScreenController] Adding new egg {uniqueKey}`)
				Wrapper:CreateItem(uniqueKey)
				Wrapper:SetItemQuantityText(uniqueKey, timeDisplay)
			end
		elseif action == "EggCollected" then
			if not eggData or not eggData.UnitName or not slotIndex then
				warn(`[EggsAndCratesScreenController] Missing egg data in EggCollected event`)
				return
			end

			local uniqueKey = string.format("%s_Slot%d", eggData.UnitName, slotIndex)
			print(`[EggsAndCratesScreenController] Removing collected egg {uniqueKey}`)
			Wrapper:RemoveItem(uniqueKey)
		end
	end)
end

function EggsAndCratesScreenController:BuildScreen(): ()
	if Wrapper.Items then
		print("[EggsAndCratesScreenController] Screen already built, skipping")
		return
	end

	print("[EggsAndCratesScreenController] Building screen...")
	local result = bridge:InvokeServerAsync({
		[actionIdentifier] = "GetEggs",
	})

	if typeof(result) ~= "table" then
		warn("EggsAndCratesScreenController: unexpected response while building screen.")
		return
	end

	print(`[EggsAndCratesScreenController] Received {#result} egg slots from server`)

	-- Result is an array of egg slots (3 slots by default)
	-- Each slot is either an empty table {} or an EggBackpackEntry with UnitName, CreatedTimestamp, HatchTimestamp
	local entries: { BackpackScreenWrapper.Entry } = {}

	for slotIndex, eggData in ipairs(result) do
		-- Check if the slot has an egg (not an empty table)
		if typeof(eggData) == "table" and eggData.UnitName then
			-- Calculate time remaining until hatch
			local currentTime = DateTime.now().UnixTimestamp
			local timeRemaining = math.max(0, eggData.HatchTimestamp - currentTime)
			local isHatched = timeRemaining <= 0

			-- Format time display for quantity label
			local timeDisplay
			if isHatched then
				timeDisplay = "Ready!"
			else
				local minutes = math.floor(timeRemaining / 60)
				local seconds = math.floor(timeRemaining % 60)
				timeDisplay = string.format("%d:%02d", minutes, seconds)
			end

			-- Use a unique key that includes slot index to handle multiple eggs of the same type
			local uniqueKey = string.format("%s_Slot%d", eggData.UnitName, slotIndex)
			table.insert(entries, {
				Key = uniqueKey,
				Amount = nil, -- No numeric amount for eggs
			})
			-- Store the time display to set after building
			entries[#entries].TimeDisplay = timeDisplay
		end
	end

	if #entries == 0 then
		print("[EggsAndCratesScreenController] No eggs in backpack.")
		-- Still build the screen, just with no items
	else
		print(`[EggsAndCratesScreenController] Building {#entries} egg entries`)
	end

	Wrapper:BuildItems(entries)

	-- Set the time display text for each entry
	for _, entry in ipairs(entries) do
		if entry.TimeDisplay then
			Wrapper:SetItemQuantityText(entry.Key, entry.TimeDisplay)
		end
	end

	print("[EggsAndCratesScreenController] Screen built successfully")
end

return EggsAndCratesScreenController
