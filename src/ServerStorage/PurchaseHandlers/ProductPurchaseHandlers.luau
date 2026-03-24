local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ReplicatedStorage.Network)
local DataHandler = require(ServerStorage.DataHandler)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local numberFromString = require(ReplicatedStorage.Shared.Utility.Convert.numberFromString)
local PlayerAttributes = require(ServerStorage.Modules.PlayerAttributes)
local DataGamepasses = require(ServerStorage.DataComponents.DataGamepasses)
local DataItems = require(ServerStorage.DataComponents.DataItems)
local DataSpin = require(ServerStorage.DataComponents.DataSpin)
local DataPlots = require(ServerStorage.DataComponents.DataPlots)
local DataBackpack = require(ServerStorage.DataComponents.DataBackpack)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)
local getUTCtime = require(ReplicatedStorage.Shared.Utility.Time.getUTCtime)

local TriggerWeatherEvent = ServerStorage.BindableEvents.TriggerWeatherEvent

local GlobalSettings = require(ReplicatedStorage.GlobalSettings)

local NotifyNormal = Network.Notifications.Notify
local NotifyError = Network.Notifications.Error
local NotifyPurchase = Network.Notifications.ProductBought
local NotifySuccess = Network.Notifications.Success
local NotifyInfo = Network.Notifications.Info
local RichText = require(ReplicatedStorage["Helper Modules"].RichText)

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Types = require(ReplicatedStorage.Shared.Types)

--local DonationsList = workspace.Leaderboards.RobuxSpent.Donations.UI.List

local ProductPurchaseHandlers = {} :: { 
	[string]: ( (player: Player) -> () )?,
}

-- Plot -> Weather -> Golden Rain

ProductPurchaseHandlers["Golden Rain"] = function(player: Player)
	TriggerWeatherEvent:Fire("Golden Rain")
end

-- Plot -> Mutate Labubu -> Mutate Fail

ProductPurchaseHandlers["Keep Lost Mutation"] = function(player: Player)
	DataPlots.KeepLostMutation(player)
end

-- Plot -> Stealing -> Labubu

ProductPurchaseHandlers["Steal Labubu"] = function(player: Player)
	DataPlots.HandleStealing(player, false)
end

ProductPurchaseHandlers["Steal High-Tier Labubu"] = function(player: Player)
	DataPlots.HandleStealing(player, true)
end

-- Plot -> Eggs -> Exclusive Egg

ProductPurchaseHandlers["Exclusive Egg"] = function(player: Player)
	DataPlots.GiveExclusiveEgg(player)
end

-- Plot -> Eggs -> Instant Legendary Egg

ProductPurchaseHandlers["Instant Legendary Egg"] = function(player: Player)
	local EggTool, eggPillar, egg = nil, nil, nil
	local eggPillarIndex: number = 1 -- for legendary
	
	local plot: Model = DataPlots.GetPlayerPlot(player)
	if plot then
		local dropper: Folder = PlotUtil.getPlotDropper(plot)
		if dropper then
			local EggRolls: Folder = PlotUtil.getDropperEggsFolder(dropper)
			if EggRolls then
				local Egg: Model? = PlotUtil.getEggFromIndex(EggRolls, eggPillarIndex)
				if Egg then
					egg = Egg
					
					local eggPillars: { Model } = PlotUtil.getEggPillars(dropper)
					if eggPillars then
						eggPillar = PlotUtil.getEggPillarFromIndex(eggPillars, eggPillarIndex)
						local EggToolClone: Tool? = DataPlots.ConvertEggModelToRoll(egg)
						if eggPillar then
							DataPlots.RemoveEggFromPillar(player, eggPillar)
						end
						DataBackpack.Eggs.addBackpackEggByInstance(player, EggToolClone, true)
						
						DataPlots.EggRoll(player, nil, eggPillars, EggRolls, 1)
					end
				end
			end
		end
	end
end

-- Plot -> Eggs -> Instant Mythic Egg

