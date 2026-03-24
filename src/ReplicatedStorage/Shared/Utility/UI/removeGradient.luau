return function(name: string, parent: Instance)
    local baseGradient = parent:FindFirstChild(name)
    if baseGradient == nil or not baseGradient:IsA("UIGradient") then
        return
    end

    baseGradient:Destroy()
end