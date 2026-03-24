local formatLargeNumberCustomLimit = require(script.Parent.formatLargeNumberCustomLimit)

return function (number: number): string
	return formatLargeNumberCustomLimit(number, 1000)
end