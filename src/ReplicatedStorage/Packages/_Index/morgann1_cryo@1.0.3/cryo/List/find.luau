--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Returns the index of the first value found or nil if not found.
]]
local function find<V>(list: Globals.List<V>, value: V): number?
	for i = 1, #list do
		if list[i] == value then
			return i
		end
	end
	return nil
end

return find
