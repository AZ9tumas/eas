--!strict
local isArray = require(script.Parent.isArray)

type ArrayDiff = {
	removals: number,
	additions: { any },
	changes: { [number]: any },
	arrayDiffs: { [number]: ArrayDiff },
	dictionaryDiffs: { [number]: DictionaryDiff },
	changeCount: number,
}

type DictionaryDiff = {
	removals: { [any]: boolean },
	removalCount: number,
	changes: { [any]: any },
	arrayDiffs: { [any]: ArrayDiff },
	dictionaryDiffs: { [any]: DictionaryDiff },
	changeCount: number,
}


local function deepCopy(x: any)
	if type(x) ~= "table" then
		return x
	end

	local new = table.clone(x)

	for key, value in x do
		if type(value) == "table" then
			new[key] = deepCopy(value)
		end
	end

	return new
end

local Diff = {}

function Diff.diffValue(
	oldValue: any,
	newValue: any,
	key: any,
	arrayDiffs: { [number]: ArrayDiff },
	dictionaryDiffs: { [number]: DictionaryDiff },
	changes: { [number]: any },
	mutable: boolean
): boolean
	if typeof(oldValue) ~= "table" or typeof(newValue) ~= "table" then
		if oldValue ~= newValue then
			changes[key] = newValue
			return true
		end

		return false
	end

	if isArray(oldValue) and isArray(newValue) then
		local diff = Diff.diffArray(oldValue, newValue, mutable)

		if diff then
			arrayDiffs[key] = diff
			return true
		else
			return false
		end
	elseif not isArray(oldValue) and not isArray(newValue) then
		local diff = Diff.diffDictionary(oldValue, newValue, mutable)

		if diff then
			dictionaryDiffs[key] = diff
			return true
		else
			return false
		end
	else
		changes[key] = newValue
		return true
	end
end

function Diff.diffArray(old: {}, new: {}, mutable: boolean): ArrayDiff?
	if old == new then
		return nil
	end

	local removals = 0
	local additions = {}

	if #old > #new then
		removals = #old - #new
	elseif #new > #old then
		for i = #old + 1, #new do
			table.insert(additions, new[i])
		end
	end

	local changes = {}
	local arrayDiffs = {}
	local dictionaryDiffs = {}
	local changeCount = 0

	for i = 1, math.min(#old, #new) do
		local oldValue = old[i]
		local newValue = new[i]

		if Diff.diffValue(oldValue, newValue, i, arrayDiffs, dictionaryDiffs, changes, mutable) then
			changeCount += 1
		end
	end

	if removals > 0 or #additions > 0 or changeCount > 0 then
		if mutable then
			for _ = 1, removals do
				table.remove(old, #old)
			end

			for _, addition in additions do
				table.insert(old, deepCopy(addition))
			end

			for index, value in changes do
				old[index] = deepCopy(value)
			end
		end

		return {
			removals = removals,
			additions = additions,
			changes = changes,
			arrayDiffs = arrayDiffs,
			dictionaryDiffs = dictionaryDiffs,
			changeCount = changeCount,
		}
	end

	return nil
end

function Diff.diffDictionary(old: {}, new: {}, mutable: boolean): DictionaryDiff?
	if old == new then
		return nil
	end

	local removals = {}
	local removalCount = 0
	for key in old do
		if new[key] == nil then
			removals[key] = true
			removalCount += 1
		end
	end

	local changes = {}
	local arrayDiffs = {}
	local dictionaryDiffs = {}
	local changeCount = 0

	for key, newValue in new do
		local oldValue = old[key]

		if Diff.diffValue(oldValue, newValue, key, arrayDiffs, dictionaryDiffs, changes, mutable) then
			changeCount += 1
		end
	end

	if removalCount > 0 or changeCount > 0 then
		if mutable then
			for removal in removals do
				old[removal] = nil
			end

			for key, value in changes do
				old[key] = deepCopy(value)
			end
		end

		return {
			removals = removals,
			removalCount = removalCount,
			changes = changes,
			arrayDiffs = arrayDiffs,
			dictionaryDiffs = dictionaryDiffs,
			changeCount = changeCount,
		}
	end

	return nil
end

return Diff