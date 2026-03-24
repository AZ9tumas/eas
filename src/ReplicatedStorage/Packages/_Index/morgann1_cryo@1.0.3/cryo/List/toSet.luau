--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Create a dictionary where each value in the given list corresponds to a key
	in the dictionary with a value of true
]]

local function toSet<V>(list: Globals.List<V>)
	local new = {}

	for i = 1, #list do
		new[list[i]] = true
	end

	return new
end

return toSet
