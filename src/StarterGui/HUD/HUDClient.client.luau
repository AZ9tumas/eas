local TweenService = game:GetService("TweenService")
local ScreenGui = script.Parent

-- Rotating Rays Animation
for _, ray in ipairs(ScreenGui:GetDescendants()) do
    if ray:GetAttribute("IsRay") then
        local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
        TweenService:Create(ray, tweenInfo, {Rotation = 360}):Play()
    end
end

-- Hover and Bouncy Button Interactions
local function bindButton(btn)
    local scaleObj = btn:FindFirstChild("UIScale")
    if not scaleObj then return end
    
    local tHover = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tRelease = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(scaleObj, tHover, {Scale = 1.08}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(scaleObj, tHover, {Scale = 1.0}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(scaleObj, TweenInfo.new(0.1), {Scale = 0.9}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(scaleObj, tRelease, {Scale = 1.08}):Play()
    end)
end

-- Hover revealing info text on boosts / events
local function bindBoostHover(wrap)
    local tipFrame = wrap:FindFirstChild("TipFrame")
    if not tipFrame then return end
    
    local tipStroke = tipFrame:FindFirstChild("UIStroke")
    local infoTxt = tipFrame:FindFirstChild("InfoText")
    local txtStroke = infoTxt and infoTxt:FindFirstChild("UIStroke") or nil
    
    local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    wrap.MouseEnter:Connect(function()
        wrap.ZIndex = 15
        TweenService:Create(tipFrame, tInfo, {BackgroundTransparency = 0}):Play()
        if tipStroke then TweenService:Create(tipStroke, tInfo, {Transparency = 0}):Play() end
        if infoTxt then TweenService:Create(infoTxt, tInfo, {TextTransparency = 0}):Play() end
        if txtStroke then TweenService:Create(txtStroke, tInfo, {Transparency = 0}):Play() end
    end)
    wrap.MouseLeave:Connect(function()
        wrap.ZIndex = 1
        TweenService:Create(tipFrame, tInfo, {BackgroundTransparency = 1}):Play()
        if tipStroke then TweenService:Create(tipStroke, tInfo, {Transparency = 1}):Play() end
        if infoTxt then TweenService:Create(infoTxt, tInfo, {TextTransparency = 1}):Play() end
        if txtStroke then TweenService:Create(txtStroke, tInfo, {Transparency = 1}):Play() end
    end)
end

-- Custom Built Shimmer logic (Simulates 'Shime' DevForum module cleanly using UIGradient Offset Tween)
local function playShimmer()
    for _, grad in ipairs(ScreenGui:GetDescendants()) do
        if grad:IsA("UIGradient") and grad:GetAttribute("IsShimmerGrad") then
            grad.Offset = Vector2.new(-1, 0)
            -- 2 secondes durée, -1 (infini), false (sans retour arrière pingpong), 2 secondes délai entre chaque passage
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 2)
            local shTween = TweenService:Create(grad, tweenInfo, {Offset = Vector2.new(1, 0)})
            shTween:Play()
        end
    end
end

playShimmer()

for _, ele in ipairs(ScreenGui:GetDescendants()) do
    if ele:GetAttribute("InteractiveBtn") then
        bindButton(ele)
    end
    if ele:GetAttribute("IsBoostTip") then
        bindBoostHover(ele)
    end
end

ScreenGui.DescendantAdded:Connect(function(child: Instance)
	if child:GetAttribute("InteractiveBtn") then
		bindButton(child)
	end
	if child:GetAttribute("IsBoostTip") then
		bindBoostHover(child)
	end
end)