ProductPurchaseHandlers["Instant Mythic Egg"] = function(player: Player)
	local EggTool, eggPillar, egg = nil, nil, nil
	local eggPillarIndex: number = 5 -- for mythic

	local plot: Model = DataPlots.GetPlayerPlot(player)
	if plot then
		local dropper: Folder = PlotUtil.getPlotDropper(plot)
		if dropper then
			local EggRolls: Folder = PlotUtil.getDropperEggsFolder(dropper)
			if EggRolls then
				local Egg: Model? = PlotUtil.getEggFromIndex(EggRolls, eggPillarIndex)
				if Egg then
					egg = Egg

					local eggPillars: { Model } = PlotUtil.getEggPillars(dropper)
					if eggPillars then
						eggPillar = PlotUtil.getEggPillarFromIndex(eggPillars, eggPillarIndex)
						local EggToolClone: Tool? = DataPlots.ConvertEggModelToRoll(egg)
						if eggPillar then
							DataPlots.RemoveEggFromPillar(player, eggPillar)
						end
						DataBackpack.Eggs.addBackpackEggByInstance(player, EggToolClone, true)
						
						DataPlots.EggRoll(player, nil, eggPillars, EggRolls, 5)
					end
				end
			end
		end
	end
end

-- Plot -> Repair Button

ProductPurchaseHandlers["Repair Button"] = function(player: Player)
	DataPlots.EnableSpin(player)
end
	

-- Plot -> Floor -> VIP Slot

ProductPurchaseHandlers["BuyVIPSlot"] = function(player: Player)
	local TargetVIPSlot = PlayerAttributes.getAttribute(player, "TargetVIPSlot")
	local TargetVIPSlotFloor = PlayerAttributes.getAttribute(player, "TargetVIPSlotFloor")
	
	if TargetVIPSlot == nil or TargetVIPSlotFloor == nil then return end
	
	local Plot: Model? = DataPlots.GetPlayerPlot(player)
	if not Plot then return end
	
	local Floor: Model? = PlotUtil.getFloor(Plot, TargetVIPSlotFloor)
	if not Floor then return end
	
	local Slots = Floor:FindFirstChild("Slots")
	if not Slots then return end
	
	local Slot = Slots:FindFirstChild(TargetVIPSlot)
	if not Slot then return end
	
	local GetSlotInfo = PlotUtil.getSlotData(Slot)
	if not GetSlotInfo then return end
	
	if not GetSlotInfo.IsVipSlot then return end
	if not GetSlotInfo.IsForSale then return end
	if GetSlotInfo.IsOccupied then return end
	
	DataPlots.SetSlotState(Slot, false, false)
	DataPlots.AddSlotToPlayerData(player, TargetVIPSlotFloor, TargetVIPSlot)
end

-- Plot -> Eggs -> Skip Egg Hatch

local function SkipEggHatch(player: Player)
	local TargetSlotNum = PlayerAttributes.getAttribute(player, "SkipHatchSlotNum")
	local TargetSlotFloor = PlayerAttributes.getAttribute(player, "SkipHatchFloorNum")

	if TargetSlotNum == nil or TargetSlotFloor == nil then return end

	local Plot: Model? = DataPlots.GetPlayerPlot(player)
	if not Plot then return end

	local Floor: Model? = PlotUtil.getFloor(Plot, TargetSlotFloor)
	if not Floor then return end

	local Slots = Floor:FindFirstChild("Slots")
	if not Slots then return end

	local Slot = Slots:FindFirstChild(TargetSlotNum)
	if not Slot then return end

	local GetSlotInfo = PlotUtil.getSlotData(Slot)
	if not GetSlotInfo then return end
	
	if GetSlotInfo.IsForSale then return end
	if not GetSlotInfo.IsOccupied then return end
	--if GetSlotInfo.IsHatchable then return end
	--if not GetSlotInfo.IsHatching then return end
	
	local Placements: Folder = PlotUtil.getSlotsPlacements(Slots)
	if not Placements then return end
	
	local Placement = PlotUtil.getPlacementFromIndex(
		Placements, TargetSlotNum
	)
	if not Placement then return end

	if Placement:GetAttribute("Type") ~= "Egg" then return end

	local EggData = PlotUtil.EggsData[Placement.Name]
	if not EggData then return end
	
	DataPlots.HatchEgg(Placement, Slot, player)
end

ProductPurchaseHandlers["Skip Common Hatch"] = SkipEggHatch
ProductPurchaseHandlers["Skip Rare Hatch"] = SkipEggHatch
ProductPurchaseHandlers["Skip Epic Hatch"] = SkipEggHatch
ProductPurchaseHandlers["Skip Legendary Hatch"] = SkipEggHatch
ProductPurchaseHandlers["Skip Mythic Hatch"] = SkipEggHatch
ProductPurchaseHandlers["Skip Exclusive Hatch"] = SkipEggHatch

