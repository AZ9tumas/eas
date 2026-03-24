local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ReplicatedStorage.Network)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)
local DataHandler = require(ServerStorage.DataHandler)

local NotifyError = Network.Notifications.Error
local NotifySuccess = Network.Notifications.Success

local DataGroupRewards = {}

function DataGroupRewards.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	if not profileData.HasBeenShownFavoritePrompt then
		-- disabled for now
		--Network.Prompts.FavoritePrompt:FireClient(player)
	end
	
	--warn(player.Name, "data loaded")
	--print(profileData, clientData)
end

function DataGroupRewards.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data unloading")
end

Network.Prompts.FavoritePrompt.OnServerEvent:Connect(function(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	profileData.HasBeenShownFavoritePrompt = true
end)

return DataGroupRewards