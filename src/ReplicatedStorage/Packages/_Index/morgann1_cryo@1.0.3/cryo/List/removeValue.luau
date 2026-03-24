--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Creates a new list that has no occurrences of the given value.
]]
local function removeValue<V>(list: Globals.List<V>, value: V)
	local new = {}
	local index = 1

	for i = 1, #list do
		if list[i] ~= value then
			new[index] = list[i]
			index = index + 1
		end
	end

	return new
end

return removeValue
