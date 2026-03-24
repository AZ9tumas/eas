return function(instance: Instance, size: number)
    for _, particleEmitter in pairs(instance:GetDescendants()) do
        if not particleEmitter:IsA("ParticleEmitter") then
            continue
        end

        local newKeypoints = {}
        for _, keypoint: NumberSequenceKeypoint in ipairs(particleEmitter.Size.Keypoints) do
            table.insert(newKeypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size, keypoint.Envelope * size))
        end
        particleEmitter.Size = NumberSequence.new(newKeypoints)
    
        local currentSpeed = particleEmitter.Speed
        particleEmitter.Speed = NumberRange.new(currentSpeed.Min * size, currentSpeed.Max * size)
    end 
end