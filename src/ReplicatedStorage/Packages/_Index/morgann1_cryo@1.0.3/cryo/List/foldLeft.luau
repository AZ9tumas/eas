--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Performs a left-fold of the list with the given initial value and callback.
]]
local function foldLeft<V, R>(list: Globals.List<V>, callback: (accum: R, value: V, index: number) -> R, initialValue: R): R
	local accum = initialValue

	for i = 1, #list do
		accum = callback(accum, list[i], i)
	end

	return accum
end

return foldLeft
