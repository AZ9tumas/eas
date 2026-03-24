local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = require(ReplicatedStorage.Client.ClientSettings)


return function (sound: Sound, position: Vector3)
    if not ClientSettings.MasterAudio then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = sound.Name
    attachment.WorldPosition = position

    local clone = sound:Clone()
    clone.Parent = attachment
    attachment.Parent = workspace.Terrain

    clone:Play()
    Debris:AddItem(clone, 1)
end