-- Plot -> Eggs -> Skip Labubu Mutation

local function SkipLabubuMutation(player: Player, tier: number)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then return end
	
	local TargetSlotNum = PlayerAttributes.getAttribute(player, "SkipMutationSlotNum")
	local TargetSlotFloor = PlayerAttributes.getAttribute(player, "SkipMutationFloorNum")

	if TargetSlotNum == nil or TargetSlotFloor == nil then return end

	local Plot: Model? = DataPlots.GetPlayerPlot(player)
	if not Plot then return end

	local Floor: Model? = PlotUtil.getFloor(Plot, TargetSlotFloor)
	if not Floor then return end

	local Slots = Floor:FindFirstChild("Slots")
	if not Slots then return end

	local Slot = Slots:FindFirstChild(TargetSlotNum)
	if not Slot then return end

	local GetSlotInfo = PlotUtil.getSlotData(Slot)
	if not GetSlotInfo then return end

	if GetSlotInfo.IsForSale then return end
	if not GetSlotInfo.IsOccupied then return end
	if GetSlotInfo.IsHatchable then return end
	if not GetSlotInfo.IsMutatable then return end

	local dropper: Folder? = PlotUtil.getPlotDropper(Plot)
	if not dropper then return end

	local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
		PlotUtil.getDropperSpinScreen(dropper)
	if not Screen then return end
	
	local Placements: Folder = PlotUtil.getSlotsPlacements(Slots)
	if not Placements then return end

	local Placement = PlotUtil.getPlacementFromIndex(
		Placements, TargetSlotNum
	)
	if not Placement then return end
	if Placement:GetAttribute("Type") ~= "Labubu" then return end
	
	local floorNum, slotNum = TargetSlotFloor, TargetSlotNum
	
	local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement :: Types.Labubu?
	if not labubuData then return end

	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
	if not GetMutationExtraInfo then return end
	
	if not GetMutationExtraInfo.NextMutationTier then return end
	if GetMutationExtraInfo.CurrentMutationTier ~= tier then return end

	-- DataPlots.MutateLabubu(player, Placement, Slot, floorNum, slotNum)
	labubuData.MutationTime = 0
end

ProductPurchaseHandlers["Skip Mutation 1"] = function(player: Player)
	SkipLabubuMutation(player, 1)
end

ProductPurchaseHandlers["Skip Mutation 2"] = function(player: Player)
	SkipLabubuMutation(player, 2)
end

ProductPurchaseHandlers["Skip Mutation 3"] = function(player: Player)
	SkipLabubuMutation(player, 3)
end

ProductPurchaseHandlers["Skip Mutation 4"] = function(player: Player)
	SkipLabubuMutation(player, 4)
end

ProductPurchaseHandlers["Skip Mutation 5"] = function(player: Player)
	SkipLabubuMutation(player, 5)
end

ProductPurchaseHandlers["Skip Mutation 6"] = function(player: Player)
	SkipLabubuMutation(player, 6)
end

ProductPurchaseHandlers["Skip Mutation 7"] = function(player: Player)
	SkipLabubuMutation(player, 7)
end

ProductPurchaseHandlers["Skip Mutation 8"] = function(player: Player)
	SkipLabubuMutation(player, 8)
end

ProductPurchaseHandlers["Skip Mutation 9"] = function(player: Player)
	SkipLabubuMutation(player, 9)
end

ProductPurchaseHandlers["Skip Mutation 10"] = function(player: Player)
	SkipLabubuMutation(player, 10)
end

-- Temporary Traits

local LUCK_DURATION = GlobalSettings.SERVER_LUCK_DURATION
local LUCK_MULTIPLIERS = GlobalSettings.SERVER_LUCK_MULTIPLIERS

local ServerLuck = {
	Multiplier = 1,
	ExpiresAt = 0
}

local function addServerLuck(tier: number)
	local now = os.time()
	local addedMultiplier = LUCK_MULTIPLIERS[tier]

	-- Extend or reset duration
	if ServerLuck.ExpiresAt > now then
		ServerLuck.ExpiresAt += LUCK_DURATION
	else
		ServerLuck.ExpiresAt = now + LUCK_DURATION
	end

	-- Only increase multiplier, never downgrade
	ServerLuck.Multiplier = math.max(ServerLuck.Multiplier, addedMultiplier)
	workspace:SetAttribute("ServerLuckMulti", ServerLuck.Multiplier)
	workspace:SetAttribute("ServerLuckExpiresAt", ServerLuck.ExpiresAt)
