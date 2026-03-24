local TweenService = game:GetService("TweenService")
local UI = script.Parent.Parent
local Main = UI:WaitForChild("IndexMain")
local ScreenGui = UI

for _, ray in ipairs(Main:GetDescendants()) do
    if ray:GetAttribute("IsRay") then
        local tweenInfo = TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
        TweenService:Create(ray, tweenInfo, {Rotation = 360}):Play()
    end
end

local TabsScroll = Main:FindFirstChild("TabsScroll") or Main:FindFirstChildOfClass("ScrollingFrame")
local GridView = Main:FindFirstChild("GridView")

local function bindButton(btn)
    local scaleObj = btn:FindFirstChild("UIScale")
    if not scaleObj then return end
    
    local tHover = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tClick = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tRelease = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(scaleObj, tHover, {Scale = 1.05}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(scaleObj, tHover, {Scale = 1.0}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(scaleObj, tClick, {Scale = 0.9}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(scaleObj, tRelease, {Scale = 1.05}):Play()
    end)
end

local function selectTab(tabType)
    if TabsScroll then
        for _, btn in ipairs(TabsScroll:GetChildren()) do
            if btn:IsA("TextButton") then
                local main = btn:FindFirstChild("Main")
                local isSelected = (btn:GetAttribute("TabType") == tabType)
                if main then
                    local ind = main:FindFirstChild("Indicator")
                    if ind then ind.Visible = isSelected end
                    
                    if isSelected then
                        main.BackgroundTransparency = 0
                        local stroke = main:FindFirstChildOfClass("UIStroke")
                        if stroke then stroke.Transparency = 0 end
                    else
                        main.BackgroundTransparency = 0.6
                        local stroke = main:FindFirstChildOfClass("UIStroke")
                        if stroke then stroke.Transparency = 0.5 end
                    end
                end
            end
        end
    end
    
    if GridView then
        for _, card in ipairs(GridView:GetChildren()) do
            if card:GetAttribute("MutType") then
                card.Visible = (card:GetAttribute("MutType") == tabType)
            end
        end
        GridView.CanvasPosition = Vector2.new(0,0)
    end
end

for _, ele in ipairs(ScreenGui:GetDescendants()) do
    if ele:GetAttribute("InteractiveBtn") then
        bindButton(ele)
        
        if ele:GetAttribute("IsClose") then
            ele.MouseButton1Click:Connect(function()
                local mainScale = Main:FindFirstChild("MainScale")
                if mainScale then
                    TweenService:Create(mainScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play()
                    task.wait(0.2)
                end
                ScreenGui.Enabled = false
                if mainScale then mainScale.Scale = 1 end
            end)
            
        elseif ele:GetAttribute("TabType") then
            ele.MouseButton1Click:Connect(function()
                selectTab(ele:GetAttribute("TabType"))
            end)
            
        elseif ele:GetAttribute("IsCard") then
            ele.MouseButton1Down:Connect(function()
                local iconScale = ele:FindFirstChild("PetIcon") and ele.PetIcon:FindFirstChildOfClass("UIScale")
                if iconScale then TweenService:Create(iconScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.8}):Play() end
            end)
            ele.MouseButton1Up:Connect(function()
                local iconScale = ele:FindFirstChild("PetIcon") and ele.PetIcon:FindFirstChildOfClass("UIScale")
                if iconScale then 
                    TweenService:Create(iconScale, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Scale = 1.15}):Play()
                    task.delay(0.2, function() TweenService:Create(iconScale, TweenInfo.new(0.2), {Scale = 1}):Play() end)
                end
            end)
            ele.MouseLeave:Connect(function()
                local iconScale = ele:FindFirstChild("PetIcon") and ele.PetIcon:FindFirstChildOfClass("UIScale")
                if iconScale then TweenService:Create(iconScale, TweenInfo.new(0.2), {Scale = 1}):Play() end
            end)
        end
    end
end

selectTab("Default")

