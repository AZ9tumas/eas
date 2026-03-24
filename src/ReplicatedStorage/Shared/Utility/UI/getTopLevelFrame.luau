return function(instance: Instance): GuiObject?
    local topLevelFrame: Instance? = nil
    local parent: Instance? = instance
    repeat
        topLevelFrame = parent
        parent = (parent :: any).Parent :: Instance?
    until parent == nil or parent:IsA("ScreenGui")

    if topLevelFrame == nil then
        warn("[getTopLevelFrame] Failed to find top level frame for:", instance)
    end
    if topLevelFrame == nil or not topLevelFrame:IsA("GuiObject") then
        return nil
    end
    
    return topLevelFrame
end