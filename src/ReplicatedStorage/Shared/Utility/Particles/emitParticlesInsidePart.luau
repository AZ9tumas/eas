local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)


return function (particlePart: BasePart, parent: BasePart)
    local trove = Trove.new()

    local clonedParticles = particlePart:Clone()

    local particles = {} :: {Instance}
    local highestLifetime = 0
    for _, particle in pairs(clonedParticles:GetDescendants()) do
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


    for _, child in ipairs(clonedParticles:GetChildren()) do
        child.Parent = parent
        trove:Add(child)
    end


    task.spawn(function()

        local highestDuration = 0
        for _, particle in ipairs(particles) do
            if particle:IsA("PointLight") then
                local fadeOutTime = particle:GetAttribute("FadeOutTime") :: number
                if fadeOutTime == nil then 
                    continue 
                end
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
                    trove:Add(task.delay(emitDelay, function()
                        particle:Emit(emitCount)
                    end))
                end
    
                local duration = particle:GetAttribute("EmitDuration") :: number
                if duration then
                    highestDuration = math.max(highestDuration, duration)
    
                    particle.Enabled = true
                    trove:Add(task.delay(duration, function()
                        particle.Enabled = false
                    end))
                end
            end
        end
        
        task.wait(highestDuration)
        task.wait(highestLifetime)
        trove:Destroy()

    end)
end