local MapService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local UtilService = require(ServerScriptService.Modules.UtilService)
local PlayerDataHandler = require(ServerScriptService.Modules.Player.PlayerDataHandler)
local BaseService = require(ServerScriptService.Modules.BaseService)

function MapService:Init() end

function MapService:AddItemInDataBase(player: Player, itemType: string, itemName: string, slot: string, subSlot: string)
	local itemOnMapId = PlayerDataHandler:Get(player, "itemOnMapId")
	local data = {
		Id = itemOnMapId + 1,
		Type = itemType,
		Name = itemName,
		Slot = slot,
		SubSlot = subSlot,
	}

	PlayerDataHandler:Set(player, "itemOnMapId", itemOnMapId + 1)

	PlayerDataHandler:Update(player, "itemsOnMap", function(current)
		table.insert(current, data)
		return current
	end)
end

function MapService:GetItemFromTypeAndName(unitType: string, unitName: string)
	local unitsFolder = ReplicatedStorage.developer.units
	local items = {
		["BLOCK"] = unitsFolder.blocks,
		["MELEE"] = unitsFolder.melee,
		["RANGED"] = unitsFolder.ranged,
		["TRAP"] = unitsFolder.trap,
	}

	if items[unitType] then
		local item = items[unitType]:FindFirstChild(unitName)

		if item then
			return item:Clone()
		end
	end
end

function MapService:SetItemOnMap(player: Player, unitType: string, unitName: string, slot: number, subSlot: number)
	local function lookAt(model: Model, targetPos: Vector3) end

	local base = BaseService:GetBase(player)
	local initBaserefPosition = BaseService:GetInitBaseRefPosition(player)
	if base then
		local baseTemplate = base.baseTemplate

		local baseTemplate = UtilService:WaitForDescendants(base, "baseTemplate")

		local baseSlots = UtilService:WaitForDescendants(baseTemplate, "baseSlots")

		local slots = UtilService:WaitForDescendants(baseSlots, "slots")

		local slotModel = UtilService:WaitForDescendants(slots, slot)

		local subSlotPart = UtilService:WaitForDescendants(slotModel, subSlot)

		local position = subSlotPart.Position
		local item = MapService:GetItemFromTypeAndName(unitType, unitName)
		local yOffset = (subSlotPart.Size.Y / 2) + (item.PrimaryPart.Size.Y / 2)

		local baseIndex = tonumber(base.Name)
		local rotation = CFrame.Angles(0, (baseIndex % 2 == 0 and 0 or math.rad(180)), 0)

		item:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, yOffset, 0)) * rotation)

		item.Parent = workspace.runtime[player.UserId][unitType]

		if unitType == "MELEE" then
			-- Adiciona a animação se for melee
			MapService:CreateWalkAnimation(item)
		end
	end
end

function MapService:CreateWalkAnimation(melee: Model)
	local AnimationController: AnimationController = melee:FindFirstChild("AnimationController")

	local idle = AnimationController:LoadAnimation(melee.Animations.Idle)
	idle.Priority = Enum.AnimationPriority.Idle
	idle:Play()
end

function MapService:InitMapFromPlayer(player: Player)
	local items = PlayerDataHandler:Get(player, "itemsOnMap")

	for _, item in items do
		local itemType = item.Type
		local itemName = item.Name
		local slot = item.Slot
		local subSlot = item.SubSlot

		MapService:SetItemOnMap(player, itemType, itemName, slot, subSlot)
	end
end

function MapService:RestartBaseMap(player: Player)
	local blocks = workspace.runtime[player.UserId]["BLOCK"]:GetChildren()

	for _, block in blocks do
		block:Destroy()
	end

	local blocks = workspace.runtime[player.UserId]["RANGED"]:GetChildren()

	for _, block in blocks do
		block:Destroy()
	end

	MapService:InitMapFromPlayer(player)
end
return MapService