end

ProductPurchaseHandlers["Server Luck (Tier 1)"] = function(player: Player)
	addServerLuck(1)
end

ProductPurchaseHandlers["Server Luck (Tier 2)"] = function(player: Player)
	addServerLuck(2)
end

ProductPurchaseHandlers["Server Luck (Tier 3)"] = function(player: Player)
	addServerLuck(3)
end

--local GOLDEN_RAIN_DURATION = GlobalSettings.GOLDEN_RAIN_DURATION

--local GoldenRain = {
--	ExpiresAt = 0
--}

--local function addGoldenRain()
--	local now = os.time()

--	if GoldenRain.ExpiresAt > now then
--		GoldenRain.ExpiresAt += GOLDEN_RAIN_DURATION
--	else
--		GoldenRain.ExpiresAt = now + GOLDEN_RAIN_DURATION
--		workspace:SetAttribute("GoldenRain", true)
--	end

--	workspace:SetAttribute("GoldenRainExpiresAt", GoldenRain.ExpiresAt)
--end

--ProductPurchaseHandlers["Golden Rain"] = function(player: Player)
--	addGoldenRain()
--end

task.spawn(function()
	while true do
		local now = os.time()

		-- SERVER LUCK EXPIRATION
		if ServerLuck.ExpiresAt > 0 and now >= ServerLuck.ExpiresAt then
			ServerLuck.ExpiresAt = 0
			ServerLuck.Multiplier = 1
			workspace:SetAttribute("ServerLuckMulti", 1)
			workspace:SetAttribute("ServerLuckExpiresAt", 0)
		end

		-- GOLDEN RAIN EXPIRATION
		--if GoldenRain.ExpiresAt > 0 and now >= GoldenRain.ExpiresAt then
		--	GoldenRain.ExpiresAt = 0
		--	workspace:SetAttribute("GoldenRain", false)
		--	workspace:SetAttribute("GoldenRainExpiresAt", 0)
		--end

		task.wait(1)
	end
end)

