local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(ServerStorage.DataHandler)
local Network = require(ReplicatedStorage.Network)
local Types = require(ReplicatedStorage.Shared.Types)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)
--local Leaderstats = require(ServerStorage.Leaderstats)


local DataIndex = {}

function DataIndex.init()
    
end

function DataIndex.AddBrainrotToIndex(player: Player, brainrotTemplate: Types.Brainrot): (boolean, boolean)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then 
		return false, false
	end
	
	local brainrotName = brainrotTemplate.Name
	local mutationTier = brainrotTemplate.MutationTier
	
	profileData.Index[mutationTier] = profileData.Index[mutationTier] or {}
	
	if profileData.Index[mutationTier][brainrotName] then
		return false, true
	end

	profileData.Index[mutationTier][brainrotName] = true
	if clientData then
		clientData.Index(deepCopy(profileData.Index))
	end
	return true, false
end

return DataIndex