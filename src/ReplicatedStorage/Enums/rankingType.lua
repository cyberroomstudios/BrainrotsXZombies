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

function RankingType.IsAscending(rankingType: string): boolean
	return IS_ASCENDING[rankingType]
end

function RankingType.Compare(rankingType: string, currValue: number, newValue: number): boolean
	return RankingType.IsAscending(rankingType) == (newValue < currValue)
end

function RankingType.LockBestValue(rankingType: string): boolean
	return LOCK_BEST_VALUE[rankingType]
end

return RankingType
