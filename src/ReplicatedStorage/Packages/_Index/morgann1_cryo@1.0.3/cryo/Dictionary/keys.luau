--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Returns a list of the keys from the given dictionary.
]]
local function keys<K, V>(dictionary: Globals.Dictionary<K, V>)
	local new = {}
	local index = 1

	for key in pairs(dictionary) do
		new[index] = key
		index += 1
	end

	return new
end

return keys
