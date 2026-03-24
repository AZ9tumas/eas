local STUDIO_VIEWPORT_SIZE = Vector2.new(2000, 800)

return function(topLevelFrame: GuiObject): Vector2
    local size = topLevelFrame.Size
    local absoluteSizeX, absoluteSizeY = size.X.Offset + size.X.Scale * STUDIO_VIEWPORT_SIZE.X, size.Y.Offset + size.Y.Scale * STUDIO_VIEWPORT_SIZE.Y

    local uiAspectRatioConstraint = topLevelFrame:FindFirstChildOfClass("UIAspectRatioConstraint")
    if uiAspectRatioConstraint ~= nil then
        local constraintRatio = uiAspectRatioConstraint.AspectRatio
        local frameRatio = absoluteSizeX / absoluteSizeY

        -- Size Y limited, so scale down
        if frameRatio < constraintRatio then
            absoluteSizeY = absoluteSizeX / constraintRatio
        else
            absoluteSizeX = absoluteSizeY * constraintRatio
        end
    end

    return Vector2.new(absoluteSizeX, absoluteSizeY)
end