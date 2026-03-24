--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Returns the index of the first value for which predicate(value, index) is truthy, or nil if not found.
]]

local function findWhere<V>(list: Globals.List<V>, predicate: (value: V, index: number) -> boolean): number?
	for i = 1, #list do
		if predicate(list[i], i) then
			return i
		end
	end
	return nil
end

return findWhere
