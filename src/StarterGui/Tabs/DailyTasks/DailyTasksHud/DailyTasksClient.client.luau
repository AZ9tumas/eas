local TweenService = game:GetService("TweenService")
local Hud = script.Parent

Hud.Position = UDim2.new(0, -350, 0, 50)
TweenService:Create(Hud, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 20, 0, 50)}):Play()
