local ClientUtil = {}

function ClientUtil:Init() end

function ClientUtil:WaitForDescendants(root, ...)
	local names = { ... }
	local current = root

	for _, name in ipairs(names) do
		current = current:WaitForChild(name)

		while not current do
			current = current:WaitForChild(name)
		end
	end

	return current
end

function ClientUtil:FormatToUSD(number)
	-- Se for inteiro, formata sem casas decimais
	local formatted
	if number % 1 == 0 then
		formatted = string.format("%d", number)
	else
		formatted = string.format("%.2f", number)
	end

	local beforeDecimal, afterDecimal = formatted:match("^(%-?%d+)%.*(%d*)$")
	beforeDecimal = beforeDecimal:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if beforeDecimal:sub(1, 1) == "," then
		beforeDecimal = beforeDecimal:sub(2)
	end

	if afterDecimal ~= "" then
		return "$" .. beforeDecimal .. "." .. afterDecimal
	else
		return "$" .. beforeDecimal
	end
end

function ClientUtil:FormatSecondsToMinutes(seconds)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%02dm:%02ds", minutes, remainingSeconds)
end

function ClientUtil:FormatNumberToSuffixes(n)
	local suffixes = { "", "K", "M", "B", "T", "Q" } -- pode adicionar mais se quiser
	local i = 1

	while n >= 1000 and i < #suffixes do
		n = n / 1000
		i = i + 1
	end

	-- Limita para 1 casa decimal e remove .0 se for inteiro
	local formatted = string.format("%.1f", n)
	formatted = formatted:gsub("%.0$", "")

	return formatted .. suffixes[i]
end

return ClientUtil
