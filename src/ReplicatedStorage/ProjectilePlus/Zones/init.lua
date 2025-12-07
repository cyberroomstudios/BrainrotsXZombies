-- Zone Module by azavier123

-- This Zones is made to be immensely reliable, using nothing but simple math and boolean logic to dictate zone entry and exits

-- There are no calls/connections to any functions such as GetPartsInPart, Touched, or anything like that.

-- FilterAxis does an infinite bound check along the specified LOCAL AXIS of the ZoneHitbox.

-- To create the zone, you can either use a Part or a table with a CFrame, Size, and Shape. Supports any Shape.

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local PartContainsPoint = require(script:WaitForChild("PartContainsPoint"))

export type Region = { CFrame: CFrame, Size: Vector3, Shape: Enum.PartType }

export type HasPosition = { CFrame: { Position: Vector3 } } | { Position: Vector3 }

type filterAxisType = "X" | "Y" | "Z"

local rootParts = {} -- an array which is continuously updated to contain every character's HumanoidRootPart in the game

for _, plr in pairs(Players:GetPlayers()) do
	local chr = plr.Character or plr.CharacterAdded:Wait()

	rootParts[plr] = chr:WaitForChild("HumanoidRootPart")
end

game.Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(chr)
		rootParts[plr] = chr:WaitForChild("HumanoidRootPart")
	end)

	plr.CharacterRemoving:Connect(function(chr)
		rootParts[plr] = nil
	end)
end)

local Zones = {}

-- Position zones use the "Position" of their targets, so it works with things like cameras. <br>
--
-- Put all targets of the zone in the "Targets" array.
-- | The only requirement is that the target has a CFrame.
-- | For example, a lua table which constantly has it's CFrame updated is a valid target.
--
function Zones.positionZone(ZoneHitbox: Part | Region)
	local zone = {}

	-- fires when a target enters the zone, supplying the target that did that (override this)
	zone.Entered = nil :: ((entered: Instance) -> ())?

	-- fires when a target exits the zone, supplying the target that did that (override this)
	zone.Exited = nil :: ((exited: Instance) -> ())?

	-- the list of targets this zone affects
	zone.Targets = {} :: { HasCFrame }

	-- what axis, if any, to do an infinite bound check along
	zone.FilterAxis = nil :: filterAxisType?

	local isEntered = {}

	local con = RunService.Heartbeat:Connect(function()
		if not zone.Targets then
			isEntered = {}
			return
		end
		if #zone.Targets == 0 then
			return
		end

		local zoneShape, zoneCFrame, zoneSize = ZoneHitbox.Shape, ZoneHitbox.CFrame, ZoneHitbox.Size

		local targetsInZone = {}

		for _, target in pairs(zone.Targets) do
			local pos = target.CFrame and target.CFrame.Position or target.Position
			assert(
				pos and typeof(pos) == "Vector3",
				"Targets must have a Position or a CFrame.Position property as a Vector3."
			)

			if not PartContainsPoint(zoneShape, zoneCFrame, zoneSize, pos, zone.FilterAxis) then
				continue
			end

			targetsInZone[target] = true

			if isEntered[target] then
				continue
			end

			isEntered[target] = true

			if not zone.Entered then
				continue
			end

			zone.Entered(target)
		end

		local toRemove = {}

		for target in pairs(isEntered) do
			if targetsInZone[target] then
				continue
			end

			table.insert(toRemove, target)

			if not zone.Exited then
				continue
			end

			zone.Exited(target)
		end

		for _, target in ipairs(toRemove) do
			isEntered[target] = nil
		end
	end)

	-- Disconnects the connection to the heartbeat which the zone listens for
	function zone:Destroy()
		con:Disconnect()
	end

	return zone
end

-- Player zones use the position of any given players HumanoidRootPart to determine when they enter/exit the zone
--
function Zones.playerZone(ZoneHitbox: Part | Region)
	local zone = {}

	-- fires when a target enters the zone, supplying the target that did that (override this)
	zone.Entered = nil :: ((plrEntered: Player) -> ())?

	-- fires when a target exits the zone, supplying the target that did that (override this)
	zone.Exited = nil :: ((plrExited: Player) -> ())?

	-- what axis, if any, to do an infinite bound check along
	zone.FilterAxis = nil :: filterAxisType?

	local isEntered = {}

	local con = RunService.Heartbeat:Connect(function()
		local zoneShape, zoneCFrame, zoneSize = ZoneHitbox.Shape, ZoneHitbox.CFrame, ZoneHitbox.Size

		local playersInZone = {}

		for _, plr in pairs(Players:GetPlayers()) do
			local hrp = rootParts[plr]

			if not hrp then
				continue
			end

			if not PartContainsPoint(zoneShape, zoneCFrame, zoneSize, hrp.Position, zone.FilterAxis) then
				continue
			end

			local UserId = plr.UserId

			playersInZone[UserId] = true

			if isEntered[UserId] then
				continue
			end

			isEntered[UserId] = plr

			if not zone.Entered then
				continue
			end

			zone.Entered(plr)
		end

		local toRemove = {}

		for UserId, plr in pairs(isEntered) do
			if playersInZone[UserId] then
				continue
			end

			table.insert(toRemove, UserId)

			if not zone.Exited then
				continue
			end

			zone.Exited(plr)
		end

		for _, UserId in ipairs(toRemove) do
			isEntered[UserId] = nil
		end
	end)

	function zone:Destroy()
		con:Disconnect()
	end

	return zone
end

return Zones
