local function deepCopy<T>(x: T): T
	if type(x) ~= "table" then
		return x
	end

	local new = table.clone(x)

	for key, value in x do
		if type(value) == "table" then
			new[key] = deepCopy(value)
		end
	end

	return new :: any
end

return deepCopy