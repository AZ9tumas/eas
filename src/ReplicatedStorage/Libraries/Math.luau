local module = {}

function module.calculateAveragePosition(Parts: {}?): Vector3
	local total = Vector3.new()
	for _, Part in Parts do    
		total += Part.Position
	end
	return total / #Parts
end

function module.calculateAverageMagnitude(MainPart: Part, Parts: {}?): number
	local total = 0
	for _, Part in Parts do    
		total += (Part.Position - MainPart.Position).Magnitude
	end

	return total / #Parts
end


function module.ToMilliseconds(totalSeconds)
	local hours = math.floor(totalSeconds / 3600)
	local remainingAfterHours = totalSeconds - (hours * 3600)
	local minutes = math.floor(remainingAfterHours / 60)
	local remainingSeconds = remainingAfterHours - (minutes * 60)
	local seconds = math.floor(remainingSeconds)
	local remainingMilliseconds = remainingSeconds - seconds
	local milliseconds = math.floor(remainingMilliseconds * 1000)

	return string.format("%d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
end


function module.SecondsToTime(totalSeconds)
	local secondsInAnHour = 3600
	local secondsInAMinute = 60

	local hours = math.floor(totalSeconds / secondsInAnHour)
	local minutes = math.floor((totalSeconds % secondsInAnHour) / secondsInAMinute)
	local seconds = totalSeconds % secondsInAMinute

	if hours > 0 then
		return string.format("%02d:%02d:%02d",hours, minutes, seconds)
	else
		return string.format("%02d:%02d", minutes, seconds)
	end
end

function module.CommaValue(amount)
	local formatted = amount
	local k
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

return module
