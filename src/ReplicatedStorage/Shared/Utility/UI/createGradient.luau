local ReplicatedStorage = game:GetService("ReplicatedStorage")

local removeGradient = require(script.Parent.removeGradient)

local assets = ReplicatedStorage.Assets
local gradients = assets.Interface.Gradients

return function(name: string, parent: Instance, condition: boolean?): UIGradient?
    if condition == false then
        removeGradient(name, parent)
        return
    end

    if parent:FindFirstChild(name) then
        return
    end

    local baseGradient = gradients:FindFirstChild(name)
    if baseGradient == nil then
        warn("[CreateGradient] Couldn't find gradient with the name:", name)
        return
    end

    if parent:IsA("GuiObject") then
        parent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end

    local clone = baseGradient:Clone() :: UIGradient
    clone.Parent = parent
    return clone
end