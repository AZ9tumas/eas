--!strict
local None = require(script.Parent.Parent.None)
local Globals = require(script.Parent.Parent.Globals)

--[[
	Combine a number of dictionary-like tables into a new table.

	Keys specified in later tables will overwrite keys in previous tables.

	Use `Cryo.None` as a value to remove a key. This is necessary because
	Lua does not distinguish between a value not being present in a table and a
	value being `nil`.
]]
local function join<K, V>(...: Globals.Dictionary<K, V>)
	local output = {}

	for i = 1, select("#", ...) do
		local source = select(i, ...)

		if source ~= nil then
			for key, value in pairs(source) do
				if value == None then
					output[key] = nil
				else
					output[key] = value
				end
			end
		end
	end

	return output
end

return join
