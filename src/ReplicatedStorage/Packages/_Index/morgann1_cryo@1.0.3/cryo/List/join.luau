--!strict
local None = require(script.Parent.Parent.None)
local Globals = require(script.Parent.Parent.Globals)

--[[
	Joins any number of lists together into a new list
]]
local function join<V>(...: Globals.List<V>)
	local new = {}

	for listKey = 1, select("#", ...) do
		local list = select(listKey, ...)
		local len = #new

		for itemKey = 1, #list do
			if list[itemKey] == None then
				len -= 1
			else
				new[len + itemKey] = list[itemKey]
			end
		end
	end

	return new
end

return join
