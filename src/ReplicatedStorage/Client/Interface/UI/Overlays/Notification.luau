local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Network = require(ReplicatedStorage.Network)

local Types = require(ReplicatedStorage.Shared.Types)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local NotificationText = ReplicatedStorage.Assets.Interface.Notification
local mainGui = playerGui.Notifications.Notifications

local Sounds = ReplicatedStorage.Assets.Sounds
local InterfaceSounds = ReplicatedStorage.Assets.Sounds.Interface

local Notification = {}

function Notification.init()
	-- can be used later if needed
end

function Notification.Notify(message: string, color: Types.ColorKey?, sound: Types.SoundKey?, duration: number?)
	duration = duration or 5
	
	if duration <= 2 then
		duration = 2
	end
	
	local notification = NotificationText:Clone()
	notification.TextTransparency = 1
	notification.Text = message
	--notification.TextColor3 = color or Types.Colors.Default
	
	notification.Shadow.ImageColor3 = color or Types.Colors.Default
	
	notification.Parent = mainGui
	
	if sound then
		local Sound: Sound? = Sounds:FindFirstChild(sound) or InterfaceSounds:FindFirstChild(sound)
		
		if not Sound then
			Sound = Sounds:WaitForChild(sound)
		end
		
		if Sound then
			Sound:Play()
		end
	end

	-- Fade in text
	TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0
	}):Play()
	
	-- Fade in text (Stroke)
	TweenService:Create(notification.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 0
	}):Play()

	-- Shadow Fade in
	TweenService:Create(notification.Shadow, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ImageTransparency = 0.55
	}):Play()

	-- Grow shadow
	TweenService:Create(notification.Shadow, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1.55, 0, 1.55, 0)
	}):Play()

	-- Wait n seconds, then fade out and destroy
	task.delay(duration - 0.6, function()
		local fadeOut = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1
		})
		local shadowFadeOut = TweenService:Create(notification.Shadow, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			ImageTransparency = 1
		})
		-- Fade out text (Stroke)
		TweenService:Create(notification.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1
		}):Play()

		fadeOut:Play()
		shadowFadeOut:Play()

		task.wait(0.6)
		notification:Destroy()
	end)
end

--task.spawn(function()
--	task.wait(5)
	
--	while task.wait(2) do
--		--Notification.Notify("You don't have enough money or cat or dog or wolf!", Types.Colors.Error, Types.Sounds.Default)
--		Notification.Error("You don't have enough money or cat or dog or wolf!", Types.Colors.Error, Types.Sounds.Default)
--	end
--end)

function Notification.Normal(text: string, duration: number?)
	return Notification.Notify(text, Types.Colors.Default, Types.Sounds.Default, duration)
end

function Notification.Info(text: string, duration: number?)
	return Notification.Notify(text, Types.Colors.Info, Types.Sounds.Info, duration)
end

function Notification.Warning(text: string, duration: number?)
	return Notification.Notify(text, Types.Colors.Warning, Types.Sounds.Warning, duration)
end

function Notification.Error(text: string, duration: number?)
	return Notification.Notify(text, Types.Colors.Error, Types.Sounds.Error, duration)
end

function Notification.Success(text: string, duration: number?)
	return Notification.Notify(text, Types.Colors.Success, Types.Sounds.Success, duration)
end

function Notification.ProductBought(name: string, duration: number?)
	return Notification.Notify(`You bought {name}`, Types.Colors.Success, Types.Sounds.Purchase, duration)
end

function Notification.ItemBought(name: string, duration: number?)
	return Notification.Notify(`You bought {name}`, Types.Colors.Success, Types.Sounds.Purchase, duration)
end

Network.Notifications.Notify.OnClientEvent:Connect(function(text: string, color: Types.ColorKey?, sound: Types.SoundKey?, duration: number?)
	return Notification.Notify(text, color, sound, duration)
end)

Network.Notifications.Normal.OnClientEvent:Connect(function(text: string, duration: number?)
	return Notification.Normal(text, duration)
end)

Network.Notifications.Info.OnClientEvent:Connect(function(text: string, duration: number?)
	return Notification.Info(text, duration)
end)

Network.Notifications.Error.OnClientEvent:Connect(function(text: string, duration: number?)
	return Notification.Error(text, duration)
end)

Network.Notifications.Warning.OnClientEvent:Connect(function(text: string, duration: number?)
	return Notification.Warning(text, duration)
end)

Network.Notifications.Success.OnClientEvent:Connect(function(text: string, duration: number?)
	return Notification.Success(text, duration)
end)

Network.Notifications.ProductBought.OnClientEvent:Connect(function(name: string, duration: number?)
	return Notification.ProductBought(name, duration)
end)

Network.Notifications.ItemBought.OnClientEvent:Connect(function(name: string, duration: number?)
	return Notification.ItemBought(name, duration)
end)

-- Sounds (ONLY)
Network.PlaySounds.Success.OnClientEvent:Connect(function()
	local sound = "Success"
	
	if sound then
		local Sound: Sound? = Sounds:FindFirstChild(sound) or InterfaceSounds:FindFirstChild(sound)
		if Sound then
			Sound:Play()
		end
	end
end)

Network.PlaySounds.Error.OnClientEvent:Connect(function()
	local sound = "Error"

	if sound then
		local Sound: Sound? = Sounds:FindFirstChild(sound) or InterfaceSounds:FindFirstChild(sound)
		if Sound then
			Sound:Play()
		end
	end
end)

Network.PlaySounds.Purchase.OnClientEvent:Connect(function()
	local sound = "Purchase"

	if sound then
		local Sound: Sound? = Sounds:FindFirstChild(sound) or InterfaceSounds:FindFirstChild(sound)
		if Sound then
			Sound:Play()
		end
	end
end)

Network.PlaySounds.Warning.OnClientEvent:Connect(function()
	local sound = "Warning"

	if sound then
		local Sound: Sound? = Sounds:FindFirstChild(sound) or InterfaceSounds:FindFirstChild(sound)
		if Sound then
			Sound:Play()
		end
	end
end)

Network.PlaySounds.CustomSound.OnClientEvent:Connect(function(sound: string?)
	if sound then
		local Sound: Sound? = Sounds:FindFirstChild(sound) or InterfaceSounds:FindFirstChild(sound)
		if Sound then
			Sound:Play()
		end
	end
end)

Network.PlaySounds.StopSound.OnClientEvent:Connect(function(sound: string?)
	if sound then
		local Sound: Sound? = Sounds:FindFirstChild(sound) or InterfaceSounds:FindFirstChild(sound)
		if Sound then
			if Sound.IsPlaying then
				Sound:Stop()
			end
		end
	end
end)

return Notification
