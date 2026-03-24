local Valuee = Instance.new('CFrameValue')
Valuee.Value = script.Parent.CFrame

coroutine.wrap(function()
	while true do
		game.TweenService:Create(Valuee, TweenInfo.new(0.285, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Value = script.Parent.CFrame * CFrame.Angles(0, math.rad(30), 0)}):Play()
		task.wait(0.03)
	end
end)()
Valuee.Changed:Connect(function(New)
	print('hello')
	script.Parent.Parent:SetPrimaryPartCFrame(New)
end)