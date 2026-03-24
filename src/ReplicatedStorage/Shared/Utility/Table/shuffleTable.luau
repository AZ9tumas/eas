local function shuffleTable<T>(tbl: {T}, rng: Random?): {T}
	local result = table.clone(tbl)
	rng = rng or Random.new()

	for i = #result, 2, -1 do
		local j = rng:NextInteger(1, i)
		result[i], result[j] = result[j], result[i]
	end

	return result
end

return shuffleTable