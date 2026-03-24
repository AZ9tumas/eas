local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ReplicatedStorage.Network)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)
local DataHandler = require(ServerStorage.DataHandler)

local NotifyError = Network.Notifications.Error
local NotifySuccess = Network.Notifications.Success

local DataCharacters = {}

local CharactersFolder = workspace.Characters

function DataCharacters.characterAdded(player: Player, character: Model)
	character.Parent = CharactersFolder
end

function DataCharacters.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data loaded")
	--print(profileData, clientData)
end

function DataCharacters.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data unloading")
end

return DataCharacters