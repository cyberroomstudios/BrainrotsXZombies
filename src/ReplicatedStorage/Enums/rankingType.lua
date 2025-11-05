local RankingType = {
	Playtime = "Playtime",
	Money = "Money",
	MaxWave = "MaxWave",
	RobuxSpent = "RobuxSpent",
}

local IS_ASCENDING: { [string]: boolean } = {
	[RankingType.Playtime] = false,
	[RankingType.Money] = false,
	[RankingType.MaxWave] = false,
	[RankingType.RobuxSpent] = false,
}

local LOCK_BEST_VALUE: { [string]: boolean } = {
	[RankingType.Playtime] = true,
	[RankingType.Money] = false,
	[RankingType.MaxWave] = true,
	[RankingType.RobuxSpent] = true,
}

local DISPLAY_NAMES: { [string]: string } = {
	[RankingType.Playtime] = "Playtime",
	[RankingType.Money] = "Money",
	[RankingType.MaxWave] = "Max Wave",
	[RankingType.RobuxSpent] = "Robux Spent",
}

local TITLES: { [string]: string } = {
	[RankingType.Playtime] = "Playtime Leaderboard",
	[RankingType.Money] = "Money Leaderboard",
	[RankingType.MaxWave] = "Max Wave Leaderboard",
	[RankingType.RobuxSpent] = "Robux Spent Leaderboard",
}

local SUFFIXES = { "", "K", "M", "B", "T", "Q" }

local function formatNumberWithSuffix(value: any): string
	local numberValue = typeof(value) == "number" and value or tonumber(value)
	if numberValue == nil then
		return tostring(value)
	end

	local isNegative = numberValue < 0
	local magnitude = math.abs(numberValue)
	local index = 1

	while magnitude >= 1000 and index < #SUFFIXES do
		magnitude /= 1000
		index += 1
	end

	local formatted = string.format("%.1f", magnitude)
	formatted = formatted:gsub("%.0$", "")

	if isNegative then
		formatted = "-" .. formatted
	end

	return formatted .. SUFFIXES[index]
end

local function formatCurrency(value: any, prefix: string): string
	local numberValue = typeof(value) == "number" and value or tonumber(value)
	if numberValue == nil then
		return tostring(value)
	end

	local formatted = formatNumberWithSuffix(numberValue)
	if formatted:sub(1, 1) == "-" then
		return "-" .. prefix .. formatted:sub(2)
	end

	return prefix .. formatted
end

local function formatPlaytime(value: any): string
	local seconds = typeof(value) == "number" and value or tonumber(value)
	if seconds == nil then
		return tostring(value)
	end

	seconds = math.max(0, math.floor(seconds))
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds % 86400 / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	local remainingSeconds = seconds % 60

	if days > 0 then
		return string.format("%dd %02dh", days, hours)
	elseif hours > 0 then
		return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
	else
		return string.format("%02d:%02d", minutes, remainingSeconds)
	end
end

local function formatInteger(value: any): string
	local numberValue = typeof(value) == "number" and value or tonumber(value)
	if numberValue == nil then
		return tostring(value)
	end

	return tostring(math.floor(numberValue))
end

local FORMATTERS: { [string]: (any) -> string } = {
	[RankingType.Playtime] = formatPlaytime,
	[RankingType.Money] = function(value: any): string
		return formatCurrency(value, "$")
	end,
	[RankingType.MaxWave] = function(value: any): string
		return formatInteger(value)
	end,
	[RankingType.RobuxSpent] = function(value: any): string
		return formatCurrency(value, "R$")
	end,
}

function RankingType.IsAscending(rankingType: string): boolean
	return IS_ASCENDING[rankingType] == true
end

function RankingType.Compare(rankingType: string, currValue: number, newValue: number): boolean
	return RankingType.IsAscending(rankingType) == (newValue < currValue)
end

function RankingType.LockBestValue(rankingType: string): boolean
	return LOCK_BEST_VALUE[rankingType] == true
end

function RankingType.GetDisplayName(rankingType: string): string
	return DISPLAY_NAMES[rankingType] or rankingType or "Leaderboard"
end

function RankingType.GetTitle(rankingType: string): string
	return TITLES[rankingType] or (RankingType.GetDisplayName(rankingType) .. " Leaderboard")
end

function RankingType.FormatValue(rankingType: string, value: any): string
	local formatter = FORMATTERS[rankingType]
	if formatter then
		return formatter(value)
	end

	if typeof(value) == "number" then
		return formatNumberWithSuffix(value)
	end

	return tostring(value)
end

return RankingType
