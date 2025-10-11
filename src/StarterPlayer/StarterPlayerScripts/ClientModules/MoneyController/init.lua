local MoneyController = {}

local Players = game:GetService("Players")

local UIReferences = require(Players.LocalPlayer.PlayerScripts.Util.UIReferences)
local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)

local player = Players.LocalPlayer

local moneyLabel
local historyMoney
local oldMoney = nil
function MoneyController:Init()
	MoneyController:CreateReferences()
	MoneyController:InitAttributeListener()
end

function MoneyController:CreateReferences()
	-- Botões referente as Tools
	moneyLabel = UIReferences:GetReference("MONEY")
	historyMoney = UIReferences:GetReference("HISTORY_MONEY")
end

function MoneyController:InitAttributeListener()
	player:GetAttributeChangedSignal("MONEY"):Connect(function()
		local money = player:GetAttribute("MONEY")

		if oldMoney and oldMoney < money then
			local diference = money - oldMoney
			MoneyController:AddHistory(true, diference)
		end

		if oldMoney and oldMoney > money then
			local diference = oldMoney - money
			MoneyController:AddHistory(false, diference)
		end

		oldMoney = money
		moneyLabel.Text = ClientUtil:FormatToUSD(money)
	end)
end

function MoneyController:AddHistory(positiveMoney, value)
	if positiveMoney then
		local positiveMoneyTextLabel = historyMoney.PositiveMoney:Clone()
		positiveMoneyTextLabel.Visible = true
		positiveMoneyTextLabel.Text = "+" .. ClientUtil:FormatToUSD(value)
		positiveMoneyTextLabel.Parent = historyMoney

		task.delay(1, function()
			positiveMoneyTextLabel.Visible = false
		end)
	else
		local negativeMoneyTextLabel = historyMoney.NegativeMoney:Clone()
		negativeMoneyTextLabel.Visible = true
		negativeMoneyTextLabel.Text = "-" .. ClientUtil:FormatToUSD(value)
		negativeMoneyTextLabel.Parent = historyMoney

		task.delay(1, function()
			negativeMoneyTextLabel.Visible = false
		end)
	end
end

return MoneyController
