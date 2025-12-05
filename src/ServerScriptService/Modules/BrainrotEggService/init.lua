local BrainrotEggService = {}

-- === SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- === CUSTOM TYPES
type EggBackpackEntry = {
	UnitName: string,
	CreatedTimestamp: number,
	HatchTimestamp: number,
}

-- === MODULES
local BaseService = require(ServerScriptService.Modules.BaseService)
local BrainrotEggBillboardGui = require(script.BrainrotEggBillboardGui)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local UnitService = require(ServerScriptService.Modules.UnitService)
-- Init Bridge Net
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local Response = require(Utility.Response)
local bridge = BridgeNet2.ReferenceBridge("BrainrotEggService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === ENUMS
local BrainrotEgg = require(ReplicatedStorage.Enums.brainrotEgg)

-- === LOCAL VARIABLES
local EggModelsByPlayer: {
	[Player]: {
		[number]: {
			Model: Model,
			BillboardGui: typeof(BrainrotEggBillboardGui.new(({} :: any) :: BasePart, Vector3.zero, "")),
			Entry: EggBackpackEntry,
			AttachPart: BasePart?,
			IsHatched: boolean?,
		},
	},
} =
	{}
local LastHatchCheckTime: number = 0
local HATCH_CHECK_INTERVAL: number = 1 -- Check every 1 second

-- === GLOBAL FUNCTIONS
function BrainrotEggService:Init(): ()
	BrainrotEggService:InitBridgeListener()
	BrainrotEggService:StartHatchingLoop()

	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player: Player): ()
		if EggModelsByPlayer[player] then
			EggModelsByPlayer[player] = nil
		end
	end)
end

function BrainrotEggService:InitBridgeListener(): ()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "GetEggs" then
			return BrainrotEggService:GetEggs(player)
		else
			return {
				[statusIdentifier] = Response.STATUS.ERROR,
				[messageIdentifier] = Response.MESSAGES.INVALID_ACTION,
			}
		end
	end
end

function BrainrotEggService:TryGiveEgg(player: Player, brainrotEggName: string): boolean
	assert(player, "Player is required")
	assert(brainrotEggName, "Brainrot Egg name is required")
	assert(BrainrotEgg[brainrotEggName], "Brainrot Egg must exist in BrainrotEgg enum")

	local success: boolean = false
	local addedSlotIndex: number? = nil
	local addedEgg: EggBackpackEntry? = nil
	PlayerDataHandler:Update(
		player,
		"brainrotEggsBackpack",
		function(current: { [string]: number }): { [string]: number }
			for idx, value in ipairs(current) do
				if next(value) == nil then -- Slot is available!
					value.UnitName = brainrotEggName
					value.CreatedTimestamp = DateTime.now().UnixTimestamp
					value.HatchTimestamp = value.CreatedTimestamp + BrainrotEgg[brainrotEggName].TimeToHatch
					success = true
					addedSlotIndex = idx
					addedEgg = value
					BrainrotEggService:SetEggOnMap(player, idx, value)
					return current
				end
			end
			warn(`No available slot for brainrot egg {brainrotEggName} for player {player.Name}`)
			return current
		end
	)

	-- Notify client about the new egg
	if success and addedSlotIndex and addedEgg then
		print(`[BrainrotEggService] Firing EggAdded bridge event to player {player.Name}`)
		bridge:Fire(player, {
			[actionIdentifier] = "EggAdded",
			[statusIdentifier] = Response.STATUS.SUCCESS,
			[messageIdentifier] = Response.MESSAGES.EGG_ADDED,
			slotIndex = addedSlotIndex,
			eggData = addedEgg,
		})
	else
		print(`[BrainrotEggService] Failed to add egg {brainrotEggName} for player {player.Name}`)
	end

	return success
end

function BrainrotEggService:GetEggs(player: Player): { EggBackpackEntry }
	return PlayerDataHandler:Get(player, "brainrotEggsBackpack")
end

