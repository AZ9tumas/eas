local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shakeEvent = ReplicatedStorage:WaitForChild("ShakeEvent")

shakeEvent.OnClientEvent:Connect(function(intensity, duration)
	local cam = workspace.CurrentCamera
	local startCFrame = cam.CFrame
	local elapsed = 0

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if elapsed < duration then
			local offset = Vector3.new(
				(math.random()-0.5),
				(math.random()-0.5),
				(math.random()-0.5)
			) * intensity
			cam.CFrame = startCFrame * CFrame.new(offset)
			elapsed = elapsed + dt
		else
			cam.CFrame = startCFrame
			if connection then connection:Disconnect() end
		end
	end)
end)
