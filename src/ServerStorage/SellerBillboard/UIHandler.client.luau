local bb = script.Parent
local container = bb:WaitForChild("Container")
local originVal = bb:WaitForChild("OriginPart")
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local Network = require(game:GetService("ReplicatedStorage").Network)

local MAX_DISTANCE = 15

RunService.Heartbeat:Connect(function()
	if not originVal.Value then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local dist = (hrp.Position - originVal.Value.Position).Magnitude
	
	if dist > MAX_DISTANCE then
		bb:Destroy()
	end
end)

for _, btn in pairs(container:GetChildren()) do
	if btn:IsA("TextButton") then
		
		btn.MouseEnter:Connect(function()
			game:GetService("TweenService"):Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.1}):Play()
			game:GetService("TweenService"):Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(1.05, 0, 0.15, 0)}):Play()
		end)
		
		btn.MouseLeave:Connect(function()
			game:GetService("TweenService"):Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
			game:GetService("TweenService"):Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()
		end)
		
		btn.MouseButton1Click:Connect(function()
			if btn.Name == "Option_5" then
				bb:Destroy()
			else
				--print("Action: " .. btn.Name)
				
				local char = player.Character
				if not char then return end
				
				local tool = char:FindFirstChildWhichIsA("Tool")
				
				if btn.Name == "Option_1" then
					Network.Seller.SellLabubus:InvokeServer()
					bb:Destroy()
				elseif btn.Name == "Option_2" then
					Network.Seller.SellEggs:InvokeServer()
					bb:Destroy()
				elseif btn.Name == "Option_3" then
					if tool then
						Network.Seller.SellHandItem:InvokeServer(tool.Name)
						bb:Destroy()
					end
				elseif btn.Name == "Option_4" then
					if tool then
						Network.Seller.CheckValue:InvokeServer(tool.Name)
						bb:Destroy()
					end
				end
			end
		end)
	end
end
