--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Returns a new list, ordered with the given sort callback.
	If no callback is given, the default table.sort will be used.
]]

local function sort<V>(list: Globals.List<V>, callback: (a: V, b: V) -> boolean)
	local new = {}

	for i = 1, #list do
		new[i] = list[i]
	end

	table.sort(new, callback)

	return new
end

return sort
