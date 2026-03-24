return function (cfA: CFrame, cfB: CFrame)

	local posMag = (cfA.Position - cfB.Position).Magnitude
	if (posMag > 0.01) then
		return false
	end
	local rotMag = (cfA.LookVector - cfB.LookVector).Magnitude
	if (rotMag > 0.01) then
		return false
	end
	return true
end