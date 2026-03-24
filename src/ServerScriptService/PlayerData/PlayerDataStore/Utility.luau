local Players = game:GetService("Players")

local module = {}

-- Utility functions

export type JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer

function module.isJSONAcceptable(value)
	local t = typeof(value)

	-- primitive types
	if t == "number" or t == "string" or t == "boolean" then
		return true
	end

	-- buffer type
	if t == "buffer" then
		return true
	end

	-- table
	if t == "table" then
		-- first check JSONAcceptable key if exists
		if value.JSONAcceptable ~= nil then
			if not module.isJSONAcceptable(value.JSONAcceptable) then
				return false
			end
		end

		-- check all string keys recursively
		for k, v in pairs(value) do
			if typeof(k) ~= "string" then
				return false
			end
			if not module.isJSONAcceptable(v) then
				return false
			end
		end

		return true
	end

	return false
end

-- don't use this for RemoveKey, since it creates table if it doesn't exist
function module.setNestedValue(tbl, keys, value)
	local current = tbl
	for i = 1, #keys - 1 do
		local key = keys[i]
		if typeof(current[key]) ~= "table" then
			current[key] = {}
		end
		current = current[key]
	end
	current[keys[#keys]] = value
end

function module.getNestedValue(tbl, keys)
	local current = tbl
	for i = 1, #keys do
		if typeof(current) ~= "table" then return nil end
		current = current[keys[i]]
	end
	return current
end

function module.parseArgs(...)
	local args = { ... }
	local value = args[#args]
	local keys = table.move(args, 1, #args - 1, 1, {})
	return keys, value, args
end

function module:resolvePlayerAndUserId(player: Player | number | string)
	local userId = player

	if typeof(player) == "Instance" then
		userId = tostring(player.UserId)
	elseif typeof(player) == "number" then
		userId = tostring(player)
		player = Players:GetPlayerByUserId(player)
	elseif typeof(player) == "string" then
		player = Players:GetPlayerByUserId(tonumber(player))
	end

	return player, userId
end

function module:isPlayerOnline(player: Player?)
	return typeof(player) == "Instance" and player and player:IsDescendantOf(Players)
end

return module
