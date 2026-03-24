return function(str: string)
	 --match one or more digits at the start of the string
	--local number = str:match("^(%d+)")
	local number = str:match("(%d+)")
	if number then
		return tonumber(number)
	else
		return nil -- if no number found
	end
end