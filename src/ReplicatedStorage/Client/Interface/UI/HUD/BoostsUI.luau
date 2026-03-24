local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
local player = localPlayer
local playerGui = localPlayer.PlayerGui

local BoostsImages = require(ReplicatedStorage.Data.BoostsImages)

local trove = Trove.new()

local mainGui = playerGui.HUD.Boosts.Boosts

local FriendBoost = {}

function FriendBoost.init()
	-- =========
	-- Helpers
	-- =========

	local function getNow()
		return os.time() -- or getUTCtime() if you use that on client too
	end

	-- =========
	-- State
	-- =========

	local ActiveStates = {
		ServerLuck = false,
		SuperSpeed = false,
		x2Cash = false,
		x2Luck = false,
		MagicShield = false,
		LuckyClover = false
	}

	-- =========
	-- Callbacks
	-- =========

	local function onStateChanged(name: string, isActive: boolean, remaining: number?)
		--print("[Trait]", name, "Active:", isActive, "Remaining:", remaining)

		for _, child in ipairs(mainGui:GetChildren()) do
			if child:IsA("ImageLabel") and not ActiveStates[child.Name] then
				child:Destroy()
			end
		end

		for name, boolean in pairs(ActiveStates) do
			local alreadyExists = mainGui:FindFirstChild(name)
			if alreadyExists then 
				alreadyExists.Visible = boolean
				continue
			end

			local Icon = BoostsImages.GetImage(name)
			if not Icon then continue end

			local ImageLabel = Instance.new("ImageLabel")
			ImageLabel.Image = Icon
			ImageLabel.ScaleType = Enum.ScaleType.Fit
			ImageLabel.Name = name
			ImageLabel.LayoutOrder = BoostsImages.Get(name).Priority
			ImageLabel.Visible = boolean
			ImageLabel.Parent = mainGui
		end
	end
	
	-- Lucky Clover
	
	local function UpdateLuckyClover()
		local Gamepasses = ClientData.Gamepasses()
		if not Gamepasses then return end

		local hasLuckyClover = Gamepasses["Lucky Clover"]
		ActiveStates.LuckyClover = hasLuckyClover
		onStateChanged("LuckyClover", hasLuckyClover, nil)
	end

	Charm.subscribe(ClientData.Gamepasses, UpdateLuckyClover)
	UpdateLuckyClover()

	-- =========
	-- Server Luck (Workspace attributes)
	-- =========

	local function updateServerLuck()
		local multi = workspace:GetAttribute("ServerLuckMulti") or 1
		local expiresAt = workspace:GetAttribute("ServerLuckExpiresAt") or 0
		local now = getNow()

		local active = multi > 1 and expiresAt > now
		local remaining = active and (expiresAt - now) or 0

		if ActiveStates.ServerLuck ~= active then
			ActiveStates.ServerLuck = active
			onStateChanged("ServerLuck", active, remaining)
		end
	end

	workspace:GetAttributeChangedSignal("ServerLuckMulti"):Connect(updateServerLuck)
	workspace:GetAttributeChangedSignal("ServerLuckExpiresAt"):Connect(updateServerLuck)

	-- =========
	-- Timed Player Attributes (timestamp-based)
	-- =========

	local function trackTimedAttribute(attrName: string, stateKey: string)
		local function update()
			local expiresAt = player:GetAttribute(attrName)
			local now = getNow()

			local active = typeof(expiresAt) == "number" and expiresAt > now
			local remaining = active and (expiresAt - now) or 0

			if ActiveStates[stateKey] ~= active then
				ActiveStates[stateKey] = active
				onStateChanged(stateKey, active, remaining)
			end
		end

		player:GetAttributeChangedSignal(attrName):Connect(update)

		-- Initial check
		update()

		-- Also tick every second to update remaining time
		task.spawn(function()
			while true do
				update()
				task.wait(1)
			end
		end)
	end

	trackTimedAttribute("SuperSpeed", "SuperSpeed")
	trackTimedAttribute("x2Cash", "x2Cash")
	trackTimedAttribute("x2Luck", "x2Luck")

	-- =========
	-- Boolean Attribute (Magic Shield)
	-- =========

	local function updateMagicShield()
		local active = player:GetAttribute("MagicShield") ~= nil

		if ActiveStates.MagicShield ~= active then
			ActiveStates.MagicShield = active
			onStateChanged("MagicShield", active, nil)
		end
	end

	player:GetAttributeChangedSignal("MagicShield"):Connect(updateMagicShield)
	updateMagicShield()

	-- =========
	-- Initial Server Luck check
	-- =========

	updateServerLuck()
end

return FriendBoost