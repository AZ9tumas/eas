return function (variableA: number, variableB: number, fraction: number, deltaTime: number)
	local f = 1.0 - math.pow(1.0 - fraction, deltaTime)
	return math.lerp(variableA, variableB, f)
end