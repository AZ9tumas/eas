local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)

local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local formatLargeNumber = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumber)
local formatLargeNumberThousands = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumberThousands)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local mainGui = playerGui.HUD.Buttons.RightIcons.Starter

local StarterPack = {}

function StarterPack.init()
	local function UpdateStarterPackUI()
		local starterPackData = ClientData.Gamepasses()
		if not starterPackData then return end
		
		mainGui.Visible = starterPackData["Starter Pack"] ~= true
	end
	
	Charm.subscribe(ClientData.Gamepasses, UpdateStarterPackUI)
	UpdateStarterPackUI()
end

return StarterPack