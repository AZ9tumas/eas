function format(Int)
	return string.format("%02i", Int)
end


local TimeFormat = {}

function TimeFormat.getTimeInMinutes(seconds: number)
	local minutes = (seconds - seconds % 60) / 60
	return minutes
end

function TimeFormat.convertToHMS(seconds: number)
	local minutes = (seconds - seconds % 60) / 60
	seconds = seconds - minutes * 60
	local hours = (minutes - minutes % 60) / 60
	minutes = minutes - hours*60
	return format(hours) .. ":" .. format(minutes) .. ":" .. format(seconds)
end

function TimeFormat.convertToMS(seconds: number)
    local minutes = (seconds - seconds % 60) / 60
	seconds = seconds - minutes * 60
    return format(minutes) .. ":" .. format(seconds)
end

function TimeFormat.automatic(seconds: number)
	if seconds < 60*60 then
		return TimeFormat.convertToMS(seconds)
	else
		return TimeFormat.convertToHMS(seconds)
	end
end

function TimeFormat.getLongestTimeAsText(seconds: number)
	seconds = math.ceil(seconds)


	local timeToUse = seconds
	local suffix = "second"

	local minutes = (seconds - seconds % 60) / 60
	if minutes > 0 then
		timeToUse = minutes
		suffix = "minute"

		local hours = (minutes - minutes % 60) / 60
		if hours > 0 then
			timeToUse = hours
			suffix = "hour"
		end
	end

	local plural = if timeToUse > 1 then "s" else ""
	return `{timeToUse} {suffix}{plural}`
end

-- Formats a duration (in seconds) into a natural human-readable string.
-- Examples:
--  • 45 -> "45 seconds"
--  • 125 -> "2 minutes and 5 seconds"
--  • 3700 -> "1 hour and 1 minute"
--  • 93784 -> "1 day and 2 hours"
--  • 200000 -> "2 days, 7 hours and 33 minutes"

function TimeFormat.formatDuration(seconds: number): string
	seconds = math.ceil(seconds)

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	local parts = {}

	if days > 0 then
		table.insert(parts, `{days} day{if days ~= 1 then "s" else ""}`)
	end
	if hours > 0 then
		table.insert(parts, `{hours} hour{if hours ~= 1 then "s" else ""}`)
	end
	if minutes > 0 then
		table.insert(parts, `{minutes} minute{if minutes ~= 1 then "s" else ""}`)
	end
	if secs > 0 and #parts == 0 then
		-- Only show seconds if it's the only part (e.g. "45 seconds")
		table.insert(parts, `{secs} second{if secs ~= 1 then "s" else ""}`)
	end

	if #parts == 0 then
		return "0 seconds"
	elseif #parts == 1 then
		return parts[1]
	else
		-- Join parts naturally (e.g. "2 days, 7 hours and 33 minutes")
		local last = table.remove(parts)
		return table.concat(parts, ", ") .. " and " .. last
	end
end

function TimeFormat.convertTimestamp(timestamp: number, useUTC: boolean?)
	useUTC = useUTC or false

	-- Choose the appropriate Lua function
	local dateTable = useUTC and os.date("!*t", timestamp) or os.date("*t", timestamp)

	-- Build a formatted string: "YYYY-MM-DD HH:MM:SS"
	local formatted = string.format(
		"%04i-%02i-%02i %02i:%02i:%02i",
		dateTable.year, dateTable.month, dateTable.day,
		dateTable.hour, dateTable.min, dateTable.sec
	)

	return {
		Year = dateTable.year,
		Month = dateTable.month,
		Day = dateTable.day,
		Hour = dateTable.hour,
		Minute = dateTable.min,
		Second = dateTable.sec,
		Formatted = formatted
	}
end

function TimeFormat.compact2(seconds: number): string
	seconds = math.max(0, math.floor(seconds))

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if days > 0 then
		return string.format("%dd %02dh", days, hours)
	elseif hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	elseif minutes > 0 then
		return string.format("%dm %02ds", minutes, secs)
	else
		return string.format("0m %02ds", secs)
	end
end

function TimeFormat.compact(seconds: number): string
	seconds = math.floor(seconds)

	if seconds <= 0 then
		return "0s"
	end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	local parts = {}

	if days > 0 then
		table.insert(parts, days .. "d")
	end
	if hours > 0 then
		table.insert(parts, hours .. "h")
	end
	if minutes > 0 then
		table.insert(parts, minutes .. "m")
	end
	if secs > 0 and #parts == 0 then
		-- Only show seconds if nothing else exists
		table.insert(parts, secs .. "s")
	end

	-- Limit to 2 biggest units (e.g. "2d 3h", not "2d 3h 5m")
	while #parts > 2 do
		table.remove(parts)
	end

	return table.concat(parts, " ")
end

function TimeFormat.short(seconds: number): string
	seconds = math.max(0, math.floor(seconds))

	if seconds <= 0 then
		return "0s"
	end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	local parts = {}

	if days > 0 then
		table.insert(parts, days .. "d")
	end

	if hours > 0 then
		table.insert(parts, hours .. "h")
	end

	if minutes > 0 then
		table.insert(parts, minutes .. "m")
	end

	if secs > 0 then
		table.insert(parts, secs .. "s")
	end

	-- Keep only the 2 largest units
	if #parts > 2 then
		parts = { parts[1], parts[2] }
	end

	return table.concat(parts, " ")
end

return TimeFormat