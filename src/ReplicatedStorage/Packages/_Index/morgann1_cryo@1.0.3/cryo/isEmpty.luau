--!strict

local function isEmpty<K, V>(object: { [K]: V }): boolean
	return next(object) == nil
end

return isEmpty
