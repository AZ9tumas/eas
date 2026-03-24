--!strict
local Globals = require(script.Parent.Parent.Globals)

--[[
	Performs a right-fold of the list with the given initial value and callback.
]]
local function foldRight<V, R>(list: Globals.List<V>, callback: (accum: R, value: V, index: number) -> R, initialValue: R): R
	local accum = initialValue

	for i = #list, 1, -1 do
		accum = callback(accum, list[i], i)
	end

	return accum
end

return foldRight