ProductPurchaseHandlers["Super Speed"] = function(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then return end

	local trove = Trove.new()
	trove:AttachToInstance(player)

	local SuperSpeedDuration = GlobalSettings.SuperSpeedDuration
	local SuperSpeedAttribute = player:GetAttribute("SuperSpeed")

	if not SuperSpeedAttribute then
		local currentTime = getUTCtime()

		player:SetAttribute("SuperSpeed", currentTime + SuperSpeedDuration)
	else
		player:SetAttribute("SuperSpeed", SuperSpeedAttribute + SuperSpeedDuration)
	end

	trove:Add(
		task.spawn(function()
			local now = getUTCtime()
			local remaining = player:GetAttribute("SuperSpeed") - now

			task.wait(remaining)

			local now = getUTCtime()
			local remaining = player:GetAttribute("SuperSpeed") - now

			if remaining <= 0 then
				player:SetAttribute("SuperSpeed", nil)
			end
		end)
	)
end

ProductPurchaseHandlers["Magic Shield (24h)"] = function(player: Player)
	local profileData = DataHandler.getProfileData(player)
	if not profileData then return end

	if profileData.Gamepasses["Magic Shield (Perm)"] then
		return
	end

	local DURATION = 24 * 60 * 60
	local now = os.time()

	local expiresAt = profileData.Traits["Magic Shield"]

	if expiresAt and expiresAt > now then
		profileData.Traits["Magic Shield"] = expiresAt + DURATION
	else
		profileData.Traits["Magic Shield"] = now + DURATION
	end
end

task.spawn(function()
	while true do
		local now = os.time()

		for _, player in ipairs(game.Players:GetPlayers()) do
			local profileData = DataHandler.getProfileData(player)
			if not profileData then continue end

			local hasPerm = profileData.Gamepasses["Magic Shield (Perm)"]
			local expiresAt = profileData.Traits["Magic Shield"]

			local active = hasPerm or (expiresAt ~= nil and expiresAt > now)

			-- Only set if changed (avoids spam)
			if player:GetAttribute("MagicShield") ~= active then
				player:SetAttribute("MagicShield", active)
			end
			
			task.wait()
		end

		task.wait(1)
	end
end)

ProductPurchaseHandlers["x2 Cash (15m)"] = function(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then return end
	
	local trove = Trove.new()
	trove:AttachToInstance(player)
	
	local x2CashDuration = GlobalSettings.x2CashDuration
	local x2CashAttribute = player:GetAttribute("x2Cash")

	if not x2CashAttribute then
		local currentTime = getUTCtime()

		player:SetAttribute("x2Cash", currentTime + x2CashDuration)
	else
		player:SetAttribute("x2Cash", x2CashAttribute + x2CashDuration)
	end
	
	trove:Add(
		task.spawn(function()
			local now = getUTCtime()
			local remaining = player:GetAttribute("x2Cash") - now
			
			task.wait(remaining)
			
			local now = getUTCtime()
			local remaining = player:GetAttribute("x2Cash") - now
			
			if remaining <= 0 then
				player:SetAttribute("x2Cash", nil)
			end
		end)
	)
end

ProductPurchaseHandlers["x2 Luck (15m)"] = function(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then return end

	local trove = Trove.new()
	trove:AttachToInstance(player)

	local x2LuckDuration = GlobalSettings.x2LuckDuration
	local x2LuckAttribute = player:GetAttribute("x2Luck")

	if not x2LuckAttribute then
		local currentTime = getUTCtime()

		player:SetAttribute("x2Luck", currentTime + x2LuckDuration)
	else
		player:SetAttribute("x2Luck", x2LuckAttribute + x2LuckDuration)
	end

	trove:Add(
		task.spawn(function()
			local now = getUTCtime()
			local remaining = player:GetAttribute("x2Luck") - now

			task.wait(remaining)

			local now = getUTCtime()
			local remaining = player:GetAttribute("x2Luck") - now

			if remaining <= 0 then
				player:SetAttribute("x2Luck", nil)
			end
		end)
	)
end

-- Spins

ProductPurchaseHandlers["1 Spin"] = function(player: Player)
 	DataSpin.RewardSpin(player, 1)
end

ProductPurchaseHandlers["3 Spins"] = function(player: Player)
	DataSpin.RewardSpin(player, 3)
end






-- Gifting

local function ExtractGifts(productsTable)
	local Gifts = {}

	for name, id in pairs(productsTable) do
		-- Only process gifting entries
		if string.find(name, "^Gifting") then

			-- Format: "Gifting | Product | x2 Cash (15m)"
			local segments = string.split(name, " | ")

			-- segments[1] = "Gifting"
			-- segments[2] = "Product" or "Pass"
			-- segments[3] = Actual item name

			if #segments >= 3 then
				table.insert(Gifts, {
					Name = segments[3],
					Id = id,
					Type = segments[2], -- "Product" or "Pass"
					FullName = name :: string
				})
			end
		end
	end

	return Gifts
end

-- Usage
local GiftItems = ExtractGifts(Products)

for _, gift in ipairs(GiftItems) do
	--print(gift.Name, gift.Id, gift.Type, gift.FullName)
	
	ProductPurchaseHandlers[gift.FullName] = function(player: Player)
		local profileData, clientData = DataHandler.getProfileData(player)
		if profileData == nil then return end
		
		local TargetGiftPlayerId = PlayerAttributes.getAttribute(player, "GiftTarget")
		if not TargetGiftPlayerId then return end

		local TargetPlayer: Player? = Players:GetPlayerByUserId(TargetGiftPlayerId)

		if TargetPlayer then
			if gift.Type == "Product" then
				local ProductFunc = ProductPurchaseHandlers[gift.Name]
				
				if ProductFunc then
					ProductFunc(TargetPlayer)
					
					NotifySuccess:FireClient(player, 
						`You gifted {gift.Name} to @{TargetPlayer.Name}`
					)
					NotifyInfo:FireClient(TargetPlayer, 
						`@{player.Name} gifted you {gift.Name}`
					)
					
					Network.Purchases.ConfettiEffect:FireClient(TargetPlayer)
				end
			else
				local success = DataGamepasses.grantGamepass(TargetPlayer, gift.Name, true)

				if success then
					NotifySuccess:FireClient(player, 
						`You gifted {gift.Name} to @{TargetPlayer.Name}`
					)
					NotifyInfo:FireClient(TargetPlayer, 
						`@{player.Name} gifted you {gift.Name} Pass`
					)
					
					Network.Purchases.ConfettiEffect:FireClient(TargetPlayer)
				end
			end
		else

		end
	end
end

return ProductPurchaseHandlers