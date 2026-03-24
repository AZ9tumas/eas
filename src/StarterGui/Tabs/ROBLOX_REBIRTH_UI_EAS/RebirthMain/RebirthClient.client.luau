local TweenService = game:GetService("TweenService")
local UI = script.Parent.Parent
local Main = UI:WaitForChild("RebirthMain")
local ScreenGui = UI

-- Animation for rays
for _, ray in ipairs(Main:GetDescendants()) do
    if ray:GetAttribute("IsRay") then
        local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
        TweenService:Create(ray, tweenInfo, {Rotation = 360}):Play()
    end
end

-- Fonction pour rendre les éléments visuellement interactifs
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
        -- Effet de dézoom super rapide au clic
        TweenService:Create(scaleObj, tClick, {Scale = 0.85}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        -- Rebond (Bounce) au relâchement
        TweenService:Create(scaleObj, tRelease, {Scale = 1.05}):Play()
    end)
end

for _, ele in ipairs(Main:GetDescendants()) do
    if ele:GetAttribute("InteractiveBtn") then
        bindButton(ele)
        
        -- Logic spécifique pour le bouton X (fermeture seamless)
        if ele:GetAttribute("IsClose") then
            ele.Activated:Connect(function()
                local mainScale = Main:FindFirstChild("MainScale")
                if mainScale then
                    -- Animation de fermeture de toute la fenêtre
                    TweenService:Create(mainScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play()
                    task.wait(0.2)
                end
                ScreenGui.Enabled = false
                if mainScale then mainScale.Scale = 1 end -- Reset au cas où tu la rouvres
            end)
            
        -- Logic spécifique pour le bouton d'Action (Rebirth)
        elseif ele.Name == "ActionBtn" then
            ele.Activated:Connect(function()
                
                local notif = Main:FindFirstChild("ErrorNotif")
                
                if notif then
                    -- Récupérer les éléments visuels de l'erreur
                    local stroke = notif:FindFirstChildOfClass("UIStroke")
                    local shadow = notif:FindFirstChildOfClass("TextLabel")
                    local shadowStr = shadow and shadow:FindFirstChildOfClass("UIStroke")
                    
                    -- Reset l'état avant d'animer
                    notif.Position = UDim2.new(0.5, 0, 0, -20)
                    notif.TextTransparency = 0
                    if stroke then stroke.Transparency = 0 end
                    if shadow then shadow.TextTransparency = 0 end
                    if shadowStr then shadowStr.Transparency = 0.5 end
                    
                    -- L'erreur "pop" en rebondissant vers le haut
                    local tMove = TweenService:Create(notif, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, -50)})
                    tMove:Play()
                    
                    -- Disparaît doucement après 2 secondes
                    task.delay(2, function()
                        TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, Position = UDim2.new(0.5, 0, 0, -70)}):Play()
                        if stroke then TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 1}):Play() end
                        if shadow then TweenService:Create(shadow, TweenInfo.new(0.5), {TextTransparency = 1}):Play() end
                        if shadowStr then TweenService:Create(shadowStr, TweenInfo.new(0.5), {Transparency = 1}):Play() end
                    end)
                end
            end)
        end
    end
end
