local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local ActiveTween: Tween = nil
local ActiveTweenSize: Tween = nil

-- Rotation tween (play once, no loop)
local TI = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, -1, false)

-- Size tween
local TI_Size = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false)

-- Store the original size of the object
local OriginalSize = script.Parent.Size

local function Update()
	-- Cancel any running tweens before creating new ones
	if ActiveTween then
		ActiveTween:Cancel()
		ActiveTween = nil
	end
	if ActiveTweenSize then
		ActiveTweenSize:Cancel()
		ActiveTweenSize = nil
	end

	if script.Parent.Parent.Parent.Enabled then
		-- Reset before tween
		script.Parent.Rotation = 0
		script.Parent.Size = UDim2.fromScale(0, 0)
		script.Parent.ImageTransparency = 1 -- start hidden

		-- Create tweens
		ActiveTween = TweenService:Create(
			script.Parent, 
			TI, 
			{ Rotation = 360 }
		)
		ActiveTweenSize = TweenService:Create(
			script.Parent, 
			TI_Size, 
			{ Size = OriginalSize }
		)

		-- Play tweens
		ActiveTween:Play()
		ActiveTweenSize:Play()
	else
		-- Tween back down to 0 size when hidden
		--ActiveTweenSize = TweenService:Create(
		--	script.Parent, 
		--	TI_Size, 
		--	{ Size = UDim2.fromScale(0, 0) }
		--)
		--ActiveTweenSize:Play()
	end
end

Update()

script.Parent.Parent.Parent:GetPropertyChangedSignal("Enabled"):Connect(Update)

local success, err = pcall(function()
	ContentProvider:PreloadAsync({script.Parent})
end)