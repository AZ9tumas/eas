return function(n: number)
	local suffix = "th"
	if n % 100 < 11 or n % 100 > 13 then
		local lastDigit = n % 10
		if lastDigit == 1 then
			suffix = "st"
		elseif lastDigit == 2 then
			suffix = "nd"
		elseif lastDigit == 3 then
			suffix = "rd"
		end
	end
	return tostring(n) .. suffix
end