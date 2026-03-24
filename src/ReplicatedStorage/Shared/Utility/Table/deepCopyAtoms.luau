local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local deepCopy = require(script.Parent.deepCopy)
local atom = Charm.atom


local function deepCopyAtoms<T>(x: T & {}): T
	local new = {}

	for key, value in pairs(x) do
		local realValue = value()
		new[key] = atom(deepCopy(realValue))
	end

	return new :: any
end

return deepCopyAtoms