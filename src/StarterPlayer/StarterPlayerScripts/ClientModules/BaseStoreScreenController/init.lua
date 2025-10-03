local BaseStoreScreenController = {}

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)
local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local blocks = require(ReplicatedStorage.Enums.blocks)

local screen
local timeRestockTextLabel
local blocksContainer
local selectedItem = nil

function BaseStoreScreenController:Init()
	BaseStoreScreenController:CreateReferences()
	BaseStoreScreenController:ConfigureProximity()
	BaseStoreScreenController:InitAttributeListener()
	BaseStoreScreenController:CreateButtonListeners()
end

function BaseStoreScreenController:CreateReferences()
	screen = UIReferences:GetReference("BASE_SHOP_SCREEN")
	timeRestockTextLabel = UIReferences:GetReference("BASE_STORE_TIME_TEXTLABEL")
	blocksContainer = UIReferences:GetReference("BLOCKS_CONTAINER")
end

function BaseStoreScreenController:ClearScreen()
	for _, value in blocksContainer:GetChildren() do
		if (not value:IsA("UIListLayout")) and not value.Name == "BUTTONS" then
			value:Destroy()
		end
	end
end

function BaseStoreScreenController:CreateButtonListeners()
	local buttonFrame = blocksContainer.BUTTONS
	local buyButton = buttonFrame.Buy
	local robuxButton = buttonFrame.Robux
	local restockButton = buttonFrame.Restock

	buyButton.MouseButton1Click:Connect(function()
		print(selectedItem)
		local result = bridge:InvokeServerAsync({
			[actionIdentifier] = "BuyItem",
			data = {
				Item = selectedItem
			}
		})
	end)
	
	robuxButton.MouseButton1Click:Connect(function()
		print("Robux")
	end)

	restockButton.MouseButton1Click:Connect(function()
		print("Restock")
	end)

end
function BaseStoreScreenController:ConfigureProximity()
	local proximityPart = ClientUtil:WaitForDescendants(workspace, "map", "stores", "base", "store", "ProximityPart")
	local proximityPrompt = proximityPart.ProximityPrompt

	proximityPrompt.PromptShown:Connect(function()
		BaseStoreScreenController:ClearScreen()
		BaseStoreScreenController:Open()
		local result = bridge:InvokeServerAsync({
			[actionIdentifier] = "GetStock",
		})

		
		BaseStoreScreenController:BuildBlocks(result.Blocks)
	
	end)

	proximityPrompt.PromptHidden:Connect(function()
		BaseStoreScreenController:Close()
	end)
end

function BaseStoreScreenController:Open()
	screen.Visible = true
end

function BaseStoreScreenController:Close()
	screen.Visible = false
end

function BaseStoreScreenController:InitAttributeListener()
	workspace:GetAttributeChangedSignal("TIME_TO_RELOAD_RESTOCK"):Connect(function()
		local leftTime = workspace:GetAttribute("TIME_TO_RELOAD_RESTOCK")
		timeRestockTextLabel.Text = "Shop Restock In:" .. ClientUtil:FormatSecondsToMinutes(leftTime)
	end)
end

function BaseStoreScreenController:BuildBlocks(blocksList)
	local itemsFolder = ReplicatedStorage.GUI.Shop.Items
	
	for index, value in blocksList do
		local blockInfo = blocks[index]

		if blockInfo then
			local newItem = itemsFolder[blockInfo.Rarity]:Clone()

			newItem.Content.MainInfos.ItemName.Text = blockInfo.GUI.Name
			newItem.Content.MainInfos.Desc.Text = blockInfo.GUI.Description
			newItem.Content.MainInfos.Price.Text = ClientUtil:FormatToUSD(blockInfo.Price)

			newItem.Name = index
			newItem.LayoutOrder = blockInfo.GUI.Order
			newItem.Parent = blocksContainer

			newItem.MouseButton1Click:Connect(function()
				local currentLayoutOrder = newItem.LayoutOrder
				selectedItem = {
					Type = "BLOCK",
					Name = index
				}
				for _, item in blocksContainer:GetChildren() do
					if not item:IsA("UIListLayout") then
						if item.LayoutOrder > currentLayoutOrder then
							item.LayoutOrder = item.LayoutOrder + 1
						end
					end
				end

				blocksContainer.BUTTONS.Visible = true
				blocksContainer.BUTTONS.LayoutOrder = currentLayoutOrder + 1
			end)
		end
	end

end

return BaseStoreScreenController
