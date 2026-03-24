--!nonstrict

local function getOriginalTransparency(instance: Instance, property: string): number
    local transparency = instance:GetAttribute(property) :: number
    if transparency == nil then
        transparency = instance[property]
        instance:SetAttribute(property, transparency)
    end
    return transparency
end

local function setLerpedTransparency(instance: Instance, property: string, alpha: number)
    instance[property] = math.lerp(getOriginalTransparency(instance, property), 1, alpha)
end

local function setTransparency(instance: Instance, transparency: number)
    if instance:HasTag("GuiEffect") then
        return
    end

    local alpha = transparency
    if instance:IsA("Frame") then
        setLerpedTransparency(instance, "Transparency", alpha)
    elseif instance:IsA("ImageLabel") then
        setLerpedTransparency(instance, "Transparency", alpha)
        setLerpedTransparency(instance, "ImageTransparency", alpha)
        if instance:HasTag("VisibleBackground") then
            setLerpedTransparency(instance, "BackgroundTransparency", alpha)
        end
    elseif instance:IsA("UIStroke") then
        setLerpedTransparency(instance, "Transparency", alpha)
    elseif instance:IsA("TextLabel") then
        setLerpedTransparency(instance, "TextTransparency", alpha)
    elseif instance:IsA("TextButton") then
        setLerpedTransparency(instance, "Transparency", alpha)
    end
end

return function(guiObject: GuiObject, transparency: number)
    setTransparency(guiObject, transparency)
    for _, descendant in ipairs(guiObject:GetDescendants()) do
        setTransparency(descendant, transparency)
    end
end