--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Create a copy of a list with only values for which `callback` returns true.
	Calls the callback with (value, index).
]]
local function filter<V>(list: Globals.List<V>, callback: (value: V, index: number) -> boolean)
	local new = {}
	local index = 1

	for i = 1, #list do
		local value = list[i]
		if callback(value, i) then
			new[index] = value
			index += 1
		end
	end

	return new
end

return filter
