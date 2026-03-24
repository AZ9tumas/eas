local HttpService = game:GetService("HttpService")

return function()
	local guid = HttpService:GenerateGUID(false)
    guid = guid:gsub("-", "")
    return string.lower(guid)
end