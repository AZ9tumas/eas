return function(source: Model, target: Model): boolean?
	for key, value in pairs(source:GetAttributes()) do
		target:SetAttribute(key, value)
	end
	
	return true
end