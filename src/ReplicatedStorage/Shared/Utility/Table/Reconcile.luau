local function reconcile(defaults: {}, data: {}?)
	data = data or {}

	for key, value in pairs(defaults) do
		if data[key] == nil then
			if typeof(value) == "table" then
				data[key] = table.clone(value)
			else
				data[key] = value
			end
		elseif typeof(value) == "table" and typeof(data[key]) == "table" then
			reconcile(value, data[key])
		end
	end

	return data
end

return reconcile