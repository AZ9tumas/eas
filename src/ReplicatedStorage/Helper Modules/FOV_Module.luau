local module = {}
local TweenService = game:GetService("TweenService")
local LocalPlayer = game.Players.LocalPlayer

module.LastFOV = 70

-- Initialize the player's core FOV attribute
function module.Setup()
	LocalPlayer:SetAttribute("Core_FOV", 70)
	
	module.LastFOV = 70
end

-- Change the core FOV attribute value
function module.Change_FOV_CORE(newFOV)
	if LocalPlayer and newFOV then
		LocalPlayer:SetAttribute("Core_FOV", newFOV)
	end
end

-- Return the current core FOV attribute value
function module.Return_Core_FOV()
	return LocalPlayer:GetAttribute("Core_FOV")
end

-- Smoothly tween the camera's FieldOfView to a target value over duration seconds
function module.Change_FOV(targetFOV, duration)
	if not game.Workspace.CurrentCamera or not targetFOV then
		return
	end
	
	if module.LastFOV == targetFOV then return end
	
	module.LastFOV = targetFOV

	-- Use a default duration if none provided
	duration = duration or 0.5

	-- Add a small random variance to duration for smoothness (between 95% and 105%)
	local adjustedDuration = duration * (math.random(95, 105) / 100)

	-- Create tween info with easing
	local tweenInfo = TweenInfo.new(adjustedDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	-- Create tween to animate the FieldOfView property
	local tween = TweenService:Create(game.Workspace.CurrentCamera, tweenInfo, { FieldOfView = targetFOV })

	tween:Play()

	-- Cleanup tween object after completion
	game.Debris:AddItem(tween, adjustedDuration)
end

return module
