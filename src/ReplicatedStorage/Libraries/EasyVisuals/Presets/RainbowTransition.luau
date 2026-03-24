--@raw
local RunService = game:GetService("RunService")
function zigzag(X) return math.acos(math.cos(X*math.pi))/math.pi end



local TextEffects = require(script.Parent.Parent);

return function(uiInstance: GuiObject, Speed: number)
	local MainGradient = TextEffects.Gradient.new(uiInstance, TextEffects.Templates.White.Color, 0)
	
	local t = Speed; --how long does it take to go through the rainbow

	local tick = tick
	local fromHSV = Color3.fromHSV
	
	local Connection
	
	Connection = RunService.Heartbeat:Connect(function(dt)
		if not uiInstance.Visible then return end
		local hue = tick() % t / t
		local color = fromHSV(hue, 1, 1)
		MainGradient.Instance.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, color),
			ColorSequenceKeypoint.new(1, color),
		})
	end)
	MainGradient:Pause()
	return {
		Effects = { MainGradient };
		Connections = { Connection }
    };
end