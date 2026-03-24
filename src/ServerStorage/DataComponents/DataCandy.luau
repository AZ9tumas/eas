local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(ServerStorage.DataHandler)
local Network = require(ReplicatedStorage.Network)
--local Leaderstats = require(ServerStorage.Leaderstats)


local DataCandy = {}

function DataCandy.init()
    
end

function DataCandy.playerAdded(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then
	   return
	end
end

function DataCandy.getCandyMultiplier(player)
	local totalMultiplier = 1
	
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return totalMultiplier
	end

	-- Friends multiplier (10% per friend)
	local friends = player:GetAttribute("FriendsInServer") or 0
	totalMultiplier += friends * 0.1

	return totalMultiplier
end

function DataCandy.reduceCandy(player: Player, amount: number)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end
	
	profileData.Candy -= math.floor(amount)
	clientData.Candy(profileData.Candy)
	
	return true
end

function DataCandy.giveCandy(player: Player, amount: number, not_affected_by_multiplier: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end

	local multiplier = 1
	if not not_affected_by_multiplier then
		multiplier = DataCandy.getCandyMultiplier(player)
	end

	profileData.Candy += math.floor(amount * multiplier)
	clientData.Candy(profileData.Candy)
	
	Network.PlaySounds.Success:FireClient(player)
	
	return true
end

function DataCandy.setCandy(player: Player, amount: number)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then
		return
	end

	profileData.Candy = math.floor(amount)
	clientData.Candy(profileData.Candy)
	
	return true
end

function DataCandy.getCandy(player: Player) : number?
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then
		return
	end
	
	return profileData.Candy
end

return DataCandy