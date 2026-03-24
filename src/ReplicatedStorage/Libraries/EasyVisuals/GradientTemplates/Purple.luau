return function()
    local Gradient = Instance.new("UIGradient");
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0.333333, 0, 1)),
        ColorSequenceKeypoint.new(0.1510416716337204, Color3.new(0.333333, 0, 1)),
        ColorSequenceKeypoint.new(0.3072916567325592, Color3.new(0.333333, 0.333333, 1)),
        ColorSequenceKeypoint.new(0.4965277910232544, Color3.new(0.333333, 0, 1)),
        ColorSequenceKeypoint.new(0.6649305820465088, Color3.new(0.333333, 0, 1)),
        ColorSequenceKeypoint.new(0.8385416865348816, Color3.new(0.211765, 0.211765, 0.631373)),
        ColorSequenceKeypoint.new(1, Color3.new(0.333333, 0, 0.498039)),
    });
    return Gradient;
end