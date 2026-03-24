local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

return function (sound: Sound)
    sound = sound:Clone()
    if sound.SoundId == "" then
        sound.SoundId = sound:GetAttribute("SoundId") :: string
    end
    sound.Parent = ReplicatedStorage

    local soundDelay = sound:GetAttribute("PlayDelay") :: number
    if soundDelay and soundDelay > 0 then
        task.delay(soundDelay, function()
            sound:Play()
        end)
    else
        sound:Play()
    end
    
    local fadeDelay = sound:GetAttribute("FadeDelay") :: number
    if fadeDelay then
        task.delay(fadeDelay, function()
            local fadeTime = sound:GetAttribute("FadeTime") :: number
            fadeTime = fadeTime or 1
            TweenService:Create(sound, TweenInfo.new(fadeTime), {
                Volume = 0,
            }):Play()
        end)
    end
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    local despawnTime = sound:GetAttribute("DespawnTime") :: number
    if despawnTime == nil and sound.Looped then
        despawnTime = 10
    end
    if despawnTime then
        Debris:AddItem(sound, despawnTime)
    end

    return sound
end