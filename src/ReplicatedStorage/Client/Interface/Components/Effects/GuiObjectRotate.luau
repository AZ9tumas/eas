local RunService = game:GetService("RunService")


local guiObjects = {} :: { [ScreenGui]: {GuiObject} }
local currentRotation = 0

local rotationSpeeds = {} :: { [GuiObject]: number? }


local GuiObjectRotate = {}

function GuiObjectRotate.tagAdded(guiObject: GuiObject)
    local parentGui = guiObject:FindFirstAncestorWhichIsA("ScreenGui")
    if parentGui == nil then
        return
    end

    if guiObjects[parentGui] == nil then
        guiObjects[parentGui] = {}
    end
    if table.find(guiObjects[parentGui], guiObject) then
        return
    end

    guiObject.Rotation = currentRotation
    table.insert(guiObjects[parentGui], guiObject)
    rotationSpeeds[guiObject] = guiObject:GetAttribute("RotationSpeed") :: number?
end

function GuiObjectRotate.tagRemoved(guiObject: GuiObject)
    rotationSpeeds[guiObject] = nil

    for _, guiObjectList in pairs(guiObjects) do
        local idx = table.find(guiObjectList, guiObject)
        if idx == nil then
            continue
        end
        table.remove(guiObjectList, idx) 
    end
end

local fullLoop = 6
local currentTime = 0
local loopMultiplier = 1 / fullLoop -- faster to multiply
RunService.Heartbeat:Connect(function(deltaTime)
    currentTime += deltaTime
    currentTime %= fullLoop
    
    local alpha = currentTime * loopMultiplier
    currentRotation = 360 * alpha

    for parentGui, guiObjectList in pairs(guiObjects) do
        -- Only update when on screen
        if not parentGui.Enabled then
            continue
        end
        for _, guiObject in ipairs(guiObjectList) do
            local rotationSpeed = rotationSpeeds[guiObject] or 1
            guiObject.Rotation = currentRotation * rotationSpeed
        end
    end
end)
    
return GuiObjectRotate