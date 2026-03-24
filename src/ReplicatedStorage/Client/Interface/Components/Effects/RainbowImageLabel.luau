local RunService = game:GetService("RunService")

local currentColor = Color3.fromHSV(1, 1, 1)
local imageLabels = {} :: { ImageLabel }


local RainbowImageLabel = {}

function RainbowImageLabel.tagAdded(imageLabel: ImageLabel)
    imageLabel.ImageColor3 = currentColor
    table.insert(imageLabels, imageLabel)
end

function RainbowImageLabel.tagRemoved(imageLabel: ImageLabel)
    table.remove(imageLabels, table.find(imageLabels, imageLabel))
end

local fullLoop = 2.5
local currentTime = 0
RunService.Heartbeat:Connect(function(deltaTime)
    currentTime += deltaTime
    currentTime %= fullLoop
    
    local alpha = currentTime / fullLoop
    currentColor = Color3.fromHSV(alpha, 1, 1)

    for _, imageLabel in ipairs(imageLabels) do
        imageLabel.ImageColor3 = currentColor
    end
end)

return RainbowImageLabel