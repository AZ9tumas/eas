local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataStoreLoc = ServerScriptService:WaitForChild("PlayerData"):WaitForChild("PlayerDataStore")

local Codes = require(ServerStorage.Info.Codes)
local DataCash = require(ServerStorage.DataComponents.DataCash)

local DataHandler = require(ServerStorage.DataHandler)
local ProfileTemplate = require(PlayerDataStoreLoc.DefaultData)
local Network = require(ReplicatedStorage.Network)


local DataCodes = {}

function DataCodes.getRedeemedCodes(player: Player): typeof(ProfileTemplate.RedeemedCodes)?
    local profileData = DataHandler.getProfileData(player)
    if profileData == nil then
        return nil
	end
	
    return profileData.RedeemedCodes
end

function DataCodes.redeemCode(player: Player, code: string)
    local rewards = Codes[code]
    if rewards == nil then
        return
    end
    if rewards.Expired then
        return false
    end

    local profileData, clientData = DataHandler.getProfileData(player)
    assert(profileData, clientData)
    if table.find(profileData.RedeemedCodes, code) then
        return true, true
    end

    table.insert(profileData.RedeemedCodes, code)

	local Cash = rewards.Cash
	if Cash then
		if DataCash.giveCash(player, Cash, true) then
			return rewards.Message or true
		end
    end
end

-- Client
Network.Codes.RedeemCode.OnServerInvoke = function(player: Player, code: string?)
    if typeof(code) ~= "string" then
        return
	end
	
	return DataCodes.redeemCode(player, code)
	
	-- false = expired
	-- nil = not valid / not found
	-- true = already redeemed
end

return DataCodes