function BrainrotEggService:SetEggOnMap(player: Player, slotIndex: number, egg: EggBackpackEntry): ()
	local base = BaseService:GetBase(player):WaitForChild("baseTemplate")
	local platforms = base and base:WaitForChild("platforms") or nil
	local eggsPlatform = platforms and platforms:FindFirstChild("egg") or nil
	if eggsPlatform then
		local eggPlatform: Model = eggsPlatform:FindFirstChild(tostring(slotIndex))
		if eggPlatform then
			local eggClone: Model = ReplicatedStorage.developer.brainrotEggs:FindFirstChild(egg.UnitName):Clone()
			if not eggClone then
				warn(`Egg model {egg.UnitName} not found in ReplicatedStorage.developer.brainrotEggs`)
				return
			end

			eggClone.Parent = eggPlatform
			local _, eggSize = eggClone:GetBoundingBox()
			eggClone:PivotTo(eggPlatform.PrimaryPart.CFrame + 0.5 * eggSize.Y * Vector3.yAxis)

			print(`[BrainrotEggService] Setting egg {egg.UnitName} on map for player {player.Name} in slot {slotIndex}`)

			-- Create BillboardGui to show hatching progress
			-- Find the best part to attach the BillboardGui to
			local attachPart = eggClone.PrimaryPart or eggClone:FindFirstChildWhichIsA("BasePart")
			if not attachPart then
				warn(`No valid part found in egg model {egg.UnitName} to attach BillboardGui`)
				return
			end

			-- Create the BillboardGui using the modularized component
			local billboardGui = BrainrotEggBillboardGui.new(attachPart, eggSize, egg.UnitName)
			print(`[BrainrotEggService] Created BillboardGui for egg {egg.UnitName}`)

			-- Store reference to egg model and billboard
			if not EggModelsByPlayer[player] then
				EggModelsByPlayer[player] = {}
			end
			EggModelsByPlayer[player][slotIndex] = {
				Model = eggClone,
				BillboardGui = billboardGui,
				Entry = egg,
				AttachPart = attachPart,
			}

			-- Check if egg is already hatched
			local currentTime = DateTime.now().UnixTimestamp
			print(`[BrainrotEggService] Current time: {currentTime}, Hatch time: {egg.HatchTimestamp}`)
			if currentTime >= egg.HatchTimestamp then
				print(`[BrainrotEggService] Egg {egg.UnitName} is already hatched, marking as hatched`)
				BrainrotEggService:MarkEggAsHatched(player, slotIndex)
			else
				local timeRemaining = egg.HatchTimestamp - currentTime
				print(`[BrainrotEggService] Egg {egg.UnitName} will hatch in {timeRemaining} seconds`)
			end
		else
			warn(`Egg platform for slot {slotIndex} not found in base for player {player.Name}`)
		end
	else
		warn(`Eggs platform not found in base for player {player.Name}`)
	end
end

function BrainrotEggService:InitEggsForPlayer(player: Player): ()
	local eggsBackpack: { EggBackpackEntry } = BrainrotEggService:GetEggs(player)
	for slotIndex, egg in ipairs(eggsBackpack) do
		if next(egg) ~= nil then
			BrainrotEggService:SetEggOnMap(player, slotIndex, egg)
		end
	end
end

