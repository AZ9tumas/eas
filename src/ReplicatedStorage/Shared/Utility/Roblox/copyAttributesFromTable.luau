return function(source, target: Model): boolean?
	for key, value in pairs(source) do
		if typeof(value) == 'table' then continue end
		
		target:SetAttribute(key, value)
	end
	
	return true
end