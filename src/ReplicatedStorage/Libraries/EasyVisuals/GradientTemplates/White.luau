return function()
    local Gradient = Instance.new("UIGradient");
    Gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
    })
    return Gradient;
end