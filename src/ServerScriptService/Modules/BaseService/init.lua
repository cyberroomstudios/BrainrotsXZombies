local ServerScriptService = game:GetService("ServerScriptService")

local UtilService = require(ServerScriptService.Modules.UtilService)

local BaseService = {}

-- Usudo para evitar Race Condition
local allocating = false

function BaseService:Init() end

function BaseService:Allocate2(player: Player)
	if allocating then
		return false
	end

	allocating = true
	-- Obtem todas as places
	local places = workspace.map.baseLocations:GetChildren()

	-- Embaralha a tabela
	for i = #places, 2, -1 do
		local j = math.random(i)
		places[i], places[j] = places[j], places[i]
	end

	-- Procura uma base não ocupada
	for _, place in places do
		if not place:GetAttribute("BUSY") then
			-- Inicializa os atributos da base
			place:SetAttribute("BUSY", true)
			place:SetAttribute("OWNER", player.UserId)

			player:SetAttribute("BASE", place.Name)
			player:SetAttribute("FLOOR", 1)
			BaseService:MoveToBase(player, place.baseTemplate.PrimaryPart)
			break
		end
	end
end

function BaseService:Allocate(player: Player)
	if allocating then
		return false
	end

	allocating = true
	-- Obtem todas as places
	local place = workspace.map.baseLocations:FindFirstChild("1")

	-- Inicializa os atributos da base
	place:SetAttribute("BUSY", true)
	place:SetAttribute("OWNER", player.UserId)

	player:SetAttribute("BASE", place.Name)
	player:SetAttribute("FLOOR", 1)
	BaseService:MoveToBase(player, place.baseTemplate.PrimaryPart)
end

-- Leva o Jogador para o Spawn da Base
function BaseService:MoveToBase(player: Player, baseSpawn: Part)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = baseSpawn.CFrame + Vector3.new(0, 10, 0)
	end
end

function BaseService:GetBase(player: Player)
	local baseNumber = player:GetAttribute("BASE")

	if baseNumber then
		local base = UtilService:WaitForDescendants(workspace, "map", "baseLocations", baseNumber)

		if base then
			return base
		end
	end
end

return BaseService
