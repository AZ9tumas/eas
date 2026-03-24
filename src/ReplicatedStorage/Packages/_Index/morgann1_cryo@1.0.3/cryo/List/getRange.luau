--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Returns a new list containing only the elements within the given range.
]]

local function getRange<V>(list: Globals.List<V>, startIndex: number, endIndex: number): { V }
	assert(startIndex <= endIndex, "startIndex must be less than or equal to endIndex")

	local new = {}
	local index = 1

	for i = math.max(1, startIndex), math.min(#list, endIndex) do
		new[index] = list[i]
		index += 1
	end

	return new
end

return getRange
