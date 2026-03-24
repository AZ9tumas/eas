local function HasValidEntries(tbl)
	for _, v in pairs(tbl) do
		if typeof(v) == "number" and v > 0 then
			return true
		elseif typeof(v) == "table" and HasValidEntries(v) then
			return true
		end
	end
	return false
end

local function Pick(tbl, Luck: number?, RND: Random?, AllowZeroFallback: boolean?)
	Luck = Luck or 1
	RND = RND or Random.new()

	AllowZeroFallback = AllowZeroFallback or false

	local ChanceTable = {}
	local ZeroEntries = {} -- store keys with 0 weight
	local TotalChance = 0

	for key, value in pairs(tbl) do
		local weight

		if typeof(value) == "number" then
			if value <= 0 then
				-- store zero entries for fallback
				table.insert(ZeroEntries, key)
				continue -- ❌ ignore invalid chance
			end
			weight = value

		elseif typeof(value) == "table" then
			if not HasValidEntries(value) then
				continue -- ❌ ignore empty / invalid tier
			end
			weight = 1 -- default tier weight
		end

		local adjusted = weight ^ (1 / Luck)
		TotalChance += adjusted
		table.insert(ChanceTable, { key, TotalChance })
	end

	-- ✅ If nothing valid and fallback is allowed, pick a 0-entry
	if TotalChance == 0 then
		if AllowZeroFallback and #ZeroEntries > 0 then
			local pick = ZeroEntries[RND:NextInteger(1, #ZeroEntries)]
			return pick
		end
		return nil
	end

	local roll = RND:NextNumber(0, TotalChance)
	local chosenKey

	for _, entry in ipairs(ChanceTable) do
		if roll <= entry[2] then
			chosenKey = entry[1]
			break
		end
	end

	local chosenValue = tbl[chosenKey]

	-- 🔁 recurse until we hit a real item
	if typeof(chosenValue) == "table" then
		return Pick(chosenValue, Luck, RND)
	end

	return chosenKey
end

return Pick