function BrainrotEggService:MarkEggAsHatched(player: Player, slotIndex: number): ()
	print(`[BrainrotEggService] MarkEggAsHatched called for player {player.Name}, slot {slotIndex}`)

	local eggData = EggModelsByPlayer[player] and EggModelsByPlayer[player][slotIndex]
	if not eggData then
		warn(`[BrainrotEggService] No egg data found for player {player.Name} in slot {slotIndex}`)
		return
	end

	-- Prevent duplicate hatching
	if eggData.IsHatched then
		print(`[BrainrotEggService] Egg already marked as hatched for player {player.Name} in slot {slotIndex}`)
		return
	end

	local eggModel = eggData.Model
	local billboardGui = eggData.BillboardGui
	local egg = eggData.Entry

	if not eggModel or not billboardGui or not egg then
		warn(`[BrainrotEggService] Invalid egg data for player {player.Name} in slot {slotIndex}`)
		return
	end

	-- Mark as hatched to prevent duplicate processing
	eggData.IsHatched = true

	-- Update BillboardGui to show "Ready to Collect"
	billboardGui:SetHatched()

	-- Notify client that the egg has hatched
	print(`[BrainrotEggService] Firing EggHatched bridge event to player {player.Name}`)
	bridge:Fire(player, {
		[actionIdentifier] = "EggHatched",
		[statusIdentifier] = Response.STATUS.SUCCESS,
		[messageIdentifier] = Response.MESSAGES.EGG_HATCHED,
		slotIndex = slotIndex,
		eggData = egg,
	})

	-- Add visual effect (glow or sparkle)
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 255, 0)
	sparkles.Parent = eggModel.PrimaryPart

	-- Add ProximityPrompt for collection (only for owner player)
	local attachPart = eggData.AttachPart or eggModel.PrimaryPart or eggModel:FindFirstChildWhichIsA("BasePart")
	if not attachPart then
		warn(`No valid part found in egg model {egg.UnitName} to attach ProximityPrompt`)
		return
	end

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "CollectEgg"
	proximityPrompt.ActionText = "Collect Unit"
	proximityPrompt.ObjectText = BrainrotEgg[egg.UnitName].Name
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = attachPart

	print(`[BrainrotEggService] Created ProximityPrompt for egg {egg.UnitName} on part {attachPart.Name}`)

	-- Connect the prompt trigger
	proximityPrompt.Triggered:Connect(function(triggeringPlayer: Player): ()
		-- Only the owner can collect
		if triggeringPlayer ~= player then
			return
		end

		-- Give the unit to the player
		local unitType = BrainrotEgg[egg.UnitName].Type:upper()
		UnitService:Give(player, egg.UnitName, unitType, 1)

		-- Remove egg from backpack
		PlayerDataHandler:Update(
			player,
			"brainrotEggsBackpack",
			function(current: { [string]: number }): { [string]: number }
				if current[slotIndex] then
					current[slotIndex] = {}
				end
				return current
			end
		)

		-- Clean up the egg model and BillboardGui
		if billboardGui then
			billboardGui:Destroy()
		end

		if EggModelsByPlayer[player] then
			EggModelsByPlayer[player][slotIndex] = nil
		end
		eggModel:Destroy()

		print(`[BrainrotEggService] Player {player.Name} collected hatched egg: {egg.UnitName}`)

		-- Notify client to update the UI
		bridge:Fire(player, {
			[actionIdentifier] = "EggCollected",
			[statusIdentifier] = Response.STATUS.SUCCESS,
			[messageIdentifier] = Response.MESSAGES.EGG_COLLECTED,
			slotIndex = slotIndex,
			eggData = egg,
		})
	end)
end

function BrainrotEggService:UpdateHatchingProgress(): ()
	local currentTime = DateTime.now().UnixTimestamp

	for player, eggs in pairs(EggModelsByPlayer) do
		local eggsForPlayer = {}
		for slotIndex, eggData in pairs(eggs) do
			local egg = eggData.Entry
			-- Collect egg info to send to client (include hatched state)
			table.insert(eggsForPlayer, {
				slotIndex = slotIndex,
				UnitName = egg and egg.UnitName or nil,
				CreatedTimestamp = egg and egg.CreatedTimestamp or nil,
				HatchTimestamp = egg and egg.HatchTimestamp or nil,
				IsHatched = eggData.IsHatched and true or false,
			})

			-- Skip if already hatched for progress update
			if eggData.IsHatched then
				continue
			end

			local billboardGui = eggData.BillboardGui

			-- Check if egg has hatched
			if currentTime >= egg.HatchTimestamp then
				BrainrotEggService:MarkEggAsHatched(player, slotIndex)
			else
				-- Update progress bar and time remaining
				local totalTime = egg.HatchTimestamp - egg.CreatedTimestamp
				local elapsedTime = currentTime - egg.CreatedTimestamp
				local progress = elapsedTime / totalTime
				local timeRemaining = egg.HatchTimestamp - currentTime

				-- Use the modularized BillboardGui to update progress
				if billboardGui then
					billboardGui:UpdateProgress(progress, timeRemaining)
				end
			end
		end

		-- Send TimePassed event with all eggs data for this player (client will update UI)
		bridge:Fire(player, {
			[actionIdentifier] = "TimePassed",
			eggs = eggsForPlayer,
			currentTime = currentTime,
		})
	end
end

function BrainrotEggService:StartHatchingLoop(): ()
	RunService.Heartbeat:Connect(function(): ()
		local currentTime = os.clock()
		if currentTime - LastHatchCheckTime >= HATCH_CHECK_INTERVAL then
			LastHatchCheckTime = currentTime
			BrainrotEggService:UpdateHatchingProgress()
		end
	end)
end

return BrainrotEggService
