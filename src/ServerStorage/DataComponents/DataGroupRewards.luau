local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ReplicatedStorage.Network)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)
local DataHandler = require(ServerStorage.DataHandler)
local DataCash = require(ServerStorage.DataComponents.DataCash)
local DataPlots = require(ServerStorage.DataComponents.DataPlots)

local NotifyError = Network.Notifications.Error
local NotifySuccess = Network.Notifications.Success

local DataGroupRewards = {}

function DataGroupRewards.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data loaded")
	--print(profileData, clientData)
end

function DataGroupRewards.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data unloading")
end

function DataGroupRewards.claimGroupReward(player: Player, dontshowPrompt: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	if profileData.GroupRewardClaimTime > 0 then return end
	
	local GroupID = ReplicatedStorage.GroupID.Value
	if not player:IsInGroupAsync(GroupID) then
		if dontshowPrompt then return end
		
		NotifyError:FireClient(player, "You are not in the group. (can take up to a minute to update)")
		
		return false
	end
	
	profileData.GroupRewardClaimTime = os.time() -- update datastore
	clientData.GroupRewardClaimTime(profileData.GroupRewardClaimTime) -- sync updated data with client
	
	NotifySuccess:FireClient(player, "You’ve claimed your Group Reward!")
	
	-- Reward Player Here
	
	DataPlots.GiveLabubuByRarity(player, "Exclusive", 1, "GroupReward")
	
	return true
end

Network.GroupRewards.Claimed.OnServerInvoke = DataGroupRewards.claimGroupReward

return DataGroupRewards