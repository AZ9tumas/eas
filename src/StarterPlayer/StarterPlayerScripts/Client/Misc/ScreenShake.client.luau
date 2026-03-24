local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local ShakeEvent = ReplicatedStorage:WaitForChild("ExplosionShake")

local SHAKE_DURATION = 0.35
local SHAKE_INTENSITY = 0.8

local function screenShake()
	local startTime = tick()
	local originalCF = camera.CFrame

	local conn
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > SHAKE_DURATION then
			camera.CFrame = originalCF
			conn:Disconnect()
			return
		end

		local strength = (1 - (elapsed / SHAKE_DURATION)) * SHAKE_INTENSITY
		local offset = Vector3.new((math.random()-0.5)*strength, (math.random()-0.5)*strength, 0)
		camera.CFrame = originalCF * CFrame.new(offset)
	end)
end

ShakeEvent.OnClientEvent:Connect(screenShake)
