local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")

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
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local GroupRewardRemote = Network.GroupRewards.Claimed

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local mainGui = playerGui.Tabs.GroupReward

local container = mainGui.Container
local GroupID = ReplicatedStorage.GroupID.Value

local GroupReward = {}

function GroupReward.init()
	-- Once initialized, this gets called
	
	local Claim: Frame = container.LeftFrame
	local ClaimButton: GuiButton = Claim.VerifyButton
	
	ClaimButton.Activated:Connect(function()
		if GroupRewardRemote:InvokeServer() == false then
			-- This should be done in a script running on the client
			local success, result = pcall(function()
				return GroupService:PromptJoinAsync(GroupID)
			end)
			
			if success then
				if result == Enum.GroupMembershipStatus.Joined then
					print("Player joined the group!")
					GroupRewardRemote:InvokeServer(true)
				elseif result == Enum.GroupMembershipStatus.JoinRequestPending then
					print("Join request sent")
				elseif result == Enum.GroupMembershipStatus.AlreadyMember then
					print("Already a member")
				else
					print("Did not join or not eligible")
				end
			else
				warn("Prompt failed: ", result)
			end
		end
	end)
	
	local function checkEligibility(new: number)
		--warn("VALUE CHANGED:", new)
		
		if new then
			if new > 0 then
				-- Claimed
				
				-- Make Claim button un-interactable
				Claim.Visible = false
				InterfaceTabUtil.closeAllTabs()
			end
		end
	end
	
	-- Listen to Value Changes
	trove:Add(
		Charm.subscribe(ClientData.GroupRewardClaimTime, checkEligibility)
	)
	
	checkEligibility(ClientData.GroupRewardClaimTime())
end

return GroupReward