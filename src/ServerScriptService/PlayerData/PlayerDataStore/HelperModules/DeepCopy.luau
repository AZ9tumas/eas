local module = {}

module.DeepCopy = function(original)
	local copy
	if typeof(original) == "table" then
		copy = {}
		for key, value in next, original do
			copy[module.DeepCopy(key)] = module.DeepCopy(value)
		end
		setmetatable(copy, module.DeepCopy(getmetatable(original)))
	else
		copy = original
	end
	return copy
end

module.DeepCopyWithRef = function(original, destination)
	local copy
	if typeof(original) == "table" then
		copy = destination or {}
		for key, value in next, original do
			copy[module.DeepCopy(key)] = module.DeepCopy(value)
		end
		setmetatable(copy, module.DeepCopy(getmetatable(original)))
	else
		copy = original
	end
	return copy
end

return module