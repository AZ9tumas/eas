local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local playSound = require(ReplicatedStorage.Shared.Utility.Sounds.playSound)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds


local UIButton = {}

function UIButton.tagAdded(uiButton: Instance)
    if not uiButton:IsA("ImageButton") then
        return
    end

    local hoverConfig = { frequency = 0.3, tension = 1000, friction = 12, damping = 0.5, velocity = 0.001 } :: ripple.SpringOptions
    local rotationConfig = { frequency = 0.2, tension = 1000, friction = 12, damping = 0.5, velocity = 0.001 } :: ripple.SpringOptions
    local clickConfig = { frequency = 0.15, tension = 1000, friction = 12, damping = 0.4, velocity = 0.001 } :: ripple.SpringOptions

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = uiButton

    local icon = uiButton:FindFirstChild("Icon") :: ImageLabel
    local titleLabel = uiButton:FindFirstChild("TitleLabel")  :: TextLabel


    local shouldRotateIcon = uiButton.Name ~= "TimeRewards"

    local motion = ripple.createMotion({
        scale = 1,
        rotation = 0,
    })
    motion:onStep(function(value, deltaTime)
        uiScale.Scale = value.scale
        if shouldRotateIcon then
            icon.Rotation = value.rotation
            titleLabel.Rotation = value.rotation
        end
    end)
    motion:start()


    local scale = uiButton:GetAttribute("HoverScale") :: number or 0.02
    local hoveredScale = 1 + scale
    local pressedScale = 1 - scale/2


    local originalZIndex = uiButton.ZIndex
    uiButton.Activated:Connect(function()
        playSound(sounds.Interface.ButtonClick)
    end)
    uiButton.MouseButton1Up:Connect(function()
        motion:to({
            scale = ripple.spring(hoveredScale, hoverConfig),
        })
    end)
    uiButton.MouseButton1Down:Connect(function()
        motion:to({
            scale = ripple.spring(pressedScale, clickConfig),
        })
    end)
    uiButton.MouseEnter:Connect(function()
        motion:to({
            scale = ripple.spring(hoveredScale, hoverConfig),
            rotation = ripple.spring(math.random(1, 2) == 1 and 3 or -3, rotationConfig),
        })

        playSound(sounds.Interface.ButtonHover)
        uiButton.ZIndex = originalZIndex + 10
    end)
    uiButton.MouseLeave:Connect(function()
        motion:to({
            scale = ripple.spring(1, hoverConfig),
            rotation = ripple.spring(0, rotationConfig),
        })

        uiButton.ZIndex = originalZIndex
    end)
end

return UIButton