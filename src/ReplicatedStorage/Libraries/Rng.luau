
return function(Table, Luck: number?, Seed)
	local Luck = Luck or 1
	local RND = Seed and Random.new(Seed) or Random.new()

	local ChanceTable = {}
	local TotalChance = 0
	for Key, ChanceOrSubTable in Table do
		if typeof(ChanceOrSubTable) == "table" and ChanceOrSubTable.Enabled ~= nil and not ChanceOrSubTable.Enabled then continue end
		local Rarity = (typeof(ChanceOrSubTable) == "number" and ChanceOrSubTable or ChanceOrSubTable.Rarity) or 0
		local AdjustedWeight = Rarity ^ (1 / Luck)
		TotalChance += AdjustedWeight
		table.insert(ChanceTable, {Key, TotalChance})
	end
	--print(TotalChance, Seed)
	local ChosenNumber = RND:NextNumber(0, TotalChance)
	local ChosenKey

	for _, entry in ChanceTable do
		if ChosenNumber <= entry[2] then
			ChosenKey = entry[1]
			break
		end
	end
	return ChosenKey
end
