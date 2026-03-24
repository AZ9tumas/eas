local function mergeTables<T>(...: {T}): {T}
	local result = {}

	for _, tbl in { ... } do
		for i = 1, #tbl do
			result[#result + 1] = tbl[i]
		end
	end

	return result
end

return mergeTables