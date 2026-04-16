-- SERVICES
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- REMOTE EVENT
local ShakeEvent = ReplicatedStorage:WaitForChild("ExplosionShake")

-- REFERENCES
local EggsFolder = script.Parent
local EggCombineComplete = EggsFolder:WaitForChild("EggCombineComplete")
local Egg1 = EggsFolder:WaitForChild("Egg1")
local Egg2 = EggsFolder:WaitForChild("Egg2")
local Egg3 = EggsFolder:WaitForChild("Egg3")
local EggCombine = EggsFolder:WaitForChild("EggCombine")

local ExplosionPart = EggsFolder:WaitForChild("ExplosionPart")
local ExplosionSound = EggsFolder:WaitForChild("ExplosionSound")
local DragSound = EggsFolder:WaitForChild("DragSound")

local Panels = {
	EggsFolder:WaitForChild("Panel1"),
	EggsFolder:WaitForChild("Panel2"),
	EggsFolder:WaitForChild("Panel3")
}

local Dings = {
	EggsFolder:WaitForChild("Ding1"),
	EggsFolder:WaitForChild("Ding2"),
	EggsFolder:WaitForChild("Ding3")
}

local MainDing = EggsFolder:WaitForChild("MainDing")

-- SETTINGS
local PANEL_FADE = 0.12
local LIGHT_PULSE_UP = 0.08
local LIGHT_PULSE_DOWN = 0.06
local CONFIRM_FLASH = 0.15
local MOVE_TIME = 2.0
local BUSY = false

local COMBINE_ROTATION = CFrame.fromOrientation(math.rad(90), math.rad(-90), 0)

-- PREP PANELS
for _, panel in ipairs(Panels) do
	panel.Transparency = 1
	panel.CanCollide = false
	panel.Light1.Light.Enabled = false
	panel.Light1.Light.Brightness = 0
end

-------------------------------------------------
-- PANEL CHECK SEQUENCE
-------------------------------------------------
local function panelCheckSequence()
	-- Phase 1: individual flashes (fast)
	for i, panel in ipairs(Panels) do
		local light = panel.Light1.Light
		local ding = Dings[i]

		local fadeIn = TweenService:Create(panel, TweenInfo.new(PANEL_FADE), {Transparency = 0})
		fadeIn:Play()
		fadeIn.Completed:Wait()

		light.Enabled = true
		local pulseUp = TweenService:Create(light, TweenInfo.new(LIGHT_PULSE_UP), {Brightness = 6})
		pulseUp:Play()
		ding:Play()
		pulseUp.Completed:Wait()

		local pulseDown = TweenService:Create(light, TweenInfo.new(LIGHT_PULSE_DOWN), {Brightness = 0})
		pulseDown:Play()
		pulseDown.Completed:Wait()
		light.Enabled = false

		local fadeOut = TweenService:Create(panel, TweenInfo.new(PANEL_FADE), {Transparency = 1})
		fadeOut:Play()
		fadeOut.Completed:Wait()
	end

	-- Phase 2: confirmation flash (all together)
	-- Step 1: enable lights and transparency
	for _, panel in ipairs(Panels) do
		panel.Transparency = 0
		panel.Light1.Light.Enabled = true
	end

	-- Step 2: flash all lights (no waiting)
	for _, panel in ipairs(Panels) do
		local flash = TweenService:Create(panel.Light1.Light, TweenInfo.new(CONFIRM_FLASH), {Brightness = 8})
		flash:Play()
	end

	-- Step 3: immediately play MainDing while lights are animating
	MainDing:Play()

	-- Step 4: after small delay, fade panels and lights
	task.wait(CONFIRM_FLASH) -- let the flash show briefly
	for _, panel in ipairs(Panels) do
		local flashDown = TweenService:Create(panel.Light1.Light, TweenInfo.new(CONFIRM_FLASH), {Brightness = 0})
		flashDown:Play()
		panel.Light1.Light.Enabled = false

		local fadeOut = TweenService:Create(panel, TweenInfo.new(CONFIRM_FLASH), {Transparency = 1})
		fadeOut:Play()
	end

	-- Wait a little to make sure fade finishes
	task.wait(CONFIRM_FLASH + 0.05)
end

-------------------------------------------------
-- MAGNETIC PULL
-------------------------------------------------
local function magneticPull(model, targetCF)
	local startCF = model:GetPivot()
	local alpha = Instance.new("NumberValue")

	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = alpha.Value
		local smoothT = t * t * (3 - 2 * t)
		local accelT = smoothT ^ 1.5
		local wobble = math.sin(accelT * math.pi * 4) * 0.06
		local spin = CFrame.Angles(0, math.rad(120 * accelT), wobble)
		model:PivotTo(startCF:Lerp(targetCF, accelT) * spin)
	end)

	TweenService:Create(alpha, TweenInfo.new(MOVE_TIME), {Value = 1}):Play()
	task.wait(MOVE_TIME)
	conn:Disconnect()
end

-------------------------------------------------
-- EXPLOSION
-------------------------------------------------
local function explode(centerCF)
	ExplosionPart.CFrame = CFrame.new(centerCF.Position) * CFrame.fromOrientation(0, math.rad(-90), 0)
	ExplosionSound:Play()
	ShakeEvent:FireAllClients()

	for _, obj in ipairs(ExplosionPart:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			obj.Enabled = true
			obj:Emit(120)
		elseif obj:IsA("Beam") then
			obj.Enabled = true
		end
	end

	task.delay(0.5, function()
		for _, obj in ipairs(ExplosionPart:GetDescendants()) do
			if obj:IsA("ParticleEmitter") or obj:IsA("Beam") then
				obj.Enabled = false
			end
		end
	end)
end

-------------------------------------------------
-- MAIN SEQUENCE
-------------------------------------------------
local function combineEggs()
	if BUSY then return end
	BUSY = true
	local centerCF = Egg2:GetPivot()

	-- Panels ritual
	panelCheckSequence()

	-- Start drag sound & magnetic pull
	DragSound:Play()
	task.spawn(function() magneticPull(Egg1, centerCF) end)
	task.spawn(function() magneticPull(Egg3, centerCF) end)

	task.wait(MOVE_TIME)
	DragSound:Stop()

	-- Explosion
	explode(centerCF)

	-- Remove old eggs
	Egg1:Destroy()
	Egg2:Destroy()
	Egg3:Destroy()
	
	EggCombineComplete.Value = true

	-- Spawn combined egg
	EggCombine.Parent = EggsFolder
	EggCombine:PivotTo(CFrame.new(centerCF.Position) * COMBINE_ROTATION)
	
	task.delay(2.5, function()
		script.Parent:Destroy()
	end)
end

-------------------------------------------------
-- AUTO START
-------------------------------------------------
task.wait(0.5)
combineEggs()
