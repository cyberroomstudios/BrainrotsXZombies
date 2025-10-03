local StockService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local unitsRarity = require(ReplicatedStorage.Enums.unitsRarity)
local blocks = require(ReplicatedStorage.Enums.blocks)

local TIME_TO_RELOAD_STOCK = 60 * 5

local blocksGlobalStock = {}
local blockPlayerStock = {}

function StockService:Init()
	StockService:InitBridgeListener()
	StockService:InitStockCounter()
end

function StockService:InitBridgeListener()
	bridge.OnServerInvoke = function(player, data)
		if data[actionIdentifier] == "GetStock" then
			return StockService:GetStock(player)
		end
	end
end

function StockService:GetStock(player: Player)
	if not blockPlayerStock[player] then
		blockPlayerStock[player] = blocksGlobalStock
	end

	return blockPlayerStock[player]
end
function StockService:InitStockCounter()
	currentTimeToReload = TIME_TO_RELOAD_STOCK
	task.spawn(function()
		while true do
			StockService:CreateBlockStock()
			while currentTimeToReload > 0 do
				currentTimeToReload = currentTimeToReload - 1
				workspace:SetAttribute("TIME_TO_RELOAD_RESTOCK", currentTimeToReload)
				task.wait(1)
			end

			currentTimeToReload = TIME_TO_RELOAD_STOCK
		end
	end)
end

function StockService:CreateBlockStock()
	local function getFromRarity(rarityName: string)
		local selectedItems = {}
		for _, block in blocks do
			if block.Rarity == rarityName then
				table.insert(selectedItems, block)
			end
		end

		table.sort(selectedItems, function(a, b)
			return a.Odd > b.Odd
		end)

		return selectedItems
	end

	local raffledRarities = {}

	-- Pega todas as categorias e vê quais vão ser sorteadas
	for index, rarity in unitsRarity do
		local odd = rarity.Odd
		local randomNumber = math.random(1, 100)

		if randomNumber <= (odd * 100) then
			table.insert(raffledRarities, index)
		end
	end

	local raffledBlocks = {}
	for index, rarity in raffledRarities do
		local blocksFromRarity = getFromRarity(rarity)

		local added = false
		for _, block in blocksFromRarity do
			local odd = block.Odd
			local randomNumber = math.random(1, 100)

			if randomNumber <= (odd * 100) then
				added = true
				table.insert(raffledBlocks, block)
			end
		end

		-- Se não tive saido nenhum, pega o item de maior sorte
		if not added then
			table.insert(raffledBlocks, blocksFromRarity[1])
		end
	end

	blocksGlobalStock = {}

	for index, block in raffledBlocks do
		blocksGlobalStock[block.Name] = math.random(block.Stock.Min, block.Stock.Max)
	end
end

return StockService
