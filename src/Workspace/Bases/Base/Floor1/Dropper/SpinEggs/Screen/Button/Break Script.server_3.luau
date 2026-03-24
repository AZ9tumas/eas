local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = script.Parent
local sparksPart = folder:FindFirstChild("Break_Sparks")
local firePart = folder:FindFirstChild("Break_Fire")
local sound = folder:FindFirstChild("Break_Sound")
local enableSound = folder:FindFirstChild("Break_Enable") -- Enable sound in Break Button folder
local thruSound = folder:FindFirstChild("Break_Thru") -- Continuous red interval sound

-- Camera shake RemoteEvent (create in ReplicatedStorage)
local shakeEvent = ReplicatedStorage:WaitForChild("ShakeEvent")

-- === Sparks from Sparks Part (one-time) ===
local sparksEmitters = {}
if sparksPart then
	local endPart = sparksPart:FindFirstChild("End")
	if endPart then
		for _, v in pairs(endPart:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				table.insert(sparksEmitters, v)
			end
		end
	end
end

-- === Fire VFX (Beam, Flame, Sparks2) ===
local fireVFX = {}
local sparks2Emitters = {}
if firePart then
	for _, v in pairs(firePart:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Fire") then
			table.insert(fireVFX, v)
			-- Sparks2 specifically
			if v.Name == "Sparks2" and v:IsA("ParticleEmitter") then
				table.insert(sparks2Emitters, v)
			end
		end
	end
end

-- SETTINGS
local ANIM_TIME = 0.25          -- duration to move in/out
local PRESS_HOLD = 2             -- seconds to stay pressed
local RED_DURATION = 10          -- seconds to stay red
local SHAKE_INTENSITY = 2
local SHAKE_DURATION = 0.3

-- Save original state
local buttonPressed = false

local tweenInfo = TweenInfo.new(ANIM_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- Function to enable/disable Fire VFX
local function enableFire(enabled)
	if fireVFX then
		for _, v in pairs(fireVFX) do
			if v:IsA("ParticleEmitter") or v:IsA("Fire") then
				v.Enabled = enabled
			elseif v:IsA("Beam") then
				v.Enabled = enabled
			end
		end
	end
end

-- Function to emit Sparks from Sparks Part (one-time)
local function emitSparks()
	if sparksEmitters then
		for _, emitter in pairs(sparksEmitters) do
			emitter:Emit(10) -- emit 10 particles immediately
		end
	end
end

-- Function to enable/disable Sparks2 during red interval
local function toggleSparks2(enabled)
	if sparks2Emitters then
		for _, emitter in pairs(sparks2Emitters) do
			emitter.Enabled = enabled
		end
	end
end

-- CLICK FUNCTION
local function onClicked(player)
	if buttonPressed then return end
	buttonPressed = true

	-- Play click sound
	if sound then sound:Play() end

	-- Camera shake
	shakeEvent:FireClient(player, SHAKE_INTENSITY, SHAKE_DURATION)

	-- Enable Fire VFX (all effects)
	enableFire(true)

	-- Emit Sparks once at press
	emitSparks()

	-- Enable Sparks2 to play continuously during red interval
	toggleSparks2(true)

	-- Start Thru sound if exists
	if thruSound then
		thruSound:Play()
	end

	buttonPressed = false
end

folder:WaitForChild("Trigger").Event:Connect(function(
	isStateNormal: boolean, TurnOn: boolean?, player: Player?)
	if isStateNormal then
		return
	end
	
	if TurnOn then
		-- Disable Fire VFX and Sparks2
		enableFire(false)
		toggleSparks2(false)

		-- Stop Thru sound
		if thruSound then
			thruSound:Stop()
		end

		-- Play Enable sound
		if enableSound then
			enableSound:Play()
		end
	else
		onClicked(player)
	end
end)