--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Create a copy of a list where each value is transformed by `callback`
]]
local function map<V, R>(list: Globals.List<V>, callback: (value: V, index: number) -> R): Globals.List<R>
	local new = {}

	for i = 1, #list do
		new[i] = callback(list[i], i)
	end

	return new
end

return map
