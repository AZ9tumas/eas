return function() : number
	local date = DateTime.now():ToUniversalTime()
	local dt = DateTime.fromUniversalTime(
		date.Year,
		date.Month,
		date.Day,
		date.Hour,
		date.Minute,
		date.Second,
		date.Millisecond
	)

	local unixTimestamp = dt.UnixTimestamp
	return unixTimestamp
end