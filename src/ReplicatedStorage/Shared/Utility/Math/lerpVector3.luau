return function (variableA: Vector3, variableB: Vector3, fraction: number, deltaTime: number)
	local f = 1.0 - math.pow(1.0 - fraction, deltaTime)
	return variableA:Lerp(variableB, f)
end