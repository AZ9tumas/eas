local TweenService = game:GetService("TweenService")
local UI = script.Parent.Parent
local Main = script.Parent

local function bindButton(btn)
    local main = btn:FindFirstChild("Frame") or btn:FindFirstChildOfClass("Frame")
    if not main then return end
    
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local scaleObj = btn:FindFirstChild("UIScale")
    
    btn.MouseEnter:Connect(function()
        local ogColor = main.BackgroundColor3
        TweenService:Create(main, tweenInfo, {
            BackgroundColor3 = Color3.new(math.clamp(ogColor.R+0.1,0,1), math.clamp(ogColor.G+0.1,0,1), math.clamp(ogColor.B+0.1,0,1))
        }):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 1.05}):Play() end
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(main, tweenInfo, {BackgroundColor3 = Color3.new(1,1,1)}):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 1}):Play() end
    end)
    
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0)}):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 0.95}):Play() end
    end)
    
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(1,0,1,-btn.Size.Y.Offset * 0.1), Position = UDim2.new(0,0,0,0)}):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 1.05}):Play() end
    end)
    
    if btn:GetAttribute("IsClose") then
        btn.Activated:Connect(function() UI.Enabled = false end)
    end
end

for _, obj in pairs(Main:GetDescendants()) do
    if obj:IsA("TextButton") and obj:GetAttribute("InteractiveBtn") then
        bindButton(obj)
    end
end

local sc = Main:FindFirstChildOfClass("UIScale")
if sc then
    sc.Scale = 0
    TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end
