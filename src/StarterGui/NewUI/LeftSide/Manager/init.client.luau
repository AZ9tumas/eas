local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local buttons = script.Parent.Buttons

local HOVER_INFO  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS_INFO  = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SPRING_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function applyButtonAnimation(btn: GuiButton)
	local uiScale = btn:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(uiScale, HOVER_INFO, { Scale = 1.06 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(uiScale, HOVER_INFO, { Scale = 1.0 }):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		TweenService:Create(uiScale, PRESS_INFO, { Scale = 0.93 }):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(uiScale, SPRING_INFO, { Scale = 1.06 }):Play()
	end)
end

for _, btn in ipairs(buttons:GetChildren()) do
	if btn:IsA("GuiButton") then
		applyButtonAnimation(btn)
	end
end

buttons.Store.MouseButton1Click:Connect(function()
	InterfaceTabUtil.openTab("Store")
end)

buttons.Index.MouseButton1Click:Connect(function()
	InterfaceTabUtil.openTab("Index")
end)

buttons.Rebirth.MouseButton1Click:Connect(function()
	InterfaceTabUtil.openTab("Rebirth")
end)