--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local observers = require(ReplicatedStorage.Shared.Utility.observers)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)

observers.observeTag("MutatingModel", function(model: Model)
	local trove = Trove.new()

	local highlight = Instance.new("Highlight")
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.fromRGB(0, 0, 0)
    highlight.FillTransparency = 1
	highlight.Parent = model
	trove:Add(highlight)

	TweenService:Create(highlight, TweenInfo.new(0.5, Enum.EasingStyle.Circular), {
		FillTransparency = 0
	}):Play()

    local waveAngle = 0
    trove:Add(RunService.Heartbeat:Connect(function(deltaTime)  
		waveAngle += deltaTime*2.5
        waveAngle %= math.pi*2

		local sineValue = -math.cos(waveAngle)
		local alpha = (sineValue + 1) * 0.5 -- from 0 to 1
        alpha = math.pow(alpha, 0.7)

		local adjustedValue = math.lerp(0, 0.45, alpha)
		highlight.FillColor = Color3.new(adjustedValue, adjustedValue, adjustedValue)
	end))

	-- Cleanup
	return function()
		trove:Clean()
	end
end)

return {}