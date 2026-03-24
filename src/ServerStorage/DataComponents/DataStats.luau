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

local Tasks = {}

function DataGroupRewards.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	local CURRENT_TIME = os.time()
	
	profileData.JoinedSessionAt = CURRENT_TIME
	
	if profileData.FirstTimePlayed == 0 then
		profileData.FirstTimePlayed = CURRENT_TIME
		clientData.FirstTimePlayed(profileData.FirstTimePlayed)
	end
	
	if player.Parent then
		Tasks[player] = task.spawn(function()
			while task.wait(1) do
				profileData.Playtime += 1
				-- dont update client here, we dont wanna spam it. guess it by yourself lol
			end
		end)
	end
end

function DataGroupRewards.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	local CURRENT_TIME = os.time()
	
	profileData.LeftSessionAt = CURRENT_TIME
	
	task.cancel(Tasks[player])
	Tasks[player] = nil
end

return DataGroupRewards