local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")

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

local displayTextMessage = require(ReplicatedStorage.Shared.Utility.Roblox.displayTextMessage)
local RichText = require(ReplicatedStorage["Helper Modules"].RichText)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local Music = {}

function Music.init()
	local MusicFolder = ReplicatedStorage:WaitForChild("Music")
	local SoundList = MusicFolder.Normal:GetChildren()

	local currentIndex = Random.new():NextInteger(1, #SoundList)
	local currentSound: Sound? = nil
	local isMuted = false
	local playNextConnection = nil

	local function playSound(index)
		if currentSound then
			currentSound:Stop()
		end

		if not SoundList[index] then
			index = 1
		end

		currentIndex = index
		currentSound = SoundList[currentIndex]
		currentSound.TimePosition = 0
		currentSound:Play()

		if playNextConnection then
			playNextConnection:Disconnect()
		end

		playNextConnection = currentSound.Ended:Connect(function()
			local nextIndex = currentIndex + 1
			if nextIndex > #SoundList then
				nextIndex = 1
			end
			if not isMuted then
				playSound(nextIndex)
			end
		end)
	end
	
	-- Start music initially
	task.delay(1, function()
		task.wait(1)

		if not isMuted and ClientSettings.Music then
			playSound(currentIndex)
		end

		ClientSettings.settingChanged("Music"):Connect(function()
			if ClientSettings.Music then
				isMuted = false

				if currentSound then
					currentSound:Play()
				else
					playSound(currentIndex)
				end

			else
				isMuted = true

				if currentSound then
					currentSound:Pause()
				end
			end
		end)
	end)
end

return Music