local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Notification = require(ReplicatedStorage.Client.Utility.Notification)

local ClientSettings = require(ReplicatedStorage.Client.ClientSettings)


local interfaceTabUtils = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local mainGui = playerGui.Tabs.Settings
local container = mainGui.Container
local list = container.Container

local Settings = {}
local CachedOriginalSFXVolumes = {}

function Settings.init()
	local function UpdateSoundEffect()
		if ClientSettings.SFX then
			if not next(CachedOriginalSFXVolumes) then return end
			
			-- Get all instances tagged with "SFX"
			local sfxInstances = CollectionService:GetTagged("SFX")

			for _, instance in ipairs(sfxInstances) do
				if not CachedOriginalSFXVolumes[instance] then continue end
				
				instance.Volume = CachedOriginalSFXVolumes[instance]
				CachedOriginalSFXVolumes[instance] = nil
			end
			
			CachedOriginalSFXVolumes = {}
		else
			if next(CachedOriginalSFXVolumes) then return end
			
			-- Get all instances tagged with "SFX"
			local sfxInstances = CollectionService:GetTagged("SFX")

			for _, instance in ipairs(sfxInstances) do
				CachedOriginalSFXVolumes[instance] = instance.Volume
				instance.Volume = 0
			end
		end
	end
	
	ClientSettings.settingChanged("SFX"):Connect(UpdateSoundEffect)
	UpdateSoundEffect()
end

return Settings