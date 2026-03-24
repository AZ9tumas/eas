local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local TimeFormat = require(ReplicatedStorage.Shared.Utility.Format.TimeFormat)
local getUTCtime = require(ReplicatedStorage.Shared.Utility.Time.getUTCtime)

local Notification = require(ReplicatedStorage.Client.Interface.UI.Overlays.Notification)
local stringRemoveTrailingSpaces = require(ReplicatedStorage.Shared.Utility.String.stringRemoveTrailingSpaces)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mainGui = playerGui.HUD.Buttons.RightIcons.Reward.TextButton.TextLabel

local trove = Trove.new()

local DailyRewards = {}
local nextRewardTime = nil

local function UpdateTimerText()
	if not nextRewardTime then return end	

	local timeLeft = nextRewardTime - getUTCtime()
	if timeLeft > 0 then
		mainGui.Text = TimeFormat.convertToHMS(timeLeft)
	else
		mainGui.Text = "Claim!"
	end
end

function DailyRewards.init()
	local function UpdateTimer()
		local LastDailyRewardTime = ClientData.LastDailyRewardTime()
		if not LastDailyRewardTime then
			return
		end
		
		nextRewardTime = LastDailyRewardTime + 24 * 60 * 60
		
		UpdateTimerText()
	end
	
	Charm.subscribe(ClientData.LastDailyRewardTime, UpdateTimer)
	UpdateTimer()
	
	mainGui.Parent.Activated:Connect(function()
		Network.DailyRewards.Claim:FireServer()
	end)
end

task.spawn(function()
	while task.wait(1) do
		UpdateTimerText()
	end
end)

return DailyRewards