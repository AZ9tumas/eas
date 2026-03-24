local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)

local interfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local ShopMerchant = {}

function ShopMerchant.tagAdded(model: BasePart)
	local MerchantProximityPrompt: ProximityPrompt = model:FindFirstChild("MerchantProximityPrompt")
	if not MerchantProximityPrompt then return end
	
	MerchantProximityPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
		if LocalPlayer ~= playerWhoTriggered then return end
		
		interfaceTabUtil.openTab("Shop", true)
	end)
end

function ShopMerchant.tagRemoved(model: BasePart)
    
end

return ShopMerchant