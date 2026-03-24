local function setTransparency(instance: Instance, transparency: number)
    if instance:HasTag("GuiEffect") then
        return
    end
    if instance:IsA("Frame") then
        instance.Transparency = transparency
    elseif instance:IsA("ImageLabel") then
        instance.ImageTransparency = transparency
        if instance:HasTag("VisibleBackground") then
            instance.BackgroundTransparency = transparency
        end
    elseif instance:IsA("UIStroke") then
        instance.Transparency = transparency
    elseif instance:IsA("TextLabel") then
        instance.TextTransparency = transparency
    elseif instance:IsA("TextButton") then
        instance.Transparency = transparency
    end
end

return function(guiObject: GuiObject, transparency: number)
    setTransparency(guiObject, transparency)
    for _, descendant in ipairs(guiObject:GetDescendants()) do
        setTransparency(descendant, transparency)
    end
end