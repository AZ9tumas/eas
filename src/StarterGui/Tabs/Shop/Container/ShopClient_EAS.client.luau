-- Interaction Handler
local TweenService = game:GetService("TweenService")
local UI = script.Parent.Parent
local Main = script.Parent

-- 1. Apply button effects
local function bindButton(btn)
    local main = btn:FindFirstChild("Frame") or btn:FindFirstChildOfClass("Frame")
    if not main then return end
    
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local scaleObj = btn:FindFirstChild("UIScale")
    
    btn.MouseEnter:Connect(function()
        local ogColor = main.BackgroundColor3
        TweenService:Create(main, tweenInfo, {
            BackgroundColor3 = Color3.new(
                math.clamp(ogColor.R + 0.1, 0, 1),
                math.clamp(ogColor.G + 0.1, 0, 1),
                math.clamp(ogColor.B + 0.1, 0, 1)
            )
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
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(1,0,1,-5), Position = UDim2.new(0,0,0,0)}):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 1.05}):Play() end
    end)
    
    -- Specific functions
    if btn:GetAttribute("IsClose") then
        btn.Activated:Connect(function()
            UI.Enabled = false
        end)
    end
    
    local tabTarget = btn:GetAttribute("TabTarget")
    if tabTarget then
        btn.Activated:Connect(function()
            local ScrollView = Main:FindFirstChild("ScrollView")
            local target = ScrollView:FindFirstChild(tabTarget)
            if ScrollView and target then
                local offset = target.AbsolutePosition.Y - ScrollView.AbsolutePosition.Y + ScrollView.CanvasPosition.Y - 10
                TweenService:Create(ScrollView, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    CanvasPosition = Vector2.new(0, math.max(0, offset))
                }):Play()
            end
        end)
    end
end

for _, obj in pairs(Main:GetDescendants()) do
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        if obj:GetAttribute("InteractiveBtn") then
            bindButton(obj)
        end
    elseif obj:IsA("ImageLabel") and obj:GetAttribute("IsRay") then
        TweenService:Create(obj, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
    elseif obj:IsA("UIGradient") and obj.Name == "ShineGlow" then
        task.spawn(function()
            while task.wait(1.5) do
                if not obj.Parent then break end
                obj.Offset = Vector2.new(-1, 0)
                local t = TweenService:Create(obj, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
                t:Play()
                t.Completed:Wait()
            end
        end)
    elseif obj:IsA("Frame") and obj:GetAttribute("SparkleEmitter") then
        task.spawn(function()
            local rng = Random.new()
            while task.wait(0.5) do
                if not obj.Parent then break end
                local sp = Instance.new("ImageLabel")
                sp.Size = UDim2.new(0, 20, 0, 20)
                sp.Position = UDim2.new(rng:NextNumber(0, 1), 0, rng:NextNumber(0, 1), 0)
                sp.BackgroundTransparency = 1
                sp.Image = "rbxassetid://6031302836"
                sp.ImageTransparency = 1
                sp.Parent = obj
                
                TweenService:Create(sp, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {ImageTransparency = 0, Rotation = 180, Size = UDim2.new(0, 40, 0, 40)}):Play()
                game:GetService("Debris"):AddItem(sp, 2)
            end
        end)
    end
end

local sc = Main:FindFirstChildOfClass("UIScale")
if sc then
    sc.Scale = 0
    TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end
