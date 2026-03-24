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
local SyncedState = require(ReplicatedStorage.Shared.SyncedState)

local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)

local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local formatLargeNumber = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumber)
local formatLargeNumberThousands = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumberThousands)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local mainGui = playerGui.HUD.Top.Traits

local Traits = {}

function Traits.init()
	local function UpdateTraitsUI()
		local WeatherEvents = SyncedState.WeatherEvents()
		if not WeatherEvents then return end
		
		for _, child in pairs(mainGui:GetChildren()) do
			if child:IsA("ImageLabel") then
				if not WeatherEvents[child.Name] then
					child:Destroy()
				end
			end
		end
		
		for name, boolean in pairs(WeatherEvents) do
			if mainGui:FindFirstChild(name) then continue end

			local Icon = PlotUtil.getTraitData(name).Icon

			local ImageLabel = Instance.new("ImageLabel")
			ImageLabel.Image = Icon
			ImageLabel.ScaleType = Enum.ScaleType.Fit
			ImageLabel.Name = name
			ImageLabel.Parent = mainGui
		end
	end
	
	Charm.subscribe(SyncedState.WeatherEvents, UpdateTraitsUI)
	UpdateTraitsUI()
end

return Traits