local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mouseEnterAndMouseLeave = require(ReplicatedStorage.Client.Interface.Utility.mouseEnterAndMouseLeave)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local playSound = require(ReplicatedStorage.Shared.Utility.Sounds.playSound)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds


local highlightFrameTemplate = Instance.new("Frame")
highlightFrameTemplate.ZIndex = 2
highlightFrameTemplate.Size = UDim2.fromScale(1, 1)
highlightFrameTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
highlightFrameTemplate.Transparency = 1
highlightFrameTemplate.Active = false
highlightFrameTemplate.Interactable = false
highlightFrameTemplate:AddTag("GuiEffect")
highlightFrameTemplate.Name = "HighlightFrame"

local troves = {} :: {
    [GuiButton]: Trove.Trove
}


local BaseButton = {}

function BaseButton.tagAdded(baseButton: GuiButton)
    if not baseButton:IsA("GuiButton") then
        warn(baseButton, "isn't a GuiButton!")
        return
    end

    local hoverConfig = { frequency = 0.25, tension = 1000, friction = 12, damping = 1, velocity = 0.001 } :: ripple.SpringOptions
    local clickConfig = { frequency = 0.15, tension = 1000, friction = 12, damping = 1, velocity = 0.001 } :: ripple.SpringOptions

    for _, uiScale in pairs(baseButton:GetChildren()) do
        if not uiScale:IsA("UIScale") then
            continue
        end
        uiScale:Destroy() -- Will mess up scaling if we don't clear out other ones
    end

    local trove = Trove.new()
    troves[baseButton] = trove

    local uiScale = Instance.new("UIScale")
    local baseButtonScaleFrame = baseButton:FindFirstChild("BaseButtonScale") :: Frame 
    uiScale.Parent = baseButtonScaleFrame or baseButton
    trove:Add(uiScale)


	local autoButtonColor = (baseButton.AutoButtonColor and baseButton.BackgroundTransparency ~= 1)
		or baseButton:HasTag("AutoButtonColor")
    if autoButtonColor then
        trove:Add(function()
            baseButton.AutoButtonColor = true
        end)
        baseButton.AutoButtonColor = false
    end


    local uiStroke = baseButton:FindFirstChildOfClass("UIStroke")
    local originalColor = if uiStroke then uiStroke.Color else Color3.fromRGB()
    local highlightColor = Color3.new(1, 1, 1):Lerp(originalColor, 0.8)

    local effectTrove = trove:Extend()
    local function doHighlightEffect()
        local highlightFrame = highlightFrameTemplate:Clone()
        local uiCorner = baseButton:FindFirstChildOfClass("UICorner")
        if uiCorner then
            uiCorner:Clone().Parent = highlightFrame
        end 

        local folder = Instance.new("Folder")
        folder.Name = "Effects"
        highlightFrame.Transparency = 0.8
        highlightFrame.Parent = folder
        folder.Parent = baseButton
        effectTrove:Add(folder)
        effectTrove:Add(function()
            if uiStroke then
                uiStroke.Color = originalColor
            end
        end)
        
        if uiStroke then
            uiStroke.Color = highlightColor
        end
    end



    local scale = baseButton:GetAttribute("HoverScale") :: number
    scale = scale or 0.06
    local hoveredScale = 1 + scale
    local pressedScale = 1 - scale/2


    local motion = ripple.createMotion(1)
    motion:onStep(function(value, deltaTime)
        if scale == 0 then
            return
        end
        uiScale.Scale = value
    end)


    trove:Add(baseButton.Activated:Connect(function()
        playSound(sounds.Interface.ButtonClick)
    end))
    trove:Add(baseButton.MouseButton1Up:Connect(function()
        motion:spring(hoveredScale, hoverConfig)
    end))
    trove:Add(baseButton.MouseButton1Down:Connect(function()
        motion:spring(pressedScale, clickConfig)
    end))

    local mouseEnterFn = function()
        if not baseButton.Active then
            return
        end
        if autoButtonColor then
			doHighlightEffect()
		end

        motion:spring(hoveredScale, hoverConfig)
        playSound(sounds.Interface.ButtonHover)
    end
    local mouseLeaveFn = function()
        if not baseButton.Active then
            return
        end

        effectTrove:Clean()
        motion:spring(1, hoverConfig)
    end
    trove:Add(mouseEnterAndMouseLeave(baseButton, mouseEnterFn, mouseLeaveFn))
end

function BaseButton.tagRemoved(baseButton: GuiButton)
    troves[baseButton]:Destroy()
    troves[baseButton] = nil
end

return BaseButton