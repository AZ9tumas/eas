local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(ServerStorage.DataHandler)
local Network = require(ReplicatedStorage.Network)
--local Leaderstats = require(ServerStorage.Leaderstats)


local DataCash = {}

function DataCash.init()
    
end

function DataCash.playerAdded(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then
	   return
	end
	
	--DataCash.setCash(player, 1000000000)
end

function DataCash.getCashMultiplier(player)
	local totalMultiplier = 1
	
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return totalMultiplier
	end

	-- Friends multiplier (10% per friend)
	local friends = player:GetAttribute("FriendsInServer") or 0
	totalMultiplier += friends * 0.1
	
	totalMultiplier += profileData.Gamepasses["VIP Status"] and 0.5 or 0
	totalMultiplier += player:GetAttribute("x2Cash") and 2 or 0

	-- Future examples:
	-- if player:GetAttribute("VIP") then
	--     totalMultiplier += 0.25
	-- end
	--
	-- if player:GetAttribute("DoubleCashBoost") then
	--     totalMultiplier += 1
	-- end

	return totalMultiplier
end

function DataCash.reduceCash(player: Player, amount: number)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end
	
	profileData.Cash -= math.floor(amount)
	clientData.Cash(profileData.Cash)
	
	return true
end

function DataCash.giveCash(player: Player, amount: number, not_affected_by_multiplier: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end

	local multiplier = 1
	if not not_affected_by_multiplier then
		multiplier = DataCash.getCashMultiplier(player)
	end

	profileData.Cash += math.floor(amount * multiplier)
	clientData.Cash(profileData.Cash)
	
	Network.PlaySounds.Success:FireClient(player)
	
	return true
end

function DataCash.setCash(player: Player, amount: number)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then
		return
	end

	profileData.Cash = math.floor(amount)
	clientData.Cash(profileData.Cash)
	
	return true
end

function DataCash.getCash(player: Player) : number?
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then
		return
	end
	
	return profileData.Cash
end

return DataCash