local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClientSettings = require(ReplicatedStorage.Client.ClientSettings)

return function (sound: Sound, part: BasePart)
    if not ClientSettings.MasterAudio then
        return
    end

    sound = sound:Clone()
    sound.Parent = part

    local soundDelay = sound:GetAttribute("PlayDelay") :: number
    if soundDelay and soundDelay > 0 then
        task.wait(soundDelay)
    end
    sound:Play()
    
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
    return sound
end