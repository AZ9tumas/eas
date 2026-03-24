local module = {}
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Try to find an existing BlurEffect or a Blur named "Blur"
local blur = Lighting:FindFirstChildOfClass("BlurEffect") or Lighting:FindFirstChild("Blur")

-- If not found, create a new BlurEffect named "Blur"
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Name = "Blur"
	blur.Size = 0 -- start with no blur
	blur.Parent = Lighting
end

-- Utility function to tween blur size
-- size: target blur size (number)
-- duration: tween duration in seconds (number)
function module.Blur(size, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenGoal = { Size = size }

	local tween = TweenService:Create(blur, tweenInfo, tweenGoal)
	tween:Play()

	tween.Completed:Connect(function()
		tween:Destroy()
	end)
end

return module