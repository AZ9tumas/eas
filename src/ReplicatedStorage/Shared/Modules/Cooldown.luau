local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)


local Cooldown = {}

function Cooldown.setCooldown(instance: Instance, attribute: string, cooldown: number)
    local now = workspace:GetServerTimeNow()
    local currentCD = instance:GetAttribute(attribute) :: number?
    if currentCD and currentCD - now > cooldown then
        return
    end
    instance:SetAttribute(attribute, now + cooldown)

    local trove = Trove.new()
    trove:AttachToInstance(instance)
    trove:Add(task.delay(cooldown, function()
        trove:Destroy()
        instance:SetAttribute(attribute, nil)
    end))
    trove:Connect(instance:GetAttributeChangedSignal(attribute), function()
        trove:Destroy()
    end)
end

function Cooldown.removeCooldown(instance: Instance, attribute: string)
    instance:SetAttribute(attribute, nil)
end

function Cooldown.getCooldown(instance: Instance, attribute: string)
    local value = instance:GetAttribute(attribute) :: number?
    return value and math.max(0, value - workspace:GetServerTimeNow())
end

function Cooldown.isOnCooldown(instance: Instance, attribute: string, lagCompensation: number | nil)
    local value = instance:GetAttribute(attribute) :: number?
    if value and lagCompensation then
        value += lagCompensation
    end
    return value and value - workspace:GetServerTimeNow() > 0
end

return Cooldown