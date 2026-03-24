-- Roblox Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Constants
local TempRandom = Random.new()

local CurrentCamera = Workspace.CurrentCamera

-- Functions
local function emitConfetti(amount: number, props: {
	size: number?,
	speed: number?,
})
	local size = props.size or 1
	local speed = props.speed or 1

	task.spawn(function()
		local ConfettiSpawned = 0

		while task.wait() do
			if ConfettiSpawned > amount then
				break
			end

			local StartingPosition = TempRandom:NextNumber(-4, 4)
			local StartingRotation = TempRandom:NextNumber(-1, 1)

			local ConfettiModel = Instance.new("Part")

			ConfettiModel.Size = Vector3.new(0.08, 0.001, 0.08)*size
			ConfettiModel.Color = Color3.fromHSV(TempRandom:NextNumber(0, 1), 0.85, 1)
			ConfettiModel.Anchored = true
			ConfettiModel.CanCollide = false
			ConfettiModel.CFrame = CurrentCamera.CFrame * CFrame.new(StartingPosition, 1, -1)
			ConfettiModel.Parent = CurrentCamera

			task.spawn(function()
				local TimeStarted = os.clock()
				local ConfettiSpeed = TempRandom:NextNumber(4, 10)/math.max(0.01, speed)
				local ConfettiRotationSpeed = TempRandom:NextNumber(15, 25)

				while true do
					local YLevel = math.clamp((os.clock() - TimeStarted) / ConfettiSpeed, 0, 1)
					local RotationLevel = math.clamp((os.clock() - TimeStarted) / ConfettiRotationSpeed, 0, 1)

					if YLevel >= 1 then
						ConfettiModel:Destroy()
						break
					end

					ConfettiModel.CFrame = CurrentCamera.CFrame
						* CFrame.new(StartingPosition, 1 - YLevel * 10, -1)
						* CFrame.Angles(
							(StartingRotation - RotationLevel) * 180,
							(StartingRotation - RotationLevel) * 180,
							0
						)

					RunService.RenderStepped:Wait()
				end
			end)

			ConfettiSpawned += 1
		end
	end)
end

return emitConfetti