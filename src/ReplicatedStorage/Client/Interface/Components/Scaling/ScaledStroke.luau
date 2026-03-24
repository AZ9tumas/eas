local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local getTopLevelFrame = require(ReplicatedStorage.Shared.Utility.UI.getTopLevelFrame)
local getTopLevelFrameAbsoluteSize = require(ReplicatedStorage.Shared.Utility.UI.getTopLevelFrameAbsoluteSize)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui


local screenStrokes = {} :: { 
    [GuiObject]: {
        [UIStroke]: number
    } 
}

local lastFrameSizes = {} :: {
    [GuiObject]: Vector2
}


local ScaledStroke = {}

function ScaledStroke.tagAdded(uiStroke: UIStroke)
    if not uiStroke:IsA("UIStroke") then
        return
    end
    if not uiStroke:IsDescendantOf(playerGui) then
        return
    end
    if uiStroke:IsDescendantOf(playerGui.Templates) then
        return
    end

    local topLevelFrame = getTopLevelFrame(uiStroke)
    if topLevelFrame == nil then
        return
    end

    if screenStrokes[topLevelFrame] == nil then
        screenStrokes[topLevelFrame] = {}
    end

    local strokes = screenStrokes[topLevelFrame]
    if strokes[uiStroke] then
        return
    end
    
    -- We can divide by absolute size here, so that when it's multiplied later we get the right thickness
    local absoluteSize = getTopLevelFrameAbsoluteSize(topLevelFrame)
    local thickness = uiStroke.Thickness
    local adjustedThickness = thickness / absoluteSize.Y
    strokes[uiStroke] = adjustedThickness

    local currentAbsoluteSize = topLevelFrame.AbsoluteSize
    uiStroke.Thickness = adjustedThickness * currentAbsoluteSize.Y
end

function ScaledStroke.tagRemoved(uiStroke: UIStroke)
    if not uiStroke:IsA("UIStroke") then
        return
    end
    for _, strokes in pairs(screenStrokes) do
        strokes[uiStroke] = nil
    end
end



local updating = false
local function updateScreenStrokes()
    if updating then
        return
    end

    updating = true
	for topLevelFrame, strokes in pairs(screenStrokes) do
        local absoluteSize = topLevelFrame.AbsoluteSize

        -- Reduce calculations as much as possible, if size hasn't changed don't update
        if lastFrameSizes[topLevelFrame] == absoluteSize then
            continue
        end
        
        lastFrameSizes[topLevelFrame] = absoluteSize
        for uiStroke, originalThickness in pairs(strokes) do
            -- "originalThickness" is divided by absolute size already, multiplying it back brings it back
            uiStroke.Thickness = originalThickness * absoluteSize.Y
        end
    end
    updating = false
end
task.spawn(updateScreenStrokes)

local updateFrequency = 0.2
local lastUpdate = time()
RunService.Heartbeat:Connect(function()
    local now = time()
    if now - lastUpdate < updateFrequency then
        return
    end
    lastUpdate = now
    updateScreenStrokes()
end)

return ScaledStroke