local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Notification = require(ReplicatedStorage.Client.Utility.Notification)

local displayTextMessage = require(ReplicatedStorage.Shared.Utility.Roblox.displayTextMessage)
local RichText = require(ReplicatedStorage["Helper Modules"].RichText)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local ChatMessages = {}

function ChatMessages.init()
	-- Once initialized, this gets called

	task.spawn(function()
		task.wait(3 * 60)
		
		if ClientData.GroupRewardClaimTime() <= 0 then
			displayTextMessage(RichText.ColorWrap(
				"[TIP] 👍 and ⭐ the game to support us!"
				, Color3.fromRGB(0, 195, 255)
				)
			)
			
			task.wait(1.5 * 60)
			
			displayTextMessage(RichText.ColorWrap(
				"[TIP] Your Labubus keep earning cash even when you’re offline!"
				, Color3.fromRGB(255, 167, 14)
				)
			)
			
			task.wait(1.5 * 60)
		else
			displayTextMessage(RichText.ColorWrap(
				"[TIP] Your Labubus keep earning cash even when you’re offline!"
				, Color3.fromRGB(255, 167, 14)
				)
			)
			
			task.wait(1.5 * 60)
		end
			
		if ClientData.GroupRewardClaimTime() <= 0 then
			displayTextMessage(RichText.ColorWrap(
				"[TIP] 👍 and ⭐ the game if you enjoy it!"
				, Color3.fromRGB(56, 244, 9)
				)
			)
			
			task.wait(3 * 60)
		end
		
		--local policyInfo = PolicyService:GetPolicyInfoForPlayerAsync(localPlayer)
		--if table.find(policyInfo.AllowedExternalLinkReferences, "Discord") then
		--	displayTextMessage(RichText.ColorWrap(
		--		"[TIP] Found a bug? Report it to us on our discord server!"
		--		, Color3.fromRGB(212, 8, 244)
		--		)
		--	)
		--end
	end)
end

Network.Chat.DisplayChatMessage.OnClientEvent:Connect(function(str: string)
	displayTextMessage(str)
end)

return ChatMessages