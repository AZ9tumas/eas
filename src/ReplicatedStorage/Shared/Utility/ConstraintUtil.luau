local ConstraintUtil = {}

function ConstraintUtil.motor6D(p0: BasePart, p1: BasePart, name: string?)
	local motor = Instance.new("Motor6D")
	motor.Part0 = p0
	motor.Part1 = p1
	motor.Name  = name or p1.Name
	motor.Parent = p0

	return motor
end

function ConstraintUtil.weldConstraint(p0: BasePart, p1: BasePart, name: string?)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Name  = name or p1.Name
	weld.Parent = p1

	return weld
end

function ConstraintUtil.weld(p0: BasePart, p1: BasePart, name: string?)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Name  = name or p1.Name
	weld.Parent = p1
	
	return weld
end

function ConstraintUtil.weldRelative(p0: BasePart, p1: BasePart, name: string?)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = p0.CFrame:Inverse()
	weld.C1 = p1.CFrame:Inverse()
	weld.Name  = name or p1.Name
	weld.Parent = p1
	
	return weld
end

return ConstraintUtil