--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local worldEffectsFolder: Folder = workspace:FindFirstChild("Effects") :: Folder
if worldEffectsFolder == nil then
	worldEffectsFolder = Instance.new("Folder")
	worldEffectsFolder.Name = "Effects"
	worldEffectsFolder.Parent = workspace
end



return function (particlePart: BasePart, cframe: CFrame)
	local newPart = particlePart:Clone()
	newPart.Anchored = true
	newPart.CFrame = cframe
	newPart.Parent = worldEffectsFolder


	local particles = {} :: {Instance}
	local highestLifetime = 0
	for _, particle in pairs(newPart:GetDescendants()) do
		table.insert(particles, particle)
		if not particle:IsA("ParticleEmitter") then
			continue
		end

		-- particle.Rate *= getEmitMultiplier()

		local lifetime = particle.Lifetime.Max
		local emitDelay = particle:GetAttribute("EmitDelay") :: number or 0
		lifetime += emitDelay
		highestLifetime = math.max(highestLifetime, lifetime)
	end

	task.spawn(function()

		local highestDuration = 0
		for _, particle in ipairs(particles) do
			if particle:IsA("PointLight") then
				local fadeOutTime = particle:GetAttribute("FadeOutTime") :: number
				if fadeOutTime == nil then continue end
				TweenService:Create(particle, TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Brightness = 0
				}):Play()
			elseif particle:IsA("ParticleEmitter") then
				local emitCount = particle:GetAttribute("EmitCount") :: number
				-- emitCount = emitCount and emitCount * getEmitMultiplier()

				local emitDelay = particle:GetAttribute("EmitDelay") :: number
				if not emitDelay then
					particle:Emit(emitCount)
				else
					task.delay(emitDelay, function()
						particle:Emit(emitCount)
					end)
				end

				local duration = particle:GetAttribute("EmitDuration") :: number
				if duration then
					highestDuration = math.max(highestDuration, duration)

					particle.Enabled = true
					task.delay(duration, function()
						particle.Enabled = false
					end)
				end
			end
		end

		game.Debris:AddItem(newPart, highestDuration + highestLifetime)

	end)
end