local TweenService = game:GetService("TweenService")

-- === REFERENCES ===
local folder = script.Parent
local buttonPart = folder
local vfxPart = folder:WaitForChild("vfxpart1")
local sound = folder:FindFirstChild("Sound")

-- SECOND VFX: Sparks --> End --> Sparks
local sparksPart = folder:FindFirstChild("Sparks")
local sparksEmitter
if sparksPart then
	local endPart = sparksPart:FindFirstChild("End")
	if endPart then
		sparksEmitter = endPart:FindFirstChildWhichIsA("ParticleEmitter", true)
	end
end

-- ParticleEmitter references (do NOT change properties)
local particles = vfxPart:FindFirstChildWhichIsA("ParticleEmitter", true)

-- === SETTINGS ===
local PRESS_DISTANCE = 0.08
local ANIM_TIME = 0.35     -- slightly slower for smoother motion
local PRESS_HOLD = 0.05
local debounce = false

-- TARGET POSITION (for button direction)
local TARGET_POSITION = Vector3.new(-415.448, 7.64, 117.78)

-- Save original state
local originalPosition = buttonPart.Position
local originalCFrame = buttonPart.CFrame

-- Use Back easing for more natural press & release
local tweenInfo = TweenInfo.new(
	ANIM_TIME,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

-- === CLICK FUNCTION ===
local function onClicked()
	if debounce then return end
	debounce = true

	-- Play sound
	if sound then
		sound:Play()
	end

	-- Spawn first VFX once
	if particles then
		particles:Emit(1)
	end

	-- Spawn sparks VFX once
	if sparksEmitter then
		sparksEmitter:Emit(8)
	end

	-- Move button toward target
	local direction = (TARGET_POSITION - originalPosition).Unit
	local pressedPosition = originalPosition + (direction * PRESS_DISTANCE)
	local pressedCFrame = CFrame.new(pressedPosition) * originalCFrame.Rotation

	local pressTween = TweenService:Create(buttonPart, tweenInfo, {CFrame = pressedCFrame})
	pressTween:Play()
	pressTween.Completed:Wait()

	task.wait(PRESS_HOLD)

	-- Smooth return using same easing
	local returnTween = TweenService:Create(buttonPart, tweenInfo, {CFrame = originalCFrame})
	returnTween:Play()
	returnTween.Completed:Wait()

	debounce = false
end

folder:WaitForChild("Trigger").Event:Connect(function(stateIsNormal: boolean?)
	if stateIsNormal then
		onClicked()
	end
end)
