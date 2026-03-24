local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Network)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)
local DataHandler = require(ServerStorage.DataHandler)
local DataPlots = require(ServerStorage.DataComponents.DataPlots)
local DataCash = require(ServerStorage.DataComponents.DataCash)
local DataCandy = require(ServerStorage.DataComponents.DataCandy)

local Rng_Module = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Rng"))
local Wheel_Rarity = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Wheel"))

local GiveSpin = ServerStorage:WaitForChild("BindableEvents"):WaitForChild("GiveSpin")

local NotifyError = Network.Notifications.Error
local NotifySuccess = Network.Notifications.Success

local SpinWheel = Network.Spin.SpinWheel

local DataSpin = {}

local NextFreeSpinTimeAfter = 30 * 60 -- 30 minutes

function DataSpin.ReduceSpin(player: Player, decreaseby: number?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	profileData.Spins -= decreaseby or 1
	clientData.Spins(profileData.Spins)
end

function DataSpin.RewardSpin(player: Player, reward: number?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	profileData.Spins += reward or 1
	clientData.Spins(profileData.Spins)
end

function DataSpin.UpdateNextSpin(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	profileData.NextSpinAt = os.time() + NextFreeSpinTimeAfter
	clientData.NextSpinAt(profileData.NextSpinAt)
end

function DataSpin.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	if profileData.NextSpinAt == 0 then
		DataSpin.UpdateNextSpin(player)
	end
	
	--warn(player.Name, "data loaded")
	--print(profileData, clientData)
end

function DataSpin.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data unloading")
end

SpinWheel.OnServerInvoke = function(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	if profileData.Spins <= 0 then return end

	DataSpin.ReduceSpin(player)

	local Reward = Wheel_Rarity[Rng_Module(Wheel_Rarity, DataPlots.GetExtraLuckMulti(player))]
	local RewardName: string = Reward.Name
	local RewardFunc = Reward.Reward

	RewardFunc(player)
	
	--Name = "30,000 Cash", 
	--Name = "+1,000 Candies", 
	--Name = "Arcane Block", 
	--Name = "King Block", 
	--Name = "SIX SIX SIX", 
	
	if RewardName == "30,000 Cash" then
		DataCash.giveCash(player, 30000)
	elseif RewardName == "+1,000 Candies" then
		DataCandy.giveCandy(player, 1000)
	elseif RewardName == "Arcane Block" then
		DataPlots.GiveEgg(player, "Arcane Block", "Spinner")
	elseif RewardName == "King Block" then
		DataPlots.GiveEgg(player, "King Block", "Spinner")
	elseif RewardName == "SIX SIX SIX" then
		DataPlots.GiveLabubu(player, "SIX SIX SIX", 1, "GroupReward")
	end

	return RewardName
end

GiveSpin.Event:Connect(function(player: Player, amount: number?)
	DataSpin.RewardSpin(player, amount or 1)
end)

-- Free Spin
task.spawn(function()
	while task.wait(1) do
		for i, player in pairs(Players:GetPlayers()) do
			if not player:GetAttribute("ClientSignaledLoaded") then continue end
			
			local profileData, clientData = DataHandler.getProfileData(player)
			if profileData == nil or clientData == nil then continue end
			
			if profileData.NextSpinAt then
				if os.time() >= profileData.NextSpinAt then
					DataSpin.UpdateNextSpin(player)
					DataSpin.RewardSpin(player)

					NotifySuccess:FireClient(player, "You received a Free Spin!", 8)
				end
			end
		end
	end
end)

return DataSpin