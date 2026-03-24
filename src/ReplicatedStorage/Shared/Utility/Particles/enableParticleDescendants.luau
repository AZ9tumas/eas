local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local ripple = require(ReplicatedStorage.Shared.Classes.ripple)


return function(instance: BasePart, enabled: boolean, springOptions: ripple.SpringOptions?)

    local originalTransparencies: { [Beam | ParticleEmitter | Trail]: NumberSequence } = {}
    for _, descendant in pairs(instance:GetDescendants()) do
        if descendant:IsA("Beam") or descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            originalTransparencies[descendant] = descendant.Transparency
        end
    end

    local trove = Trove.new()
    trove:AttachToInstance(instance)
    trove:Add(instance:GetPropertyChangedSignal("Transparency"):Connect(function()
        trove:Destroy()
    end))

    local motion = ripple.createMotion(0)
    motion:onStep(function(t)
        for particle, originalValue in pairs(originalTransparencies) do
            local newKeypoints = {}
            for i, keypoint: NumberSequenceKeypoint in pairs(originalValue.Keypoints) do
                table.insert(
                    newKeypoints, 
                    NumberSequenceKeypoint.new( keypoint.Time, math.lerp( if enabled then 1 else keypoint.Value, if enabled then keypoint.Value else 1, t) 
                ))
            end
            (particle :: any).Transparency = NumberSequence.new(newKeypoints)
        end
        if t >= 1 then
            trove:Clean()
        end
    end)
    motion:spring(1, springOptions or { frequency = 0.4, tension = 1000, friction = 20, damping = 1 })
    trove:Add(motion.stop)
end
