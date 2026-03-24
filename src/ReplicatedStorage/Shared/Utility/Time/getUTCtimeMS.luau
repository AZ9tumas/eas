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

	local unixTimestamp = dt.UnixTimestampMillis
	return unixTimestamp / 1000
end