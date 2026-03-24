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

local SellMerchant = {}

function SellMerchant.tagAdded(model: BasePart)
	local MerchantProximityPrompt: ProximityPrompt = model:FindFirstChild("MerchantProximityPrompt")
	if not MerchantProximityPrompt then return end
	
	MerchantProximityPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
		if LocalPlayer ~= playerWhoTriggered then return end
		
		--interfaceTabUtil.openTab("Seller", true)
	end)
end

function SellMerchant.tagRemoved(model: BasePart)
    
end

return SellMerchant