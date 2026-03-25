--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Bases = workspace:WaitForChild("Bases")
local BaseSamples = ReplicatedStorage:WaitForChild("BaseSamples")

local Network = require(ReplicatedStorage.Network)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)
local SyncedState = require(ReplicatedStorage.Shared.SyncedState)
local DataHandler = require(ServerStorage.DataHandler)
local Types = require(ReplicatedStorage.Shared.Types)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local PlayerAttributes = require(ServerStorage.Modules.PlayerAttributes)
local PlayerCooldowns = require(ServerStorage.Modules.PlayerCooldowns)
local DataCash = require(ServerStorage.DataComponents.DataCash)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)
local RngUtil = require(ReplicatedStorage.Shared.Utility.RngUtil)
local PlayerConnections = require(ServerStorage.Modules.PlayerConnections)
local RarityTextColors = require(ReplicatedStorage.Data.TextColors.Rarity)
local MutationTextColors = require(ReplicatedStorage.Data.TextColors.Mutation)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)
local getProductStaticPrice = require(ReplicatedStorage.Shared.Utility.Roblox.getProductStaticPrice)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)
local Reconcile = require(ReplicatedStorage.Shared.Utility.Table.Reconcile)
local Pity = require(ReplicatedStorage.Data.Pity)
local getUTCtimeMS = require(ReplicatedStorage.Shared.Utility.Time.getUTCtimeMS)
local getUTCtime = require(ReplicatedStorage.Shared.Utility.Time.getUTCtime)
local copyAttributes = require(ReplicatedStorage.Shared.Utility.Roblox.copyAttributes)
local copyAttributesFromTable = require(ReplicatedStorage.Shared.Utility.Roblox.copyAttributesFromTable)
local DataBackpack = require(ServerStorage.DataComponents.DataBackpack)
local generateGUID = require(ReplicatedStorage.Shared.Utility.String.generateGUID)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local RatelimitUtil = require(ReplicatedStorage.Shared.Utility.RatelimitUtil)
local DataIndex = require(ServerStorage.DataComponents.DataIndex)
local TimeFormat = require(ReplicatedStorage.Shared.Utility.Format.TimeFormat)
local richColor = require(ReplicatedStorage.Shared.Utility.String.richColor)
local getPlayerFullBackpack = require(ReplicatedStorage.Shared.Utility.Roblox.getPlayerFullBackpack)
local RebirthModule = require(ReplicatedStorage.Data.Rebirths)

local GlobalSettings = require(ReplicatedStorage.GlobalSettings)

local EggInfoUI: BillboardGui = ReplicatedStorage.Assets.Interface.BillboardGui.InfoUI

local Eggs = ReplicatedStorage.Assets.Eggs
local EggTools = ReplicatedStorage.Assets.EggTools
local LabubuTools = ReplicatedStorage.Assets.LabubuTools
local Labubus = ReplicatedStorage.Assets.Hatchables

local NotifyError = Network.Notifications.Error
local NotifySuccess = Network.Notifications.Success
local NotifyInfo = Network.Notifications.Info
local NotifyWarn = Network.Notifications.Warning

local DataPlots = {}

local PlayerPlots = {}     -- [player] = plot
local PlotModels = {}      -- free plots only
local PlotStates = {}      -- [plot] = player or nil
local AllPlots = {}        -- all plots (free + taken)
local CachedPlotsFloors = {}
local CachedPlotsTextsUI = {}

local CachedEggsFusionEffect = {}

local SlotsTroves = {} :: { [any]: Trove.Trove }

local PlotsInitialized = false -- to prevent possible race conditions

-- Load Product Prices

local BuyLegendaryInstantProduct = Products["Instant Legendary Block"]
local BuyLegendaryInstantProductInfo = PlotUtil.ProductsInfo.LegendaryInstant
local BuyLegendaryInstantProductPrice = BuyLegendaryInstantProductInfo and 
	BuyLegendaryInstantProductInfo.PriceInRobux or 0

local BuyMythicInstantProduct = Products["Instant Mythic Block"]
local BuyMythicInstantProductInfo = PlotUtil.ProductsInfo.BuyMythicInstant
local BuyMythicInstantProductPrice = BuyMythicInstantProductInfo and 
	BuyMythicInstantProductInfo.PriceInRobux or 0

--task.spawn(function()
--	getProductInfo(BuyLegendaryInstantProduct, Enum.InfoType.Product):andThen(function(productInfo)
--		BuyLegendaryInstantProductPrice = productInfo.PriceInRobux or 0
--	end)

--	getProductInfo(BuyMythicInstantProduct, Enum.InfoType.Product):andThen(function(productInfo)
--		BuyMythicInstantProductPrice = productInfo.PriceInRobux or 0
--	end)
--end)

----------------------------------------------------
-- Cache plots
----------------------------------------------------
for _, plot in ipairs(Bases:GetChildren()) do
	table.insert(PlotModels, plot)
	table.insert(AllPlots, plot)
	PlotStates[plot] = nil
	
	local Floor1: Model = plot:WaitForChild("Floor1")
	local Architecture: Folder = Floor1:WaitForChild("Architecture")
	local BackSurface: BasePart = Architecture:WaitForChild("BackSurface")
	local SurfaceGui: SurfaceGui = BackSurface:WaitForChild("SurfaceGui")
	local TextLabel: TextLabel = SurfaceGui:WaitForChild("TextLabel")
	
	CachedPlotsTextsUI[plot] = TextLabel
	
	-- Floors
	CachedPlotsFloors[plot] = CachedPlotsFloors[plot] or {}
	
	for _, Floor in pairs(plot:GetChildren()) do
		if Floor:IsA("Model") then
			table.insert(CachedPlotsFloors[plot], Floor)
		end
	end
	
	local EggsEffects = Floor1:WaitForChild("Dropper")
		:WaitForChild("Effects"):WaitForChild("EggsFusion")
	CachedEggsFusionEffect[plot] = EggsEffects
	
	EggsEffects.Parent = nil
end

-- Init Eggs
for _, egg in pairs(Eggs:GetChildren()) do
	PlotUtil.setEggPriceInfoUI(egg)
	
	local clone = egg:Clone()
	local eggTool = PlotUtil.ConvertEggModelToEggTool(clone)
	eggTool.Parent = EggTools
end

-- Init Labubus
for _, labubu in pairs(Labubus:GetChildren()) do
	local clone = labubu:Clone()
	local eggTool = PlotUtil.ConvertLabubuModelToLabubuTool(clone)
	eggTool.Parent = LabubuTools
end

----------------------------------------------------
-- Get empty plot
----------------------------------------------------
function DataPlots.GetEmptyPlot(): Model?
	return PlotModels[1]
end

----------------------------------------------------
-- Get all plots (free + occupied)
----------------------------------------------------
function DataPlots.GetAllPlots(): {Model}
	return AllPlots
end

----------------------------------------------------
-- Teleport player to plot
----------------------------------------------------
function DataPlots.TeleportPlayerToPlot(player: Player, plot: Model)
	local Floor1: Model = plot:FindFirstChild("Floor1")
	if not Floor1 then return end

	local SpawnPart: BasePart = Floor1:FindFirstChild("Spawn")
	if not SpawnPart then return end

	local character = player.Character
	if not character then return end

	character:PivotTo(SpawnPart.CFrame)
end

----------------------------------------------------
-- Assign plot
----------------------------------------------------
function DataPlots.AssignPlot(player: Player)
	if PlayerPlots[player] then
		return PlayerPlots[player]
	end
	
	if not PlotsInitialized then
		repeat 
			warn("Waiting for plots to initialize")
			task.wait(0.1)
		until PlotsInitialized
	end

	local plot = DataPlots.GetEmptyPlot()
	if not plot then
		warn("No free plots available")
		
		repeat task.wait(0.1) until DataPlots.GetEmptyPlot() or not player:IsDescendantOf(Players)
		plot = DataPlots.GetEmptyPlot()
		
		if not plot or not player:IsDescendantOf(Players) then
			warn("No free plots available #2")
			return nil
		end
	end

	-- remove from free cache
	table.remove(PlotModels, 1)
	
	--CachedPlotsTextsUI[plot].Text = player.Name
	CachedPlotsTextsUI[plot].Text = player.DisplayName .. "'s Plot"

	PlayerPlots[player] = plot
	PlotStates[plot] = player
	
	--local profileData, clientData = DataHandler.getProfileData(player)
	--if profileData ~= nil and clientData ~= nil then
	--	clientData.Plot(plot)
	--end
	
	DataPlots.ClearPlot(plot)

	return plot
end

----------------------------------------------------
-- Unassign plot from player
----------------------------------------------------
function DataPlots.UnassignPlot(player: Player)
	local plot = PlayerPlots[player]
	if not plot then
		return nil
	end
	
	PlayerPlots[player] = nil
	PlotStates[plot] = nil
	
	DataPlots.ClearPlot(plot, true)

	-- return plot back to free cache
	table.insert(PlotModels, plot)

	return plot
end

function DataPlots.ExpandPlotFloors(plot: Model, amount: number)
	if amount <= 0 then return end

	-- Expand Floors
	for _, floor in ipairs(CachedPlotsFloors[plot]) do
		local floorNum = tonumber(string.match(floor.Name, "%d+"))
		if amount >= floorNum - 1 then
			floor.Parent = plot
		end
	end
end

function DataPlots.EnableSpin(player: Player)
	local plot: Model = DataPlots.GetPlayerPlot(player)
	if not plot then return end
	
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then return end
	
	local dropper = PlotUtil.getPlotDropper(plot)
	if not dropper then return end
	
	local Screen, Button, GoButtonUI, BarUI = PlotUtil.getDropperSpinScreen(dropper)
	if not Button then return end
	
	Button.Trigger:Fire(false, true)
	
	DataPlots.SetPlotSpinState(plot, "on")

	if not profileData.PlotData.SpinInfo.CanSpin or profileData.PlotData.SpinInfo.SpinBroken then
		profileData.PlotData.SpinInfo.CanSpin = true
		profileData.PlotData.SpinInfo.SpinBroken = false

		clientData.PlotData(deepCopy(profileData.PlotData))
	end
end

function DataPlots.UpdatePlayerSpinInfo(player: Player, onJoin: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then return end
	
	local plot: Model = DataPlots.GetPlayerPlot(player)
	if not plot then return end

	local SpinCooldown: number = profileData.PlotData.SpinInfo.SpinCooldown
	local Remaining: number = SpinCooldown - getUTCtime()
	
	if Remaining > 0 then
		if Remaining <= GlobalSettings.SpinCooldown and not onJoin then
			DataPlots.SetPlotSpinState(plot, "idle", profileData.PlotData.SpinInfo.SpinCooldown)
		else
			DataPlots.SetPlotSpinState(plot, "off", profileData.PlotData.SpinInfo.SpinCooldown)
		end
		
		task.wait(Remaining)
	end
	
	local NewSpinCooldown: number = profileData.PlotData.SpinInfo.SpinCooldown
	if NewSpinCooldown ~= SpinCooldown then
		return
	end
	
	DataPlots.EnableSpin(player)
end

function DataPlots.UpdateRollsInfo(plot: Model, RollsInfo: Types.PlotRollsInfo, SpawnEggs: boolean?)
	if not plot or not plot.Parent then return end
	if not RollsInfo then return end
	
	local dropper: Model = PlotUtil.getPlotDropper(plot)
	if not dropper then return end
	
	local EggsRollInfoScreen: BasePart?, LuckBoardUI: BillboardGui? 
		= PlotUtil.getEggRollsScreen(dropper)
	
	if not EggsRollInfoScreen or not LuckBoardUI then return end
	
	local BoardFrame: Frame = LuckBoardUI:FindFirstChild("BoardFrame")
	if not BoardFrame then return end
	
	local EpicLabel: TextLabel = BoardFrame:FindFirstChild("EpicLabel")
	local LegendaryLabel: TextLabel = BoardFrame:FindFirstChild("LegendaryLabel")
	local MythicalLabel: TextLabel = BoardFrame:FindFirstChild("MythicalLabel")
	
	if not EpicLabel or not LegendaryLabel or not MythicalLabel then return end
	
	local RollsAmount: number = RollsInfo.EggRollsCount
	
	local EpicRolls: number = PlotUtil.getRollsLeft(RollsAmount, Pity.Epic)
	local LegendaryRolls: number = PlotUtil.getRollsLeft(RollsAmount, Pity.Legendary)
	local MythicalRolls: number = PlotUtil.getRollsLeft(RollsAmount, Pity.Mythic)

	EpicLabel.Text =
		`<font color="#ff80ff">Epic</font> Egg In {EpicRolls} Rolls`

	LegendaryLabel.Text =
		`<font color="#ffff00">Legendary</font> Egg In {LegendaryRolls} Rolls`

	MythicalLabel.Text =
		`<font color="#ff0000">Mythical</font> Egg In {MythicalRolls} Rolls`
	
	if SpawnEggs then
		local EggPillars: { Model } = PlotUtil.getEggPillars(dropper)
		if not EggPillars then return end

		local EggsRolls: Folder = dropper:FindFirstChild("EggRolls")
		if not EggsRolls then return end

		EggsRolls:ClearAllChildren()
		
		local EggPillarsByIndex: { [number]: Model } = {}

		for _, pillar in pairs(EggPillars) do
			local EggPillarInfo = PlotUtil.getEggPillarInfo(pillar)
			if not EggPillarInfo then continue end
			
			EggPillarsByIndex[EggPillarInfo.Index] = pillar
		end
		
		for index, eggName in pairs(RollsInfo.EggRolls) do
			if not EggPillarsByIndex[index] then
				warn("Egg pillar not found for index: " .. index)
				continue
			end
			
			local EggPillarInfo = PlotUtil.getEggPillarInfo(EggPillarsByIndex[index])
			
			local egg: Model = PlotUtil.spawnEggRoll(eggName, 
				EggPillarsByIndex[index], not EggPillarInfo.Premium, "SpinRoll")
			egg.Parent = EggsRolls
		end
	end
end

function DataPlots.CollectAllSlotCash(profileSlotData: Types.Slot, player: Player?)
	local CashToCollect = profileSlotData.Cash + profileSlotData.OfflineCash
	if CashToCollect > 0 then
		profileSlotData.Cash = 0
		profileSlotData.OfflineCash = 0
		profileSlotData.LastOfflineCashCollected = os.time()
		profileSlotData.HasBeenHoldingOfflineCash = false
		
		if player then
			DataCash.giveCash(player, CashToCollect)
		end
	end
end

function DataPlots.SetPlotSpinState(plot: Model, state: string, cooldown: number?)
	local Dropper: Folder? = PlotUtil.getPlotDropper(plot)
	if not Dropper then return end
	
	local SpinScreen: Model?, 
		Button: BasePart?, 
		GoButtonUI: BillboardGui? = PlotUtil.getDropperSpinScreen(Dropper)
		
	if not SpinScreen or not Button or not GoButtonUI then return end
	
	if state == "on" then
		Button.Color = Color3.fromRGB(75, 151, 75)
	elseif state == "off" then
		Button.Color = Color3.fromRGB(151, 0, 3)
	elseif state == "idle" then
		Button.Color = Color3.fromRGB(151, 141, 0)
	end
end

function DataPlots.SpawnHatchableAtSlot(slot: Model, labubuData: Types.Labubu, player: Player?)
	local slots: Folder = slot.Parent
	if not slots then return end

	local slotsPlacement = PlotUtil.getSlotsPlacements(slots)
	if not slotsPlacement then return end

	local getSlotInfo = PlotUtil.getSlotData(slot)
	if not getSlotInfo then return end

	local getSlotPartsInfo = PlotUtil.getSlotWorldData(slot)
	if not getSlotPartsInfo then return end

	if getSlotInfo.IsForSale then return end

	local labubuModel: Model? = nil :: Model

	labubuModel = PlotUtil.getHatchableModel(labubuData.Name)
	if not labubuModel then return warn("No hatchable model found for: " .. labubuData.Name) end
	
	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
	if not GetMutationExtraInfo then return end
	
	labubuModel = labubuModel:Clone()

	copyAttributesFromTable(labubuData, labubuModel)
	
	for _, part in pairs(labubuModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	
	for _, fx in pairs(labubuModel:GetDescendants()) do
		if fx:HasTag("FX") then
			fx:Destroy()
		end
	end

	PlotUtil.setHatchableInfoUI(labubuModel, GetMutationExtraInfo.CurrentMutationName,
		labubuData.IsMutating, labubuData
	)
	labubuModel:SetAttribute("ParentIndex", getSlotInfo.SlotNum)

	local GetExtentsSize: Vector3 = labubuModel:GetExtentsSize()
	local GetExtentsSizeY: number = GetExtentsSize.Y

	labubuModel:PivotTo(
		getSlotInfo.MainStand.CFrame + 
			Vector3.new(0,
				GetExtentsSizeY / 2 + getSlotInfo.MainStand.Size.Y/2, 
				0)
	)

	labubuModel.Parent = slotsPlacement
end

function DataPlots.HatchEgg(egg: Model, slot: Model, player: Player?, mutationTier: number?)
	local labubuName, labubuData = PlotUtil.TranslateEggToHatchable(egg)
	if not labubuName or not labubuData then return end
	
	local slots = slot.Parent
	if not slots then return end
	
	local slotsPlacement = PlotUtil.getSlotsPlacements(slots)
	if not slotsPlacement then return end

	local getSlotInfo = PlotUtil.getSlotData(slot)
	if not getSlotInfo then return end

	local getSlotPartsInfo = PlotUtil.getSlotWorldData(slot)
	if not getSlotPartsInfo then return end
	
	if getSlotInfo.IsForSale then return end
	local placement: Model? = PlotUtil.getPlacementFromIndex(slotsPlacement, tonumber(slot.Name))
	if not placement then return end
	
	local eggData = PlotUtil.EggsData[egg.Name]
	if not eggData then return end
	
	mutationTier = mutationTier or egg:GetAttribute("EggMutationTier")
	
	if player then
		local profileData, clientData = DataHandler.getProfileData(player)
		if profileData then
			local currentTime = getUTCtime()

			local LabubuTemplate = PlotUtil.CreateLabubuTemplateFromEggData(
				labubuName, labubuData, {
					MutationTier = mutationTier
				}, eggData.Rarity, egg.Name
			)
			
			profileData.PlotData.Floors[getSlotInfo.floorNum].Slots[getSlotInfo.SlotNum].Placement
				= LabubuTemplate
			
			placement:Destroy()
			
			DataPlots.SpawnHatchableAtSlot(slot, 
				profileData.PlotData.Floors[getSlotInfo.floorNum].Slots[getSlotInfo.SlotNum].Placement,
				player
			)
			DataPlots.SetSlotState(slot, false, true, 
				profileData.PlotData.Floors[getSlotInfo.floorNum].Slots[getSlotInfo.SlotNum], player)
			
			DataIndex.AddLabubuToIndex(player, LabubuTemplate)
			
			profileData.EggsHatched += 1
			
			if clientData then
				clientData.PlotData(deepCopy(profileData.PlotData))
				clientData.EggsHatched(profileData.EggsHatched)
			end
		end
		
		NotifySuccess:FireClient(player, "Successfully hatched egg!")
	end
end

-- Gets Called at Buy Slot & Clear Slot & Place At Slot & Loading Player Slots
function DataPlots.SetSlotState(slot: Model, isForSale: boolean?,  isOccupied: boolean?,
	profileSlotData: Types.Slot, player: Player?
)
	local slotPlacement = profileSlotData and profileSlotData.Placement
	
	isForSale = isForSale or false
	isOccupied = isOccupied or false
	
	local Slots = slot.Parent
	if not Slots then return end
	
	local getSlotWorldData = PlotUtil.getSlotWorldData(slot)
	if not getSlotWorldData then return end
	
	local getSlotData = PlotUtil.getSlotData(slot)
	if not getSlotData then return end
	
	local Button: Model = getSlotWorldData.Button
	if not Button then return end

	local slotNum = tonumber(slot.Name)
	local IsVipSlot: boolean? = slot:GetAttribute("VipSlot")

	local CollectPart: BasePart = getSlotWorldData.CollectPart
	if not CollectPart then return end

	local FloatingCollectUI: BillboardGui = getSlotWorldData.FloatingCollectUI
	if not FloatingCollectUI then return end

	local Display: BasePart = getSlotWorldData.Display
	if not Display then return end

	local Screen: Model = getSlotWorldData.Screen
	if not Screen then return end

	local ScreenGo: BasePart = getSlotWorldData.ScreenGo
	if not ScreenGo then return end

	local ScreenMain: BasePart = getSlotWorldData.ScreenMain
	if not ScreenMain then return end

	local GoButtonUI: BillboardGui = getSlotWorldData.GoButtonUI
	if not GoButtonUI then return end

	local NextMutationUI: BillboardGui = getSlotWorldData.NextMutationUI
	if not NextMutationUI then return end
	
	SlotsTroves[slot] = SlotsTroves[slot] or Trove.new()
	SlotsTroves[slot]:Clean()

	slot:SetAttribute("Occupied", isOccupied)
	slot:SetAttribute("ForSale", isForSale)
	
	if slotPlacement and slotPlacement.Type == "Block" then
		if slotPlacement.IsHatching and slotPlacement.HatchTimeLeft 
			and slotPlacement.HatchTimeLeft <= 0 then
			slot:SetAttribute("IsHatching", false)
		else
			slot:SetAttribute("Hatchable", false)
		end
		
		if slotPlacement.IsHatching and slotPlacement.HatchTimeLeft > 0 then
			slot:SetAttribute("IsHatching", true)
		else
			slot:SetAttribute("IsHatching", false)
		end
		
		slot:SetAttribute("ReadyToBeginMutate", nil)
		slot:SetAttribute("IsMutatable", nil)
		slot:SetAttribute("ReadyToMutate", nil)
		slot:SetAttribute("IsMutating", nil)
	else
		slot:SetAttribute("Hatchable", nil)
		slot:SetAttribute("IsHatching", nil)
		
		if slotPlacement and slotPlacement.Type == "Labubu" then
			slot:SetAttribute("ReadyToBeginMutate", not slotPlacement.IsMutating
				and (not slotPlacement.MutationTime or 
					(slotPlacement.MutationTime and slotPlacement.MutationTime > 0))
			)
			slot:SetAttribute("IsMutatable", true)
			
			slot:SetAttribute("IsMutating", slotPlacement.IsMutating or nil)
			
			slot:SetAttribute("ReadyToMutate", slotPlacement.IsMutating and slotPlacement.MutationTime
				and slotPlacement.MutationTime <= 0
			)
		else
			slot:SetAttribute("ReadyToBeginMutate", nil)
			slot:SetAttribute("IsMutatable", nil)
			slot:SetAttribute("ReadyToMutate", nil)
			slot:SetAttribute("IsMutating", nil)
		end
	end
		
	if not isForSale then -- Not For Sale
		if not isOccupied then -- Unoccupied
			--FloatingCollectUI.Enabled = true
			--GoButtonUI.Enabled = true
			
			ScreenGo.Color = Color3.fromRGB(255, 0, 0)
			GoButtonUI.Enabled = false
			FloatingCollectUI.Enabled = false
			
			NextMutationUI.DisplayScreen.PriceText.Text = "- - -"
			NextMutationUI.DisplayScreen.PriceText.TextColor3 = Color3.fromRGB(255, 255, 255)
			NextMutationUI.TitleLabel.Text = "Empty Slot"
			
			--ScreenGo.Color = Color3.fromRGB(0, 255, 0)
		else -- Not For Sale & Occupied
			local player: Player? = player or PlotUtil.getPlotOwnerFromSlot(slot)
			if not player then return end
			
			local profileData, clientData = DataHandler.getProfileData(player)
			if not profileData then return end
			
			if slotPlacement then
				local PlacementFolder: Folder = PlotUtil.getSlotsPlacements(Slots)
				if not PlacementFolder then return end
				
				local placementModel = PlotUtil.getPlacementFromIndex(
					PlacementFolder, getSlotData.SlotNum
				)
				if not placementModel then return end
				
				if slotPlacement.Type == "Block" then
					local eggPlacement: Types.Egg = slotPlacement
					
					-- Egg
					
					if eggPlacement.IsHatching then
						ScreenGo.Color = Color3.fromRGB(255, 0, 0)
						GoButtonUI.Enabled = false
						FloatingCollectUI.Enabled = false

						NextMutationUI.TitleLabel.Text = "Hatching in"
						
						local function UpdateHatchTimeState()
							if player:IsDescendantOf(Players) then
								local newPlacementModel = PlotUtil.getPlacementFromIndex(
									PlacementFolder, getSlotData.SlotNum
								)
								if placementModel ~= newPlacementModel then return end
								
								if eggPlacement.HatchTimeLeft > 0 then
									NextMutationUI.DisplayScreen.PriceText.Text = 
										TimeFormat.short(eggPlacement.HatchTimeLeft)
									NextMutationUI.DisplayScreen.PriceText.TextColor3 = 
										Color3.fromRGB(255, 0, 0)
									slot:SetAttribute("IsHatching", true)
								else
									NextMutationUI.DisplayScreen.PriceText.Text = "READY!"
									NextMutationUI.DisplayScreen.PriceText.TextColor3 = 
										Color3.fromRGB(0, 255, 0)
									
									ScreenGo.Color = Color3.fromRGB(0, 255, 0)
									
									slot:SetAttribute("Hatchable", true)
									slot:SetAttribute("IsHatching", nil)
									
									return true
								end
							end
						end
						
						if not UpdateHatchTimeState() then
							local trove = Trove.new()
							local onDisconnect = trove:AttachToInstance(placementModel, 
								function()
									eggPlacement.HatchTimeLeft = 0
									
									UpdateHatchTimeState()
								end
							)
							
							trove:Add(
								task.spawn(function()
									while task.wait(1) do
										if UpdateHatchTimeState() then break end
										
										--local TripleHatchMultiplier = profileData.Gamepasses["Triple Hatch"]
										--	and 3 or 1
										
										local IsSuperSpeed = player:GetAttribute("SuperSpeed")
										eggPlacement.HatchTimeLeft -= 
											math.floor((IsSuperSpeed and 
												1 * GlobalSettings.SuperSpeedMultiplier or 1))
													--* TripleHatchMultiplier)
										
										if UpdateHatchTimeState() then break end
									end
								end)
							)
						end
					else
						warn("SLOT OCCUPATION EGG NOT HATCHING CORRUPTION")
					end
				elseif slotPlacement.Type == "Labubu" then
					-- Labubu
					
					local LabubuPlacement: Types.Labubu = slotPlacement
					
					local MutationName = PlotUtil.MutationTierToName(LabubuPlacement.MutationTier)
					if not MutationName then return end

					local MutationTierInfo = PlotUtil.getMutationInfo(MutationName)
					if not MutationTierInfo then return end

					local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(LabubuPlacement)
					if not GetMutationExtraInfo then return end
					
					local NextMutationTier = GetMutationExtraInfo.NextMutationTier
					local NextMutationName = GetMutationExtraInfo.NextMutationName
					
					local NextMutationTierInfo = NextMutationName
						and PlotUtil.getMutationInfo(NextMutationName)
					
					local EggMutationData = PlotUtil.getEggMutationInfo(LabubuPlacement.EggType)
					if not EggMutationData then return end
					
					local EggMutationInfo = EggMutationData.Mutations[MutationName]
					if not EggMutationInfo then return end
					
					
					local function UpdateRevealingIn(): true?
						if not player:IsDescendantOf(Players) then
							return nil
						end

						if not placementModel:HasTag("MutatingModel") then
							placementModel:AddTag("MutatingModel")
						end

						if LabubuPlacement.MutationTime > 0 then
							NextMutationUI.DisplayScreen.PriceText.Text = 
								TimeFormat.short(LabubuPlacement.MutationTime)
							NextMutationUI.DisplayScreen.PriceText.TextColor3 = 
								Color3.fromRGB(255, 0, 0)
							ScreenGo.Color = Color3.fromRGB(255, 0, 0)
							
							slot:SetAttribute("IsMutating", true)
							placementModel:SetAttribute("IsMutating", true)

							return nil
						else
							NextMutationUI.DisplayScreen.PriceText.Text = 
								"READY!"
							NextMutationUI.DisplayScreen.PriceText.TextColor3 = 
								Color3.fromRGB(0, 255, 0)
							ScreenGo.Color = Color3.fromRGB(0, 255, 0)
							
							NextMutationUI.TitleLabel.Text = "Reveal Mutation"
							slot:SetAttribute("IsMutating", nil)
							slot:SetAttribute("ReadyToMutate", true)

							return true
						end
					end
					
					if LabubuPlacement.IsMutating then
						if not UpdateRevealingIn() then
							PlotUtil.setHatchableInfoUI(
								placementModel, GetMutationExtraInfo.CurrentMutationName, true,
								LabubuPlacement
							)
							NextMutationUI.TitleLabel.Text = "Mutating in"
							
							SlotsTroves[slot]:Add(
								task.spawn(function()
									while task.wait(1) do
										if UpdateRevealingIn() then break end
										
										local IsSuperSpeed = player:GetAttribute("SuperSpeed")
										LabubuPlacement.MutationTime -= math.floor(IsSuperSpeed and 
											1 * GlobalSettings.SuperSpeedMultiplier or 1)
										
										if UpdateRevealingIn() then break end
									end
								end)
							)
						end
					else

						if placementModel:HasTag("MutatingModel") then
							placementModel:RemoveTag("MutatingModel")
						end

						ScreenGo.Color = Color3.fromRGB(0, 255, 0)
						
						NextMutationUI.TitleLabel.Text = "Next Mutation"
						if NextMutationTierInfo and NextMutationTier then
							NextMutationUI.DisplayScreen.PriceText.Text = 
								"$" .. formatCommaValue(EggMutationInfo.Cost)
							NextMutationUI.DisplayScreen.PriceText.TextColor3 = 
								Color3.fromRGB(0, 255, 0)
							ScreenGo.Color = Color3.fromRGB(0, 255, 0)
						else
							NextMutationUI.DisplayScreen.PriceText.Text = "- - -"
							NextMutationUI.DisplayScreen.PriceText.TextColor3 = 
								Color3.fromRGB(255, 255, 255)
							ScreenGo.Color = Color3.fromRGB(255, 0, 0)
						end
					end
					
					local OfflineCashToCollect = profileSlotData.OfflineCash
					local LastOfflineCashHolderLeaveSession = 
						profileSlotData.LastOfflineCashHolderLeaveSession
					if LastOfflineCashHolderLeaveSession then
						local passed = os.time() - LastOfflineCashHolderLeaveSession
						
						FloatingCollectUI.OfflineCashLabel.Text = 
							"Offline Cash: $" .. formatCommaValue(OfflineCashToCollect)
							.. ` ({TimeFormat.compact2(passed)})`
					else
						FloatingCollectUI.OfflineCashLabel.Text = 
							"Offline Cash: $" .. formatCommaValue(OfflineCashToCollect)
					end
					FloatingCollectUI.OfflineCashLabel.Visible = OfflineCashToCollect > 0
					
					
					local function UpdateCashUI()
						if player:IsDescendantOf(Players) then
							FloatingCollectUI.PriceText.Text =
								"$" .. formatCommaValue(
									profileSlotData.Cash
								)
						end
					end

					UpdateCashUI()
					
					--FloatingCollectUI.Enabled = true

					SlotsTroves[slot]:Add(
						task.spawn(function()
							while task.wait(1) do
								--profileSlotData.Cash += GetMutationExtraInfo.CurrentMutationCPS
								profileSlotData.Cash += PlotUtil.CalculateCPS(LabubuPlacement, 
									profileData.CashMulti * 
										(profileData.Gamepasses["Index Reader"] and 
											GlobalSettings.IndexReaderMultiplier or 1)
								)

								UpdateCashUI()
							end
						end)
					)

					local CollectRatelimitUtil = RatelimitUtil.new(0.1)
					local function CollectCash()
						DataPlots.CollectAllSlotCash(profileSlotData, player)

						FloatingCollectUI.OfflineCashLabel.Visible = false

						UpdateCashUI()
					end
					
					SlotsTroves[slot]:Add(
						task.spawn(function()
							while task.wait(60) do
								if profileData.Gamepasses["Auto-Collect"] then
									CollectCash()
								end
							end
						end)
					)

					SlotsTroves[slot]:Add(
						CollectPart.Touched:Connect(function(otherPart: BasePart)
							if otherPart.Parent == player.Character then
								if profileSlotData.Cash > 0 then
									if not CollectRatelimitUtil:Try() then return end
									CollectCash()
								end
							end
						end)
					)
				end
			else
				warn("SLOT OCCUPATION DATA CORRUPTION")
			end
		end
		
		if not IsVipSlot then
			CollectPart.Color = Color3.fromRGB(0, 255, 0)
		end
	else
		-- Sale & Unoccupied
		if not isOccupied then
			if not IsVipSlot then
				CollectPart.Color = Color3.fromRGB(255, 0, 0)
			end

			ScreenGo.Color = Color3.fromRGB(255, 0, 0)

			FloatingCollectUI.Enabled = false
			GoButtonUI.Enabled = false

			NextMutationUI.DisplayScreen.PriceText.Text = "FOR SALE"
			NextMutationUI.DisplayScreen.PriceText.TextColor3 = Color3.fromRGB(255, 0, 0)
			NextMutationUI.TitleLabel.Text = "Unoccupied Slot"
		end
	end
end

function DataPlots.ClearPlot(plot: Model, clearCompletely: boolean?)
	if clearCompletely then
		-- Reset Base SurfaceUI Text
		CachedPlotsTextsUI[plot].Text = "Empty Plot"
	end
	
	-- Reset Floors
	for _, floor in ipairs(CachedPlotsFloors[plot]) do
		local floorNum = tonumber(string.match(floor.Name, "%d+"))
		if floorNum > 1 then
			floor.Parent = ServerStorage.Cache
		end
	end
	
	-- Reset Slots
	for _, floor in ipairs(CachedPlotsFloors[plot]) do
		local floorNum = tonumber(string.match(floor.Name, "%d+"))
		
		local Slots: Folder = floor:WaitForChild("Slots")
		local Placements: Folder = PlotUtil.getSlotsPlacements(Slots)
		if Placements then
			Placements:ClearAllChildren()
		end
		
		for _, slot in ipairs(Slots:GetChildren()) do
			DataPlots.SetSlotState(slot, true, false)
		end
	end
	
	local dropper: Folder? = PlotUtil.getPlotDropper(plot)
	if not dropper then return end
	local EggRollsScreen: BasePart?, EggRollsScreenUI: BillboardGui? = PlotUtil.getEggRollsScreen(dropper)

	local EggPillars: { Model } = PlotUtil.getEggPillars(dropper)
	local EggsRolls: Folder = dropper:FindFirstChild("EggRolls")

	EggsRolls:ClearAllChildren()
	
	PlotUtil.setEggsRollScreenUIState(plot, false)
	DataPlots.SetPlotSpinState(plot, "off")
	
	plot:SetAttribute("Initialized", false)
	plot:SetAttribute("OwnerUserId", nil)
end

function DataPlots.BeforePlayerLeave(player: Player, plot: Model, plotData: Types.PlotData)
	if not plotData or not plotData.Floors then
		return
	end

	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then return end

	for floorIndex, floorData in pairs(plotData.Floors) do
		local floorModel = plot:FindFirstChild("Floor" .. floorIndex)
		if not floorModel then
			for _, floor in ipairs(CachedPlotsFloors[plot]) do
				local floorNum = tonumber(string.match(floor.Name, "%d+"))
				if floorNum == floorIndex then
					floorModel = floor

					break
				end
			end

			if not floorModel then
				continue
			end
		end

		local slotsFolder = floorModel:FindFirstChild("Slots")
		if not slotsFolder then
			continue
		end

		for slotIndex, slotInfo in pairs(floorData.Slots) do
			local slot = slotsFolder:FindFirstChild(tostring(slotIndex))
			if not slot then
				continue
			end

			local labubuPlacement = slotInfo and slotInfo.Placement

			if labubuPlacement ~= nil then
				-- Has the slot

				local IsOccupiedLabubu = next(labubuPlacement) ~= nil -- IsOccupied with Labubu?
				local slotPlacement = IsOccupiedLabubu and labubuPlacement or nil -- nil if unoccupied

				if slotPlacement and slotPlacement.Type == "Labubu" then
					if not slotInfo.HasBeenHoldingOfflineCash and not slotPlacement.IsMutating then
						slotInfo.LastOfflineCashHolderLeaveSession = os.time()
						slotInfo.HasBeenHoldingOfflineCash = true
					end
				end
			end
		end
	end
end

function DataPlots.ApplyPlotData(plot: Model, plotData: Types.PlotData, player: Player?)
	if not plotData or not plotData.Floors then
		return
	end
	
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then return end

	for floorIndex, floorData in pairs(plotData.Floors) do
		local floorModel = plot:FindFirstChild("Floor" .. floorIndex)
		if not floorModel then
			for _, floor in ipairs(CachedPlotsFloors[plot]) do
				local floorNum = tonumber(string.match(floor.Name, "%d+"))
				if floorNum == floorIndex then
					floorModel = floor
					
					break
				end
			end
			
			if not floorModel then
				continue
			end
		end

		local slotsFolder = floorModel:FindFirstChild("Slots")
		if not slotsFolder then
			continue
		end
		
		-- Default Labubu
		if floorIndex == 1 then
			local firstSlot = slotsFolder:FindFirstChild("1")
			if firstSlot then
				if not profileData.HasBeenRewardedBeginnerLabubu then
					profileData.HasBeenRewardedBeginnerLabubu = true
					
					DataPlots.AddSlotToPlayerData(player, 1, 1)
					DataPlots.SetSlotState(firstSlot, false, false)
					
					local name = "Normal Labubu"

					local LabubuInfo = PlotUtil.getLabubuData(name)
					if not LabubuInfo then return end
					
					local rarity = LabubuInfo.Rarity -- Common to Basic

					local EggRng = RngUtil(
						PlotUtil.EggChancesRarity[rarity],
						DataPlots.GetExtraLuckMulti(player)
					)

					local labubuName, labubuData = name, LabubuInfo
					if not labubuName or not labubuData then return end

					local eggData = PlotUtil.EggsData[EggRng]
					if not eggData then return end

					local mutationTier = 1

					local currentTime = getUTCtime()

					local LabubuTemplate = PlotUtil.CreateLabubuTemplateFromEggData(
						labubuName, labubuData, {
							MutationTier = mutationTier,
							ObtainedFrom = "BeginnerReward",
						}, rarity, EggRng
					)
					
					profileData.PlotData.Floors[1].Slots[1].Placement = LabubuTemplate

					--DataPlots.SpawnHatchableAtSlot(firstSlot, LabubuTemplate, player)
					DataPlots.SetSlotState(firstSlot, false, true, 
						profileData.PlotData.Floors[1].Slots[1], player)
					DataIndex.AddLabubuToIndex(player, 
						LabubuTemplate)
				end
			end
		end

		local TotalOfflineCash = 0

		for slotIndex, slotInfo in pairs(floorData.Slots) do
			local slot = slotsFolder:FindFirstChild(tostring(slotIndex))
			if not slot then
				continue
			end
			
			slotInfo.Placement = slotInfo.Placement or {}
			slotInfo.Cash = slotInfo.Cash or 0
			slotInfo.OfflineCash = slotInfo.OfflineCash or 0
			
			local labubuPlacement = slotInfo and slotInfo.Placement

			if labubuPlacement ~= nil then
				-- Has the slot
				
				local IsOccupiedLabubu = next(labubuPlacement) ~= nil -- IsOccupied with Labubu?
				local slotPlacement = IsOccupiedLabubu and labubuPlacement or nil -- nil if unoccupied
				
				slot:SetAttribute("Occupied", IsOccupiedLabubu)
				slot:SetAttribute("ForSale", false)

				-- spawn labubu here
				-- DataPlots.SpawnLabubu(plot, floorIndex, slotIndex, labubu)
				
				if slotPlacement then
					if slotPlacement.Type == "Block" then
						DataPlots.SpawnEggAtSlot(slot, slotPlacement)
					elseif slotPlacement.Type == "Labubu" then
						slotPlacement.Traits = slotPlacement.Traits or {}
						
						DataPlots.SpawnHatchableAtSlot(slot, slotPlacement, player)
					end
				end
				
				if slotPlacement and slotPlacement.Type == "Labubu" then
					local LeftSession = profileData.LeftSessionAt
					local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(slotPlacement)
					
					if LeftSession and LeftSession > 0 and GetMutationExtraInfo then
						local secondsPassed = math.min(os.time() - LeftSession, 
							GlobalSettings.OfflineEarningDuration + profileData.OfflineEarningExtension
						)
						local CPS = GetMutationExtraInfo.CurrentMutationCPS * secondsPassed
						
						slotInfo.OfflineCash += CPS
					end
				end
				
				DataPlots.SetSlotState(slot, false, IsOccupiedLabubu, slotInfo, player)
			else
				DataPlots.SetSlotState(slot, true, false)
			end
			
			TotalOfflineCash += slotInfo.OfflineCash
		end
		
		if TotalOfflineCash > 0 then
			NotifyInfo:FireClient(player, 
				`Your Labubus have made ${formatCommaValue(TotalOfflineCash)} while offline!`, 8)
		end
	end
	
	local FloorCount: number = DataPlots.CountFloorsFromPlotData(plotData)
	if not FloorCount then
		return 
	end
	
	DataPlots.UpdateRollsInfo(plot, plotData.RollsInfo, true)
	
	DataPlots.ExpandPlotFloors(plot, FloorCount - 1)
	PlotUtil.setEggsRollScreenUIState(plot, true)
	
	DataPlots.SetPlotSpinState(plot, 
		plotData.SpinInfo.CanSpin and "on" or "off", plotData.SpinInfo.SpinCooldown)
	
	--plot:SetAttribute("Initialized", true)
end

function DataPlots.ConvertEggModelToRoll(egg: Model)
	local EggTool: Tool = PlotUtil.getEggTool(egg)
	if not EggTool then return end
	
	local EggToolClone: Tool = EggTool:Clone()
	copyAttributes(egg, EggToolClone)
	EggToolClone:SetAttribute("ParentIndex", nil)
	if not EggToolClone:GetAttribute("Id") then
		EggToolClone:SetAttribute("Id", generateGUID())
	end
	if not EggToolClone:GetAttribute("Name") then
		EggToolClone:SetAttribute("Name", EggTool.Name)
	end
	PlotUtil.setEggPriceInfoUI(EggToolClone, egg:GetAttribute("PriceOnly"))
	
	return EggToolClone
end

function DataPlots.ConvertEggToolToModel(EggTool: Model)
	local egg: Model = PlotUtil.getEggModel(EggTool)
	if not egg then return end
	
	local EggClone: Model = egg:Clone()
	copyAttributes(EggTool, EggClone)
	if not EggClone:GetAttribute("Id") then
		EggClone:SetAttribute("Id", generateGUID())
	end
	if not EggClone:GetAttribute("Name") then
		EggClone:SetAttribute("Name", EggTool.Name)
	end
	PlotUtil.setEggPriceInfoUI(EggClone, EggClone:GetAttribute("PriceOnly"), true)
	
	return EggClone
end

function DataPlots.RemoveEggFromPillar(player: Player, eggPillar: Model)
	local eggPillarIndex = eggPillar:GetAttribute("Index")
	if not eggPillarIndex then return end
	
	local dropper: Folder = eggPillar.Parent
	if not dropper then return end

	local EggsRolls: Folder = PlotUtil.getDropperEggsFolder(dropper)
	if not EggsRolls then return end
	
	if player then
		local profileData, clientData = DataHandler.getProfileData(player)
		if profileData then
			profileData.PlotData.RollsInfo.EggRolls[eggPillarIndex] = nil
		end
		
		if clientData then
			clientData.PlotData(deepCopy(profileData.PlotData))
		end
	end
	
	for _, egg in ipairs(EggsRolls:GetChildren()) do
		local ParentIndex = egg:GetAttribute("ParentIndex")
		if ParentIndex and ParentIndex == eggPillarIndex then
			egg:Destroy()
			
			return
		end
	end
end

function DataPlots.SpawnEggAtSlot(slot: Model, egg: Model | Tool | Types.Egg)
	local slots: Folder = slot.Parent
	if not slots then return end
	
	local slotsPlacement = PlotUtil.getSlotsPlacements(slots)
	if not slotsPlacement then return end
	
	local getSlotInfo = PlotUtil.getSlotData(slot)
	if not getSlotInfo then return end

	local getSlotPartsInfo = PlotUtil.getSlotWorldData(slot)
	if not getSlotPartsInfo then return end
	
	if getSlotInfo.IsForSale then return end
	
	local eggModel: Model? = nil :: Model
	
	-- If it's a model
	if typeof(egg) == 'Instance' then
		if egg:IsA("Model") then
			eggModel = egg:Clone()
		elseif egg:IsA("Tool") then
			local EggModel: Model = DataPlots.ConvertEggToolToModel(egg)
			if not EggModel then return end
			
			eggModel = EggModel
		end
	else
		eggModel = PlotUtil.getEggModel(egg.Name)
		if not eggModel then return end
		eggModel = eggModel:Clone()
		
		copyAttributesFromTable(egg, eggModel)
	end

	PlotUtil.setEggPriceInfoUI(eggModel, eggModel:GetAttribute("PriceOnly"), true)
	eggModel:SetAttribute("ParentIndex", getSlotInfo.SlotNum)
	
	local GetExtentsSize: Vector3 = eggModel:GetExtentsSize()
	local GetExtentsSizeY: number = GetExtentsSize.Y

	eggModel:PivotTo(
		getSlotInfo.MainStand.CFrame + 
			Vector3.new(0,
				GetExtentsSizeY / 2 + getSlotInfo.MainStand.Size.Y/2, 
			0)
	)

	PlotUtil.weldModelToPrimaryPart(eggModel)
	
	print("WHYYY")
	eggModel.Parent = slotsPlacement
end

function DataPlots.GiveTraitToLabubu(
	player: Player, labubu: Model, slot: Model, floorNum: number, slotNum: number,
	traitName: string
)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then return end

	if labubu:GetAttribute("Type") ~= "Labubu" then return end

	local labubuData: Types.Labubu? = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
	if not labubuData then return end

	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
	if not GetMutationExtraInfo then return end

	if labubuData.Traits[traitName] then return end

	labubuData.Traits[traitName] = true
	labubu:Destroy()

	DataPlots.SpawnHatchableAtSlot(slot, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement,
		player
	)

	DataPlots.SetSlotState(slot, false, true, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum], player)

	if clientData then
		clientData.PlotData(deepCopy(profileData.PlotData))
		
		NotifySuccess:FireClient(player, `{labubu.Name} got {traitName} trait!`)
	end
end

function DataPlots.TriggerWeatherPlotsTrait(trait: string, givenPlayer: Player?)
	for _, player in pairs(Players:GetPlayers()) do
		if givenPlayer then
			if player ~= givenPlayer then continue end
		end
		
		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData then continue end

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then continue end

		local Slot, FloorNum = PlotUtil.FindWorkingLabubuSlot(plot)
		if not Slot or not FloorNum then continue end

		local Slots = Slot.Parent
		local Placements = PlotUtil.getSlotsPlacements(Slots)

		local Placement = PlotUtil.getPlacementFromIndex(Placements, tonumber(Slot.Name))

		if Placement then
			DataPlots.GiveTraitToLabubu(player, Placement, Slot, FloorNum, tonumber(Slot.Name), 
				trait
			)
		end
	end
end

function DataPlots.DowngradeLabubuMutation(
	player: Player, labubu: Model, slot: Model, floorNum: number, slotNum: number
): number?
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then return end

	if labubu:GetAttribute("Type") ~= "Labubu" then return end

	local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
	if not labubuData then return end

	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
	if not GetMutationExtraInfo then return end

	local prevMutationTier = GetMutationExtraInfo.PrevMutationTier
	if not prevMutationTier then return end

	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating = false

	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.CPS = 
		GetMutationExtraInfo.FailureMutationCPS

	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.MutationTier = prevMutationTier

	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.MutationTime = 
		GetMutationExtraInfo.PrevMutationTime

	labubu:Destroy()

	DataPlots.SpawnHatchableAtSlot(slot, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement,
		player
	)

	DataPlots.SetSlotState(slot, false, true, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum], player)

	DataIndex.AddLabubuToIndex(player, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement)

	if clientData then
		clientData.PlotData(deepCopy(profileData.PlotData))
	end

	return prevMutationTier
end

function DataPlots.MutateLabubu(
	player: Player, labubu: Model, slot: Model, floorNum: number, slotNum: number, wasFailedMutation: boolean?
)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then return end
	
	if labubu:GetAttribute("Type") ~= "Labubu" then return end
	
	local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
	if not labubuData then return end
	
	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
	if not GetMutationExtraInfo then return end
	
	local nextMutationTier = GetMutationExtraInfo.NextMutationTier
	if not nextMutationTier then return end
	
	-- why is it repeated so many times. use a variable!
	-- e.g. local placementData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement 
	-- thanks!
	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating = false
	
	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.CPS = 
		GetMutationExtraInfo.NextMutationCPS

	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.MutationTier = nextMutationTier

	profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.MutationTime = 
		GetMutationExtraInfo.NextMutationTime
	
	profileData.Mutations += 1

	labubu:Destroy()

	DataPlots.SpawnHatchableAtSlot(slot, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement,
		player
	)

	DataPlots.SetSlotState(slot, false, true, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum], player)
	
	local _, isInIndex = DataIndex.AddLabubuToIndex(player, 
		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement)
	
	if clientData then
		if wasFailedMutation then
			Network.Plots.KeepLostMutationSuccess:FireClient(player, labubuData.Id)
		else
			local isNewMutation = not isInIndex
			Network.Overlay.MutationReveal:FireClient(player, labubuData.Name, nextMutationTier, isNewMutation)
		end

		clientData.PlotData(deepCopy(profileData.PlotData))
		clientData.Mutations(profileData.Mutations)
	end
end

function DataPlots.HandleStealing(player: Player, isHighTier: boolean)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then return end

	local PlayerPlot = DataPlots.GetPlayerPlot(player)
	if not PlayerPlot then return end

	local base = PlayerAttributes.getAttribute(player, "TargetStealBase")
	local expectedOwnerUserId = PlayerAttributes.getAttribute(player, "TargetStealExpectedOwnerUserId")
	local placementName = PlayerAttributes.getAttribute(player, "TargetStealPlacementName")
	local floorNum = PlayerAttributes.getAttribute(player, "TargetStealFloorNum")
	local slotNum = PlayerAttributes.getAttribute(player, "TargetStealSlotNum")
	local Info = PlayerAttributes.getAttribute(player, "TargetStealPlacementInfo")

	if not base or not expectedOwnerUserId or not placementName or 
		not floorNum or not slotNum or not Info then return end
	
	if Info.CurrentMutationTier > GlobalSettings.HighTierMutationsAreOver then
		if not isHighTier then return end
	end

	if base.Parent ~= Bases then return end

	local TargetBaseOwnerUserId = base:GetAttribute("OwnerUserId")
	if TargetBaseOwnerUserId ~= expectedOwnerUserId then return end

	local TargetBaseOwner = Players:GetPlayerByUserId(TargetBaseOwnerUserId)
	if not TargetBaseOwner then return end

	if TargetBaseOwner == player then return end

	local floor = PlotUtil.getFloor(base, floorNum)
	if not floor then return end

	local Slots: Folder = floor:FindFirstChild("Slots")
	if not Slots then return end

	local Slot: Model = Slots:FindFirstChild(slotNum)
	if not Slot then return end

	local Placements: Folder = PlotUtil.getSlotsPlacements(Slots)
	if not Placements then return end

	local Placement: Model = Placements:FindFirstChild(placementName)
	if not Placement then return end

	if Placement:GetAttribute("Type") ~= "Labubu" then return end
	if Placement:GetAttribute("IsMutating") then return end
	if Slot:GetAttribute("IsMutating") then return end
	if Slot:GetAttribute("ReadyToMutate") then return end
	if Placement:GetAttribute("IsBeingStolen") then return end
	if not Placement:GetAttribute("IsStealable") then return end

	local TargetProfileData, TargetClientData = DataHandler.getProfileData(TargetBaseOwner)
	if not TargetProfileData or not TargetClientData then return end

	local character = player.Character
	if not character then return end

	local Humanoid: Humanoid = character:FindFirstChild("Humanoid")
	if not Humanoid then return end

	if not TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum].Placement then return end
	if not TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsStealable then
		return
	end
	
	local FindEmptySlotAvailable = PlotUtil.FindEmptySlotAvailable(PlayerPlot)
	if not FindEmptySlotAvailable then
		NotifyError:FireClient(player, "Can't steal, no empty slot available in your plot!", 8)

		return
	end
	
	--if TargetProfileData.Gamepasses["Magic Shield (Perm)"] then
	--	NotifyError:FireClient(player, "Can't steal, target has Magic Shield!", 8)
	--	return
	--end

	local LabubuToolClone
	local OriginalAttributes
	
	local LabubuTool: Tool = PlotUtil.getHatchableTool(Placement.Name)
	if not LabubuTool then return end

	local PlacementAttributes = Placement:GetAttributes()
	OriginalAttributes = deepCopy(PlacementAttributes)

	LabubuToolClone = LabubuTool:Clone()
	copyAttributesFromTable(PlacementAttributes, LabubuToolClone)

	DataBackpack.Labubus.addToBackpackByInstance(player, LabubuToolClone, true)

	DataPlots.SetSlotState(Slot, false, false)
	TargetClientData.PlotData(deepCopy(TargetProfileData.PlotData))
	
	NotifyInfo:FireClient(player, "You stole a Labubu!")
	NotifyWarn:FireClient(TargetBaseOwner, "Your Labubu has been cloned!")

	--[[
	local function BringBackToRightOwner()
		if LabubuToolClone then
			if LabubuToolClone.Parent then
				LabubuToolClone:Destroy()
			end

			if OriginalAttributes then
				if TargetBaseOwner:IsDescendantOf(Players) then
					TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum].Placement = 
						OriginalAttributes

					DataPlots.SpawnHatchableAtSlot(Slot, OriginalAttributes, TargetBaseOwner)
					DataPlots.SetSlotState(Slot, false, true, 
						TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum], TargetBaseOwner)

					TargetClientData.PlotData(deepCopy(TargetProfileData.PlotData))
				end
			end
		end
	end

	local LabubuTool: Tool = PlotUtil.getHatchableTool(Placement.Name)
	if not LabubuTool then return end

	local PlacementAttributes = Placement:GetAttributes()
	OriginalAttributes = deepCopy(PlacementAttributes)

	character:SetAttribute("IsStealing", true)
	PlacementAttributes.IsBeingStolen = true
	PlacementAttributes.FloorNum = floorNum
	PlacementAttributes.OwnerUserId = TargetBaseOwnerUserId
	PlacementAttributes.Placeable = true

	Placement:Destroy()

	TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum].Placement = {}

	LabubuToolClone = LabubuTool:Clone()
	copyAttributesFromTable(PlacementAttributes, LabubuToolClone)

	local playerTrove = Trove.new()
	local characterRemoving = playerTrove:AttachToInstance(character, function()
		BringBackToRightOwner()
	end)

	playerTrove:Add(
		Humanoid.Died:Connect(function()
			if playerTrove then
				BringBackToRightOwner()
				playerTrove:Destroy()
			end
		end)
	)

	PlotUtil.addMutationEffect(LabubuToolClone, PlacementAttributes.MutationTier)
	LabubuToolClone.Parent = character

	playerTrove:Add(
		LabubuToolClone:GetPropertyChangedSignal("Parent"):Connect(function()
			if playerTrove then
				playerTrove:Destroy()
			end
		end)
	)

	DataPlots.SetSlotState(Slot, false, false)
	TargetClientData.PlotData(deepCopy(TargetProfileData.PlotData))

	NotifyInfo:FireClient(player, "You're stealing Labubu!")
	NotifyWarn:FireClient(TargetBaseOwner, "Your Labubu has been stolen!")
	--]]
end

function DataPlots.GetExtraLuckMulti(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return 1
	end
	
	local multi = profileData.EggLuck
	
	if profileData.Gamepasses["VIP Status"] then
		multi += 0.5
	end
	
	if profileData.Gamepasses["Lucky Clover"] or player:GetAttribute("x2Luck") then
		multi += 1
	end
	
	local ServerLuckMulti = workspace:GetAttribute("ServerLuckMulti")
	if ServerLuckMulti then
		multi += ServerLuckMulti - 1
	end
	
	return multi
end

function DataPlots.GiveLabubu(
	player: Player, name: string?, mutationTier: number?, obtainedFrom: string?)

	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end

	local plot = DataPlots.GetPlayerPlot(player)
	if not plot then
		return
	end
	
	local LabubuInfo = PlotUtil.getLabubuData(name)
	if not LabubuInfo then return end
	
	local rarity = LabubuInfo.Rarity -- Common to Basic

	local EggRng = RngUtil(
		PlotUtil.EggChancesRarity[rarity],
		DataPlots.GetExtraLuckMulti(player)
	)

	if not EggRng then
		if rarity == "Exclusive" then
			EggRng = "Exclusive Block"
		end
	end

	local labubuName, labubuData = name, LabubuInfo
	if not labubuName or not labubuData then return end

	local eggData = PlotUtil.EggsData[EggRng]
	if not eggData then return end

	local mutationTier = mutationTier or 1

	local currentTime = getUTCtime()

	local LabubuTemplate = PlotUtil.CreateLabubuTemplateFromEggData(
		labubuName, labubuData, {
			MutationTier = mutationTier,
			ObtainedFrom = obtainedFrom or "Unknown",
		}, rarity, EggRng
	)

	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(LabubuTemplate)
	if not GetMutationExtraInfo then return end

	local LabubuTool: Tool = PlotUtil.getHatchableTool(labubuName)
	if not LabubuTool then return end

	local LabubuToolClone = LabubuTool:Clone()
	copyAttributesFromTable(LabubuTemplate, LabubuToolClone)

	for _, fx in pairs(LabubuToolClone:GetDescendants()) do
		if fx:HasTag("FX") then
			fx:Destroy()
		end
	end

	PlotUtil.setHatchableInfoUI(LabubuToolClone, GetMutationExtraInfo.CurrentMutationName,
		LabubuTemplate.IsMutating, LabubuTemplate
	)

	DataIndex.AddLabubuToIndex(player, LabubuTemplate)
	DataBackpack.Labubus.addToBackpackByInstance(player, LabubuToolClone, true)
end

function DataPlots.GiveLabubuByRarity(
	player: Player, rarity: string?, mutationTier: number?, obtainedFrom: string?)
	-- Common to Basic: rarity now uses "Common" directly
	
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end
	
	local plot = DataPlots.GetPlayerPlot(player)
	if not plot then
		return
	end
	
	local EggRng = RngUtil(
		PlotUtil.EggChancesRarity[rarity],
		DataPlots.GetExtraLuckMulti(player), nil, true
	)
	
	local labubuName, labubuData = PlotUtil.TranslateEggToHatchable(EggRng)
	if not labubuName or not labubuData then return end

	local eggData = PlotUtil.EggsData[EggRng]
	if not eggData then return end

	local mutationTier = mutationTier or 1

	local currentTime = getUTCtime()

	local LabubuTemplate = PlotUtil.CreateLabubuTemplateFromEggData(
		labubuName, labubuData, {
			MutationTier = mutationTier,
			ObtainedFrom = obtainedFrom or "Unknown",
		}, rarity, EggRng
	)
	
	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(LabubuTemplate)
	if not GetMutationExtraInfo then return end
	
	local LabubuTool: Tool = PlotUtil.getHatchableTool(labubuName)
	if not LabubuTool then return end

	local LabubuToolClone = LabubuTool:Clone()
	copyAttributesFromTable(LabubuTemplate, LabubuToolClone)

	for _, fx in pairs(LabubuToolClone:GetDescendants()) do
		if fx:HasTag("FX") then
			fx:Destroy()
		end
	end

	PlotUtil.setHatchableInfoUI(LabubuToolClone, GetMutationExtraInfo.CurrentMutationName,
		LabubuTemplate.IsMutating, LabubuTemplate
	)

	DataIndex.AddLabubuToIndex(player, LabubuTemplate)
	DataBackpack.Labubus.addToBackpackByInstance(player, LabubuToolClone, true)
end

function DataPlots.GiveEgg(player: Player, name: string, obtainedFrom: string?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end

	local plot = DataPlots.GetPlayerPlot(player)
	if not plot then
		return
	end

	local rng = name
	local egg = PlotUtil.spawnEggRoll(rng, nil, true, obtainedFrom or "Unknown")

	local EggData = PlotUtil.EggsData[egg.Name]
	local EggCost, EggSellerCost = PlotUtil.CalculateCost({
		Name = egg.Name,
		EggMutationTier = egg:GetAttribute("EggMutationTier") or 1,
		Type = "Block"
	})

	local EggToolClone: Tool? = DataPlots.ConvertEggModelToRoll(egg)
	DataBackpack.Eggs.addBackpackEggByInstance(player, EggToolClone, true)
	
	profileData.EggsReceived += 1
	clientData.EggsReceived(profileData.EggsReceived)
end

function DataPlots.GiveEggBasedOffRarity(player: Player, rarity: string, obtainedFrom: string?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end

	local plot = DataPlots.GetPlayerPlot(player)
	if not plot then
		return
	end

	if not PlotUtil.EggChancesRarity[rarity] then return end

	local rng = RngUtil(
		PlotUtil.EggChancesRarity[rarity],
		DataPlots.GetExtraLuckMulti(player), nil, true
	)

	if not rng then return end

	local egg = PlotUtil.spawnEggRoll(rng, nil, true, obtainedFrom or "Unknown")

	local EggData = PlotUtil.EggsData[egg.Name]
	local EggCost, EggSellerCost = PlotUtil.CalculateCost({
		Name = egg.Name,
		EggMutationTier = egg:GetAttribute("EggMutationTier") or 1,
		Type = "Block"
	})

	local EggToolClone: Tool? = DataPlots.ConvertEggModelToRoll(egg)
	DataBackpack.Eggs.addBackpackEggByInstance(player, EggToolClone, true)
	
	profileData.EggsReceived += 1
	clientData.EggsReceived(profileData.EggsReceived)
end

function DataPlots.GiveExclusiveEgg(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end
	
	local plot = DataPlots.GetPlayerPlot(player)
	if not plot then
		return
	end
	
	if not PlotUtil.EggChancesRarity["Exclusive"] then return end
	
	local rng = RngUtil(
		PlotUtil.EggChancesRarity["Exclusive"],
		DataPlots.GetExtraLuckMulti(player), nil, true
	)
	
	if not rng then return end
	
	local egg = PlotUtil.spawnEggRoll(rng, nil, true, "Exclusive")
	
	local EggData = PlotUtil.EggsData[egg.Name]
	local EggCost, EggSellerCost = PlotUtil.CalculateCost({
		Name = egg.Name,
		EggMutationTier = egg:GetAttribute("EggMutationTier") or 1,
		Type = "Block"
	})

	local EggToolClone: Tool? = DataPlots.ConvertEggModelToRoll(egg)
	DataBackpack.Eggs.addBackpackEggByInstance(player, EggToolClone, true)
	
	profileData.EggsReceived += 1
	clientData.EggsReceived(profileData.EggsReceived)
end

function DataPlots.KeepLostMutation(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData or not clientData then
		return
	end
	
	local plot = DataPlots.GetPlayerPlot(player)
	if not plot then
		return
	end
	
	local Info = PlayerAttributes.getAttribute(player, "LastMutationFailForProduct")
	if not Info then return end

	local Id, slotNum, floorNum = Info.Id, Info.SlotNum, Info.FloorNum

	if not Id or not slotNum or not floorNum then return end
	
	local floor = PlotUtil.getFloor(plot, floorNum)
	if not floor then return end

	local Slots = floor:FindFirstChild("Slots")
	if not Slots then return end
	
	local slot = Slots:FindFirstChild(slotNum)
	if not slot then return end

	local Placements = PlotUtil.getSlotsPlacements(Slots)
	if not Placements then return end

	local Placement = PlotUtil.getPlacementFromId(Placements, Id)
	if not Placement then return end

	if Placement:GetAttribute("Type") ~= "Labubu" then return end

	local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
	if not labubuData then return end

	local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
	if not GetMutationExtraInfo then return end

	if not GetMutationExtraInfo.NextMutationTier then return end
	if profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating then return end
	
	DataPlots.MutateLabubu(player, Placement, slot, floorNum, slotNum, true)
end

function DataPlots.InitAllPlots()
	if PlotsInitialized then return end
	
	for _, plot in ipairs(DataPlots.GetAllPlots()) do
		DataPlots.ClearPlot(plot, true)
	end
	
	-- Tutorial
	Network.Tutorial.Progress.OnServerEvent:Connect(function(player: Player, tutorialStep: number,
		isComplete: boolean?
	)
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local profileData, clientData = DataHandler.getProfileData(player)
		if profileData == nil or clientData == nil then return end
		
		if typeof(tutorialStep) ~= 'number' then return end
		
		profileData.TutorialStep = tutorialStep
		if isComplete == true then
			profileData.HasCompletedTutorial = true
			clientData.HasCompletedTutorial(profileData.HasCompletedTutorial)
		end
		
		clientData.TutorialStep(profileData.TutorialStep)
	end)
	
	-- Mutate Fail
	
	Network.Plots.ClientMutateFail.OnServerEvent:Connect(function(player: Player, expectedId: string?)
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local profileData, clientData = DataHandler.getProfileData(player)
		if profileData == nil or clientData == nil then return end

		local plot = DataPlots.GetPlayerPlot(player)
		if plot == nil then return end
		
		local Info = PlayerAttributes.getAttribute(player, "LastMutationFail")
		if not Info then return end
		
		local Id, slotNum, floorNum = Info.Id, Info.SlotNum, Info.FloorNum
		
		if not Id or not slotNum or not floorNum then return end
		if Id ~= expectedId then return end
		
		local floor = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end
		
		local Slots = floor:FindFirstChild("Slots")
		if not Slots then return end
		
		local slot = Slots:FindFirstChild(slotNum)
		if not slot then return end
		
		local Placements = PlotUtil.getSlotsPlacements(Slots)
		if not Placements then return end
		
		local Placement = PlotUtil.getPlacementFromId(Placements, Id)
		if not Placement then return end
		
		if Placement:GetAttribute("Type") ~= "Labubu" then return end
		
		local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
		if not labubuData then return end

		local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
		if not GetMutationExtraInfo then return end

		if not GetMutationExtraInfo.NextMutationTier then return end
		if profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating then return end
		
		local Id = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.Id
		PlayerAttributes.setAttribute(player, 
			"LastMutationFailForProduct",
			{
				Id = Id,
				SlotNum = slotNum,
				FloorNum = floorNum
			}
		)
		
		Network.Purchases.promptProduct:FireClient(player, Products["Keep Lost Mutation"], true)
	end)
	
	-- Daily Rewards
	
	Network.DailyRewards.Claim.OnServerEvent:Connect(function(player: Player)
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local profileData, clientData = DataHandler.getProfileData(player)
		if profileData == nil or clientData == nil then return end

		local plot = DataPlots.GetPlayerPlot(player)
		if plot == nil then return end

		if profileData.LastDailyRewardTime == 0 then return end

		local egg = RngUtil(PlotUtil.EggChancesRarity, DataPlots.GetExtraLuckMulti(player))
		local eggData = egg and PlotUtil.EggsData[egg]

		if eggData == nil then return end

		local timeBeen = os.time() - profileData.LastDailyRewardTime
		if timeBeen < 24 * 60 * 60 then 
			local nextRewardTime = profileData.LastDailyRewardTime + 24 * 60 * 60
			NotifyError:FireClient(player, `Try again in {TimeFormat.formatDuration(nextRewardTime - os.time())}`)
			return
		end

		profileData.LastDailyRewardTime = os.time()

		DataPlots.GiveEggBasedOffRarity(player, eggData.Rarity, "DailyReward")

		local EggText = richColor(RarityTextColors[eggData.Rarity], eggData.Rarity)
		NotifySuccess:FireClient(player, `You got a {EggText} egg from Daily Rewards!`)

		clientData.LastDailyRewardTime(profileData.LastDailyRewardTime)
	end)
	
	
	
	-- Stealing
	
	Network.Plots.StealLabubu.OnServerEvent:Connect(function(
		player: Player, base: Folder, expectedOwnerUserId: number, placementName: string,
		floorNum: number, slotNum: number
	)
		
		if typeof(base) ~= "Instance" then return end
		if typeof(expectedOwnerUserId) ~= 'number' then return end
		if typeof(placementName) ~= 'string' then return end
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then return end

		local PlayerPlot = DataPlots.GetPlayerPlot(player)
		if not PlayerPlot then return end
		
		if base.Parent ~= Bases then return end
		
		local TargetBaseOwnerUserId = base:GetAttribute("OwnerUserId")
		if TargetBaseOwnerUserId ~= expectedOwnerUserId then return end
		
		local TargetBaseOwner = Players:GetPlayerByUserId(TargetBaseOwnerUserId)
		if not TargetBaseOwner then return end
		
		if TargetBaseOwner == player then return end
		
		local floor = PlotUtil.getFloor(base, floorNum)
		if not floor then return end
		
		local Slots: Folder = floor:FindFirstChild("Slots")
		if not Slots then return end
		
		local Slot: Model = Slots:FindFirstChild(slotNum)
		if not Slot then return end
		
		local Placements: Folder = PlotUtil.getSlotsPlacements(Slots)
		if not Placements then return end
		
		local Placement: Model = Placements:FindFirstChild(placementName)
		if not Placement then return end
		
		if Placement:GetAttribute("Type") ~= "Labubu" then return end
		if Placement:GetAttribute("IsMutating") then return end
		if Slot:GetAttribute("IsMutating") then return end
		if Slot:GetAttribute("ReadyToMutate") then return end
		if Placement:GetAttribute("IsBeingStolen") then return end
		if not Placement:GetAttribute("IsStealable") then return end
		
		local TargetProfileData, TargetClientData = DataHandler.getProfileData(TargetBaseOwner)
		if not TargetProfileData or not TargetClientData then return end
		
		local character = player.Character
		if not character then return end
		
		local Humanoid: Humanoid = character:FindFirstChild("Humanoid")
		if not Humanoid then return end
		
		if not TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum].Placement then return end
		if not TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsStealable then
			return
		end
		
		local Info = PlotUtil.GetMutationExtraInfo(
			TargetProfileData.PlotData.Floors[floorNum].Slots[slotNum].Placement)
		if not Info then return end
		
		local FindEmptySlotAvailable = PlotUtil.FindEmptySlotAvailable(PlayerPlot)
		if not FindEmptySlotAvailable then
			NotifyError:FireClient(player, "Can't steal, no empty slot available in your plot!", 8)
			
			return
		end
		
		PlayerAttributes.setAttribute(player, "TargetStealBase", base)
		PlayerAttributes.setAttribute(player, "TargetStealExpectedOwnerUserId", expectedOwnerUserId)
		PlayerAttributes.setAttribute(player, "TargetStealPlacementName", placementName)
		PlayerAttributes.setAttribute(player, "TargetStealFloorNum", floorNum)
		PlayerAttributes.setAttribute(player, "TargetStealSlotNum", slotNum)
		PlayerAttributes.setAttribute(player, "TargetStealPlacementInfo", Info)
		
		if Info.CurrentMutationTier > GlobalSettings.HighTierMutationsAreOver then
			local Product = Products["Steal High-Tier Labubu"]
			Network.Purchases.promptProduct:FireClient(player, Product, true)
		else
			local Product = Products["Steal Labubu"]
			Network.Purchases.promptProduct:FireClient(player, Product, true)
		end
	end)
	
	-- Rebirth
	
	Network.Plots.Rebirth.OnServerEvent:Connect(function(
		player: Player, expectedNextRebirthLevel: number)
		if typeof(expectedNextRebirthLevel) ~= "number" then return end
		
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)
		
		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then return end
		
		local Plot = DataPlots.GetPlayerPlot(player)
		if not Plot then return end
		
		local CurrentRebirthLevel = profileData.Rebirths
		local NextRebirthLevel = CurrentRebirthLevel + 1
		
		if NextRebirthLevel ~= expectedNextRebirthLevel then return end
		
		local RebirthData = RebirthModule[NextRebirthLevel]
		if not RebirthData then return end
		
		local Placements = PlotUtil.GetAllPlacements(Plot)
		if not Placements then return end
		
		if RebirthData.Requirements.Hatchables then
			for _, hatchable in RebirthData.Requirements.Hatchables do
				local RequiredAmount = hatchable.RequiredAmount or 1
				local Rarity = hatchable.Rarity
				local Mutation = hatchable.Mutation
				
				local RarityColor = Rarity and RarityTextColors[Rarity]
				local MutationColor = Mutation and MutationTextColors[Mutation]
				
				local FilteredPlacements, Count = 
					PlotUtil.LabubuPlacementFilterBy(Placements, Rarity, Mutation)
				
				if Count < RequiredAmount then
					local RarityText = RarityColor and 
						" " .. richColor(RarityColor, Rarity) or ""
					local MutationText = MutationColor and 
						" " .. richColor(MutationColor, Mutation) or ""
					
					NotifyError:FireClient(player, 
						`You need to have {RequiredAmount}x of{RarityText}{MutationText} Labubus!`)
					
					return
				end
			end
		end
		
		
		if RebirthData.Requirements.Cash and RebirthData.Requirements.Cash > 0 then
			if DataCash.getCash(player) < RebirthData.Requirements.Cash then
				NotifyError:FireClient(player, "You need more cash for Rebirth!")
				
				return
			end
			DataCash.reduceCash(player, RebirthData.Requirements.Cash)
		end
		
		
		local UnlockedNewSlots = 0
		
		for floorNum = 1, 3 do
			local floor = Plot:FindFirstChild("Floor" .. floorNum)
			if not floor then continue end
			
			local Slots: Folder = floor:FindFirstChild("Slots")
			if not Slots then continue end

			for i = 1, 10 do
				local Slot = Slots:FindFirstChild(i)
				if not Slot then continue end
				
				local Button = Slot:FindFirstChild("Button")
				if not Button then continue end
				
				local IsForSale = profileData.PlotData.Floors[floorNum].Slots[i] == nil
				if not IsForSale then
					--profileData.PlotData.Floors[floorNum].Slots[i].Placement = {}
				end
				
				if IsForSale and 
					(RebirthData.Rewards.Slots and UnlockedNewSlots < RebirthData.Rewards.Slots) then
					DataPlots.AddSlotToPlayerData(player, floorNum, i)
					DataPlots.SetSlotState(Slot, false, false)
					
					UnlockedNewSlots += 1
				else
					--DataPlots.SetSlotState(Slot, IsForSale, 
					--	profileData.PlotData.Floors[floorNum].Slots[i].Placement and
					--		profileData.PlotData.Floors[floorNum].Slots[i].Placement ~= nil
					--)

				end
				
			end
		end
		
		if RebirthData.Rewards.EggLuck then
			profileData.EggLuck += RebirthData.Rewards.EggLuck
		end
		
		if RebirthData.Rewards.CashMulti then
			profileData.CashMulti += RebirthData.Rewards.CashMulti
		end
		
		if RebirthData.Rewards.OfflineEarningExtension then
			profileData.OfflineEarningExtension += RebirthData.Rewards.OfflineEarningExtension
		end
		
		if RebirthData.Rewards.UnlockFloorNum then
			local floor = Plot:FindFirstChild("Floor" .. RebirthData.Rewards.UnlockFloorNum)
			
			if not floor then
				DataPlots.ExpandPlotFloors(Plot, 1)
				DataPlots.AddFloorToPlayerData(player, RebirthData.Rewards.UnlockFloorNum)
			end
		end
		
		--DataBackpack.Eggs.ResetAll(player)
		--DataBackpack.Labubus.ResetAll(player)
		
		--Placements:ClearAllChildren()
		
		profileData.Rebirths += 1
		clientData.Rebirths(profileData.Rebirths)
		
		NotifySuccess:FireClient(player, 
			`You've Rebirthed to level {NextRebirthLevel}!`, 8)
	end)
	
	-- Seller Network
	
	Network.Seller.SellLabubus.OnServerInvoke = function(player: Player)
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local character = player.Character
		if not character then return end

		local Plot = DataPlots.GetPlayerPlot(player)
		if not Plot then return end
		
		local TotalPrice = 0
		local ItemsCount = 0
		
		for _, instance: Instance? in pairs(getPlayerFullBackpack(player)) do
			if not instance:IsA("Tool") then continue end
			
			local Tool: Tool = instance

			local Type = Tool:GetAttribute("Type")
			if not Type then continue end

			if Type ~= "Labubu" then continue end
			if Tool:GetAttribute("IsBeingStolen") then continue end
			local Id = Tool:GetAttribute("Id")
			if not Id then continue end

			local Data = Tool:GetAttributes()
			if not Data then continue end
			local Cost, SellerPrice = PlotUtil.CalculateCost(Data)
			if not Cost then continue end

			local Rarity, RarityColor = PlotUtil.GetRarity(Data)
			if not Rarity or not RarityColor then continue end

			TotalPrice += SellerPrice
			ItemsCount += 1
		end
		
		if TotalPrice > 0 then
			DataBackpack.Labubus.ResetAll(player)
			DataCash.giveCash(player, TotalPrice)
			NotifySuccess:FireClient(player, 
				`You sold {ItemsCount} Labubus for ${formatCommaValue(TotalPrice)}`, 8)
		else
			NotifyError:FireClient(player, "No Labubus in your Backpack to Sell")
			return
		end
		
		return true
	end
	
	Network.Seller.SellEggs.OnServerInvoke = function(player: Player)
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local character = player.Character
		if not character then return end

		local Plot = DataPlots.GetPlayerPlot(player)
		if not Plot then return end

		local TotalPrice = 0
		local ItemsCount = 0

		for _, instance: Instance? in pairs(getPlayerFullBackpack(player)) do
			if not instance:IsA("Tool") then continue end

			local Tool: Tool = instance

			local Type = Tool:GetAttribute("Type")
			if not Type then continue end

			if Type ~= "Block" then continue end
			if Tool:GetAttribute("IsBeingStolen") then continue end
			local Id = Tool:GetAttribute("Id")
			if not Id then continue end

			local Data = Tool:GetAttributes()
			if not Data then continue end
			local Cost, SellerPrice = PlotUtil.CalculateCost(Data)
			if not Cost then continue end

			local Rarity, RarityColor = PlotUtil.GetRarity(Data)
			if not Rarity or not RarityColor then continue end

			TotalPrice += SellerPrice
			ItemsCount += 1
		end

		if TotalPrice > 0 then
			DataBackpack.Eggs.ResetAll(player)
			DataCash.giveCash(player, TotalPrice)
			NotifySuccess:FireClient(player, 
				`You sold {ItemsCount} Eggs for ${formatCommaValue(TotalPrice)}`, 8)
		else
			NotifyError:FireClient(player, "No Eggs in your Backpack to Sell")
			return
		end

		return true
	end
	
	Network.Seller.SellHandItem.OnServerInvoke = function(player: Player, item: string)
		if typeof(item) ~= "string" then return end
		
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)
		
		local character = player.Character
		if not character then return end
		
		local Plot = DataPlots.GetPlayerPlot(player)
		if not Plot then return end
		
		local Tool: Tool = character:FindFirstChild(item)
		if not Tool then
			NotifyError:FireClient(player, "You don't have anything in your hand!")

			return 
		end
		
		local IsATool = Tool and Tool:IsA("Tool")
		local Type = Tool and Tool:GetAttribute("Type")
		
		if not Type or (Type ~= "Block" and Type ~= "Labubu") then 
			NotifyError:FireClient(player, "You can't sell this item!")
			
			return 
		end
		
		local Id = Tool:GetAttribute("Id")
		if not Id then return end
		
		if Tool:GetAttribute("IsBeingStolen") then return end
		
		local Data = Tool:GetAttributes()
		if not Data then return end

		local Cost, SellerPrice = PlotUtil.CalculateCost(Data)
		if not Cost then return end

		local Rarity, RarityColor = PlotUtil.GetRarity(Data)
		if not Rarity or not RarityColor then return end

		if Type == "Block" then
			DataBackpack.Eggs.removeBackpackEggByID(player, Id)
		elseif Type == "Labubu" then
			DataBackpack.Labubus.removeById(player, Id)
		end
		
		DataCash.giveCash(player, SellerPrice)
		NotifySuccess:FireClient(player, 
			`You sold {richColor(RarityColor, item)} for ${formatCommaValue(SellerPrice)}`, 8)

		return true
	end
	
	Network.Seller.CheckValue.OnServerInvoke = function(player: Player, item: string)
		if typeof(item) ~= "string" then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local character = player.Character
		if not character then return end

		local Plot = DataPlots.GetPlayerPlot(player)
		if not Plot then return end

		local Tool: Tool = character:FindFirstChild(item)
		if not Tool then
			NotifyError:FireClient(player, "You don't have anything in your hand!")

			return 
		end

		local IsATool = Tool and Tool:IsA("Tool")
		local Type = Tool and Tool:GetAttribute("Type")

		if not Type or (Type ~= "Block" and Type ~= "Labubu") then 
			NotifyError:FireClient(player, "Invalid Item!")

			return 
		end
		
		if Tool:GetAttribute("IsBeingStolen") then return end
		
		local Id = Tool:GetAttribute("Id")
		if not Id then return end
		
		local Data = Tool:GetAttributes()
		if not Data then return end
		
		local Cost, SellerPrice = PlotUtil.CalculateCost(Data)
		if not Cost then return end
		
		local Rarity, RarityColor = PlotUtil.GetRarity(Data)
		if not Rarity or not RarityColor then return end
		
		NotifyInfo:FireClient(player, 
			`{richColor(RarityColor, item)} is worth ${formatCommaValue(SellerPrice)}!`, 8)
		
		return true
	end
	
	-- Plot Network
	
	-- Buy Slot
	Network.Plots.BuySlot.OnServerEvent:Connect(function(player: Player,
		floorNum: number, slotNum: number)
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)
		
		local Plot: Model? = DataPlots.GetPlayerPlot(player)
		if not Plot then return end
		
		local floor = Plot:FindFirstChild("Floor" .. floorNum)
		if not floor then return end
		
		local Slots = floor:FindFirstChild("Slots")
		if not Slots then return end
		
		local slot = Slots:FindFirstChild(tostring(slotNum))
		if not slot then return end
		
		local IsOccupied = slot:GetAttribute("Occupied")
		if IsOccupied then return end
		
		local IsForSale = slot:GetAttribute("ForSale")
		if not IsForSale then return end
		
		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then return end
		
		local Price = slot:GetAttribute("Price")
		local IsVipSlot = slot:GetAttribute("VipSlot")
		
		if IsVipSlot then
			PlayerAttributes.setAttribute(player, "TargetVIPSlot", slotNum)
			PlayerAttributes.setAttribute(player, "TargetVIPSlotFloor", floorNum)
			Network.Purchases.promptProduct:FireClient(player, Products["BuyVIPSlot"], true)
		else
			if not Price then return end
			
			local Cash = DataCash.getCash(player)
			if not Cash then return end
			
			if Cash >= Price then
				DataCash.reduceCash(player, Price)

				DataPlots.SetSlotState(slot, false, false)
				DataPlots.AddSlotToPlayerData(player, floorNum, slotNum)
				
				NotifySuccess:FireClient(player, "You bought a new slot!")
			else
				NotifyError:FireClient(player, "You don't have enough cash to buy a new slot!")
			end
		end
	end)
	
	function DataPlots.EggRoll(player, PreRolledRNG, EggPillars, EggsRolls, updateIndex: number?)
		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData then return end
		
		local plot = EggsRolls.Parent.Parent.Parent

		PreRolledRNG = PreRolledRNG or {}

		-- =========================
		-- Helpers
		-- =========================

		local function rollRNGForIndex(index)
			if index == 1 then
				return RngUtil(
					PlotUtil.EggChancesRarity.Legendary,
					DataPlots.GetExtraLuckMulti(player)
				)
			elseif index == 5 then
				return RngUtil(
					PlotUtil.EggChancesRarity.Mythic,
					DataPlots.GetExtraLuckMulti(player)
				)
			else
				return RngUtil(
					PlotUtil.EggChances,
					DataPlots.GetExtraLuckMulti(player)
				)
			end
		end

		local function middleFusionReady(rng)
			local a, b, c = rng[2], rng[3], rng[4]
			return a ~= nil and a == b and b == c
		end

		local function destroyEggAtIndex(index)
			for _, eggroll in pairs(EggsRolls:GetChildren()) do
				if eggroll:GetAttribute("ParentIndex") == index then
					eggroll:Destroy()
					break
				end
			end
		end

		local function spawnNormalEgg(info, pillar, rng)
			destroyEggAtIndex(info.Index)

			local egg
			if info.Premium then
				egg = PlotUtil.spawnEggRoll(rng, pillar, nil, "SpinRoll")
			else
				egg = PlotUtil.spawnEggRoll(rng, pillar, true, "SpinRoll")
			end

			if egg then
				egg.Parent = EggsRolls
			end

			profileData.PlotData.RollsInfo.EggRolls[info.Index] = egg and egg.Name
		end

		-- =========================
		-- Initialize RNG
		-- =========================

		for _, pillar in pairs(EggPillars) do
			local info = PlotUtil.getEggPillarInfo(pillar)
			if not info then continue end

			if not PreRolledRNG[info.Index] then
				PreRolledRNG[info.Index] =
					profileData.PlotData.RollsInfo.EggRolls[info.Index]
					or rollRNGForIndex(info.Index)
			end
		end

		if updateIndex then
			PreRolledRNG[updateIndex] = rollRNGForIndex(updateIndex)
		end

		-- =========================
		-- Fusion Path (NO RETURN)
		-- =========================

		local didFuse = updateIndex ~= 1 and updateIndex ~= 5 and 
			middleFusionReady(PreRolledRNG)
		if not GlobalSettings.EggFusionEnabled then
			didFuse = false
		end
		if didFuse then
			local CachedInvisibleEggs = {}
			
			local function setEggsVisible(visible: boolean)
				for _, egg in ipairs(EggsRolls:GetChildren()) do
					if egg:IsA("Model") then
						for _, d in ipairs(egg:GetDescendants()) do
							if d:IsA("BasePart") then
								d.Transparency = visible and 0 or 1
							end
						end
					elseif egg:IsA("BasePart") then
						egg.Transparency = visible and 0 or 1
					end
				end
			end
			
			local function setEggsParents(visible: boolean)
				if not visible then
					for _, egg in ipairs(EggsRolls:GetChildren()) do
						if egg:IsA("Model") or egg:IsA("BasePart") then
							table.insert(CachedInvisibleEggs, egg)
							
							egg.Parent = ReplicatedStorage.Cache
						end
					end
				else
					for _, egg in ipairs(CachedInvisibleEggs) do
						egg.Parent = EggsRolls
					end
					
					CachedInvisibleEggs = {}
				end
			end
			
			-- Destroy side middle eggs (2 & 4)
			--destroyEggAtIndex(2)
			--destroyEggAtIndex(4)
			
			-- Fusion Effect
			
			-- Hide all eggs during fusion
			setEggsVisible(false)
			setEggsParents(false)

			local cooldown = 6

			if not profileData.PlotData.SpinInfo.SpinBroken then
				local LastSpinTime: number = math.max(profileData.PlotData.SpinInfo.LastSpinTime,
					os.time()
				)
				local EndTime: number = LastSpinTime + cooldown
				
				profileData.PlotData.SpinInfo.CanSpin = false
				profileData.PlotData.SpinInfo.SpinCooldown = EndTime
				
				task.spawn(function()
					local connections = PlayerConnections:Get(player)

					connections:Add(
						task.defer(function()
							DataPlots.UpdatePlayerSpinInfo(player)
						end)
					)
				end)
				
				if clientData then
					clientData.PlotData(deepCopy(profileData.PlotData))
				end
			end
			
			local EffectClone = CachedEggsFusionEffect[plot]:Clone()
			local EggCombineComplete = EffectClone:WaitForChild("EggCombineComplete")

			EffectClone.Parent = EggsRolls.Parent:WaitForChild("Effects")
			EffectClone.Script.Enabled = true

			PlayerCooldowns.setCooldown(player, "EggRollSpinCooldown", cooldown)
			repeat task.wait(0.05) until EggCombineComplete.Value == true
			
			-- Show eggs again after fusion
			setEggsParents(true)
			
			-- 🔁 Re-roll side pillars (2 & 4)
			PreRolledRNG[2] = rollRNGForIndex(2)
			PreRolledRNG[4] = rollRNGForIndex(4)

			-- Re-roll ONLY pillar 3
			for _, pillar in pairs(EggPillars) do
				local info = PlotUtil.getEggPillarInfo(pillar)
				if not info or info.Index ~= 3 or info.Premium then continue end

				destroyEggAtIndex(3)

				local mutation, mutationTier =
					PlotUtil.RollFusionMutation(
						PreRolledRNG[3],
						DataPlots.GetExtraLuckMulti(player)
					)

				local egg = PlotUtil.spawnEggRoll(
					PreRolledRNG[3],
					pillar,
					true,
					"SpinRoll",
					mutationTier
				)

				if egg then
					egg.Parent = EggsRolls
				end

				profileData.PlotData.RollsInfo.EggRolls[3] = egg and egg.Name
			end
			
			setEggsVisible(true)
		end

		-- =========================
		-- Normal Roll Path
		-- =========================

		for _, pillar in pairs(EggPillars) do
			local info = PlotUtil.getEggPillarInfo(pillar)
			if not info then continue end
			if not didFuse then
				if updateIndex and info.Index ~= updateIndex then continue end
			end

			-- HARD LOCK middle when fused
			--if didFuse and (info.Index == 2 or info.Index == 3 or info.Index == 4) then
			--	continue
			--end

			if didFuse and (info.Index == 3) then
				continue
			end

			local rng = PreRolledRNG[info.Index]
			if not rng then continue end

			spawnNormalEgg(info, pillar, rng)
			
			task.wait(0.1)
		end
	end
	
	-- Egg Roll
	Network.Plots.EggRoll.OnServerEvent:Connect(function(player: Player)
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)
		
		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end
		
		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then return end
		
		if not profileData.PlotData.SpinInfo.CanSpin then 
			NotifyError:FireClient(player, "You can't spin at the moment!")
			return 
		end
		
		local cooldown: number = GlobalSettings.SpinCooldown
		
		if PlayerCooldowns.isOnCooldown(player, "EggRollSpinCooldown") then
			NotifyError:FireClient(player, "Please wait a bit before trying again!")
			return
		end
		PlayerCooldowns.setCooldown(player, "EggRollSpinCooldown", cooldown * 1.1)
		
		local dropper: Model = PlotUtil.getPlotDropper(plot)
		if not dropper then return end
		
		local EggPillars: { Model } = PlotUtil.getEggPillars(dropper)
		if not EggPillars then return end
		
		local EggsRolls: Folder = dropper:FindFirstChild("EggRolls")
		if not EggsRolls then return end
		
		local Screen, Button, GoButtonUI, BarUI = PlotUtil.getDropperSpinScreen(dropper)
		if not Button then return end
		
		local curTime: number = getUTCtime()
		local nextTime: number = curTime + cooldown

		profileData.PlotData.SpinInfo.CanSpin = false
		profileData.PlotData.SpinInfo.LastSpinTime = curTime
		profileData.PlotData.SpinInfo.SpinsCount += 1

		profileData.PlotData.RollsInfo.EggRollsCount += 1
		profileData.PlotData.RollsInfo.LastEggRollTime = curTime
		
		local Rolls: number, Triggered: boolean = PlotUtil.getRollsLeft(
			profileData.PlotData.SpinInfo.SpinsCount, GlobalSettings.BreakSpinEveryTry)

		if Triggered and not profileData.Gamepasses["Unbreakable Button"] then
			local LastSpinTime: number = profileData.PlotData.SpinInfo.LastSpinTime
			local EndTime: number = LastSpinTime + GlobalSettings.BreakForSeconds

			profileData.PlotData.SpinInfo.SpinCooldown = EndTime
			profileData.PlotData.SpinInfo.SpinBroken = true
			Button.Trigger:Fire(false, false, player)
		else
			profileData.PlotData.SpinInfo.SpinCooldown = nextTime
			Button.Trigger:Fire(true)
		end
		
		EggsRolls:ClearAllChildren()
		
		local RollsAmount: number = profileData.PlotData.RollsInfo.EggRollsCount

		local EpicRolls: number, EpicTriggered: boolean = 
			PlotUtil.getRollsLeft(RollsAmount, Pity.Epic)
		local LegendaryRolls: number, LegendaryTriggered: boolean = 
			PlotUtil.getRollsLeft(RollsAmount, Pity.Legendary)
		local MythicalRolls: number, MythicalTriggered: boolean = 
			PlotUtil.getRollsLeft(RollsAmount, Pity.Mythic)
		
		local PreRolledRNG = {} -- [Index] = RNG string

		for _, pillar in pairs(EggPillars) do
			local info = PlotUtil.getEggPillarInfo(pillar)
			if not info then continue end

			local rng: string

			if info.Premium and info.Rarity then
				rng = RngUtil(
					PlotUtil.EggChancesRarity[info.Rarity],
					DataPlots.GetExtraLuckMulti(player)
				)
			else
				rng = RngUtil(PlotUtil.EggChances, DataPlots.GetExtraLuckMulti(player))

				if info.Index == 2 and EpicTriggered then
					rng = RngUtil(PlotUtil.EggChancesRarity.Epic, DataPlots.GetExtraLuckMulti(player))
				elseif info.Index == 3 and MythicalTriggered then
					rng = RngUtil(PlotUtil.EggChancesRarity.Mythic, DataPlots.GetExtraLuckMulti(player))
				elseif info.Index == 4 and LegendaryTriggered then
					rng = RngUtil(PlotUtil.EggChancesRarity.Legendary, 
						DataPlots.GetExtraLuckMulti(player))
				end
			end

			PreRolledRNG[info.Index] = rng
		end
		
		DataPlots.EggRoll(player, PreRolledRNG, EggPillars, EggsRolls)
		
		DataPlots.UpdateRollsInfo(plot, profileData.PlotData.RollsInfo)
		
		clientData.PlotData(deepCopy(profileData.PlotData))
		
		-- Delayed
		local connections = PlayerConnections:Get(player)
		
		connections:Add(
			task.spawn(function()
				DataPlots.UpdatePlayerSpinInfo(player)
			end)
		)
	end)

	Network.Plots.BuyEggRoll.OnServerEvent:Connect(function(player: Player, eggName: string, eggPillarIndex: number)
		if typeof(eggName) ~= 'string' then return end
		if typeof(eggPillarIndex) ~= 'number' then return end
		
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)
		
		if PlayerCooldowns.isOnCooldown(player, "EggRollSpinCooldown") then
			NotifyError:FireClient(player, "Please wait a bit before trying again!")
			return 
		end
		
		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end
		
		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end
		
		local dropper: Folder = PlotUtil.getPlotDropper(plot)
		if not dropper then return end
		
		local EggsRolls: Folder = PlotUtil.getDropperEggsFolder(dropper)
		if not EggsRolls then return end
		
		local egg: Model? = nil
		for _, rollEgg in pairs(EggsRolls:GetChildren()) do
			local SameName: boolean = rollEgg.Name == eggName
			local SameIndex: boolean = rollEgg:GetAttribute("ParentIndex") == eggPillarIndex
			
			if SameName and SameIndex then
				egg = rollEgg
				
				break
			end
		end
		if not egg then return end
		
		local eggIndex: number = egg:GetAttribute("ParentIndex")
		if not eggIndex or eggIndex ~= eggPillarIndex then return end
		
		local EggPillars: { Model } = PlotUtil.getEggPillars(dropper)
		if not EggPillars then return end
		
		local eggPillar: Model? = PlotUtil.getEggPillarFromIndex(
			EggPillars, eggPillarIndex
		)
		if not eggPillar then return end
		
		local EggTool: Tool = PlotUtil.getEggTool(eggName)
		if not EggTool then return end
		
		if DataBackpack.Eggs.getLength(player) >= GlobalSettings.BackpackEggsLimit then
			return NotifyError:FireClient(player, "Your backpack is full, Place or Sell your eggs!")
		end
		
		local eggPillarInfo = PlotUtil.getEggPillarInfo(eggPillar)
		if not eggPillarInfo then return end
		
		if eggPillarInfo.Premium then
			local Product = Products[`Instant {eggPillarInfo.Rarity} Egg`]
			if Product then
				Network.Purchases.promptProduct:FireClient(player, Product, true)
				
				return
			end
		end
		
		local EggData = PlotUtil.EggsData[egg.Name]
		local EggCost, EggSellerCost = PlotUtil.CalculateCost({
			Name = egg.Name,
			EggMutationTier = egg:GetAttribute("EggMutationTier") or 1,
			Type = "Block"
		})
		
		--if EggData.Price > DataCash.getCash(player) then
		if EggCost > DataCash.getCash(player) then
			return NotifyError:FireClient(player, "You don't have enough cash to buy this egg!")
		end
		
		--DataCash.reduceCash(player, EggData.Price)
		DataCash.reduceCash(player, EggCost)
		
		local EggToolClone: Tool? = DataPlots.ConvertEggModelToRoll(egg)
		DataPlots.RemoveEggFromPillar(player, eggPillar)

		DataBackpack.Eggs.addBackpackEggByInstance(player, EggToolClone, true)
		
		NotifySuccess:FireClient(player, `You bought {EggToolClone.Name}!`)
		
		DataPlots.EggRoll(player, nil, EggPillars, EggsRolls, eggIndex)
		clientData.PlotData(deepCopy(profileData.PlotData))
		
		profileData.EggsReceived += 1
		clientData.EggsReceived(profileData.EggsReceived)
	end)

	Network.Plots.PlaceAtSlot.OnServerEvent:Connect(function(
		player: Player, placeName: string, floorNum: number, slotNum: number)
		
		if typeof(placeName) ~= 'string' then return end
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end
		
		local character: Model = player.Character
		if not character then return end
		
		local tool: Tool = character:FindFirstChildOfClass("Tool")
		if not tool then return end
		
		local IsToolPlaceable = tool:GetAttribute("Placeable")
		if not IsToolPlaceable then return end
		
		local Type = tool:GetAttribute("Type")
		if not Type then return end
		
		local id: string = tool:GetAttribute("Id")
		if not id then return end
		
		local floor: Model = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end
		
		local slots: Folder = floor:FindFirstChild("Slots")
		if not slots then return end
		
		local slot: Model = slots:FindFirstChild(slotNum)
		if not slot then return end
		
		local slotData: PlotUtil.SlotWorldData = PlotUtil.getSlotData(slot)
		if not slotData then return end
		
		local Placements: Folder = PlotUtil.getSlotsPlacements(slots)
		if not Placements then return end
		
		if slotData.IsForSale then return end
		if slotData.IsOccupied then return end
		
		local dropper: Folder? = PlotUtil.getPlotDropper(plot)
		if not dropper then return end
		
		local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
			PlotUtil.getDropperSpinScreen(dropper)
		if not Screen then return end
		
		tool:SetAttribute("Placeable", nil)
		
		if Type == "Block" then
			local PlayerEggData: Types.Egg? = DataBackpack.Eggs.getBackpackEggByID(player, id)
			if not PlayerEggData then return end
			
			local CloneEggData: Types.Egg = deepCopy(PlayerEggData)
			if not CloneEggData then return end
			
			DataBackpack.Eggs.removeBackpackEggByID(player, id)
			
			local EggData = PlotUtil.EggsData[tool.Name]
			
			CloneEggData.IsHatching = true
			CloneEggData.HatchTimeLeft = CloneEggData.HatchTimeLeft or EggData.HatchTime
			if CloneEggData.HatchTimeLeft >= EggData.HatchTime then
				local TripleHatchMultiplier = profileData.Gamepasses["Triple Hatch"]
					and 3 or 1
				
				CloneEggData.HatchTimeLeft = math.floor(CloneEggData.HatchTimeLeft / TripleHatchMultiplier)
			end
			
			profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement = CloneEggData
			
			DataPlots.SpawnEggAtSlot(slot, 
				profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement)
			
			DataPlots.SetSlotState(slot, false, true, 
				profileData.PlotData.Floors[floorNum].Slots[slotNum], player)
			
			clientData.PlotData(deepCopy(profileData.PlotData))
			
			profileData.EggsPlaced += 1
			clientData.EggsPlaced(profileData.EggsPlaced)
		elseif Type == "Labubu" then
			local CloneLabubuData: Types.Labubu? = nil :: Types.Labubu
			
			if not tool:GetAttribute("IsBeingStolen") then
				local PlayerLabubuData: Types.Labubu? = DataBackpack.Labubus.getById(player, id)
				if not PlayerLabubuData then return end

				CloneLabubuData = deepCopy(PlayerLabubuData)
				if not CloneLabubuData then return end

				DataBackpack.Labubus.removeById(player, id)
			else
				CloneLabubuData = tool:GetAttributes()
				if not CloneLabubuData then return end
				
				character:SetAttribute("IsStealing", nil)
				CloneLabubuData.IsBeingStolen = nil
				CloneLabubuData.FloorNum = nil
				CloneLabubuData.OwnerUserId = nil
				CloneLabubuData.ParentIndex = nil
				CloneLabubuData.Placeable = nil
				
				for _, instance: Instance? in pairs(getPlayerFullBackpack(player)) do
					if not instance:IsA("Tool") then continue end

					local Tool: Tool = instance
					
					if Tool:GetAttribute("Type") ~= "Labubu" then continue end
					if not Tool:GetAttribute("IsBeingStolen") then continue end
					
					Tool:Destroy()
				end
			end
			
			if CloneLabubuData then
				profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement = CloneLabubuData
				
				DataPlots.SpawnHatchableAtSlot(slot, CloneLabubuData, player)
				DataPlots.SetSlotState(slot, false, true, 
					profileData.PlotData.Floors[floorNum].Slots[slotNum], player)
				DataIndex.AddLabubuToIndex(player, 
					CloneLabubuData)
			end
		end
	end)
	
	Network.Plots.HatchEgg.OnServerEvent:Connect(function(player: Player,
		placeName: string, floorNum: number, slotNum: number)
		
		if typeof(placeName) ~= 'string' then return end
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end

		local character: Model = player.Character
		if not character then return end
		
		local floor: Model = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end

		local slots: Folder = floor:FindFirstChild("Slots")
		if not slots then return end

		local slot: Model = slots:FindFirstChild(slotNum)
		if not slot then return end

		local slotData: PlotUtil.SlotWorldData = PlotUtil.getSlotData(slot)
		if not slotData then return end

		local Placements: Folder = PlotUtil.getSlotsPlacements(slots)
		if not Placements then return end

		if slotData.IsForSale then return end
		if not slotData.IsOccupied then return end
		if not slotData.IsHatchable then return end

		local dropper: Folder? = PlotUtil.getPlotDropper(plot)
		if not dropper then return end

		local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
			PlotUtil.getDropperSpinScreen(dropper)
		if not Screen then return end
		
		local Placement = PlotUtil.getPlacementFromIndex(
			Placements, slotNum
		)
		if not Placement then return end
		if Placement.Name ~= placeName then return end
		
		if Placement:GetAttribute("Type") ~= "Block" then return end
		
		DataPlots.HatchEgg(Placement, slot, player)
	end)
	
	Network.Plots.SkipEggHatch.OnServerEvent:Connect(function(player: Player, floorNum: number, slotNum: number)
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end
		
		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end

		local character: Model = player.Character
		if not character then return end

		local floor: Model = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end

		local slots: Folder = floor:FindFirstChild("Slots")
		if not slots then return end

		local slot: Model = slots:FindFirstChild(slotNum)
		if not slot then return end

		local slotData: PlotUtil.SlotWorldData = PlotUtil.getSlotData(slot)
		if not slotData then return end

		local Placements: Folder = PlotUtil.getSlotsPlacements(slots)
		if not Placements then return end

		if slotData.IsForSale then return end
		if not slotData.IsOccupied then return end
		if slotData.IsHatchable then return end
		if not slotData.IsHatching then return end

		local dropper: Folder? = PlotUtil.getPlotDropper(plot)
		if not dropper then return end

		local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
			PlotUtil.getDropperSpinScreen(dropper)
		if not Screen then return end

		local Placement = PlotUtil.getPlacementFromIndex(
			Placements, slotNum
		)
		if not Placement then return end

		if Placement:GetAttribute("Type") ~= "Block" then return end
		
		local EggData = PlotUtil.EggsData[Placement.Name]
		if not EggData then return end
		
		local rarity = EggData.Rarity -- Common to Basic
		
		local Product = Products[`Skip {rarity} Hatch`]
		if not Product then return end
		
		PlayerAttributes.setAttribute(player, "SkipHatchFloorNum", floorNum)
		PlayerAttributes.setAttribute(player, "SkipHatchSlotNum", slotNum)
		
		Network.Purchases.promptProduct:FireClient(player, Product, true)
	end)
	
	Network.Plots.SkipMutation.OnServerEvent:Connect(function(player: Player,
		placeName: string, floorNum: number, slotNum: number)

		if typeof(placeName) ~= 'string' then return end
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end

		local character: Model = player.Character
		if not character then return end

		local floor: Model = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end

		local slots: Folder = floor:FindFirstChild("Slots")
		if not slots then return end

		local slot: Model = slots:FindFirstChild(slotNum)
		if not slot then return end

		local slotData: PlotUtil.SlotWorldData = PlotUtil.getSlotData(slot)
		if not slotData then return end

		local Placements: Folder = PlotUtil.getSlotsPlacements(slots)
		if not Placements then return end

		if slotData.IsForSale then return end
		if not slotData.IsOccupied then return end
		if not slotData.IsMutatable then return end

		local dropper: Folder? = PlotUtil.getPlotDropper(plot)
		if not dropper then return end

		local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
			PlotUtil.getDropperSpinScreen(dropper)
		if not Screen then return end

		local Placement = PlotUtil.getPlacementFromIndex(
			Placements, slotNum
		)
		if not Placement then return end
		if Placement.Name ~= placeName then return end

		if Placement:GetAttribute("Type") ~= "Labubu" then return end
		
		local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
		if not labubuData then return end

		local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
		if not GetMutationExtraInfo then return end

		if not GetMutationExtraInfo.NextMutationTier then return end
		if not profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating then 
			return 
		end
		
		local Product = Products[`Skip Mutation {GetMutationExtraInfo.CurrentMutationTier}`]
		
		PlayerAttributes.setAttribute(player, "SkipMutationFloorNum", floorNum)
		PlayerAttributes.setAttribute(player, "SkipMutationSlotNum", slotNum)

		Network.Purchases.promptProduct:FireClient(player, Product, true)
	end)
	
	Network.Plots.Mutate.OnServerEvent:Connect(function(player: Player,
		placeName: string, floorNum: number, slotNum: number)

		if typeof(placeName) ~= 'string' then return end
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end

		local character: Model = player.Character
		if not character then return end

		local floor: Model = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end

		local slots: Folder = floor:FindFirstChild("Slots")
		if not slots then return end

		local slot: Model = slots:FindFirstChild(slotNum)
		if not slot then return end

		local slotData: PlotUtil.SlotWorldData = PlotUtil.getSlotData(slot)
		if not slotData then return end

		local Placements: Folder = PlotUtil.getSlotsPlacements(slots)
		if not Placements then return end

		if slotData.IsForSale then return end
		if not slotData.IsOccupied then return end
		if not slotData.IsMutatable then return end
		if not slotData.ReadyToBeginMutate then return end

		local dropper: Folder? = PlotUtil.getPlotDropper(plot)
		if not dropper then return end

		local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
			PlotUtil.getDropperSpinScreen(dropper)
		if not Screen then return end

		local Placement = PlotUtil.getPlacementFromIndex(
			Placements, slotNum
		)
		if not Placement then return end
		if Placement.Name ~= placeName then return end

		if Placement:GetAttribute("Type") ~= "Labubu" then return end
		
		local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
		if not labubuData then return end

		local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
		if not GetMutationExtraInfo then return end
		
		if not GetMutationExtraInfo.NextMutationTier then return end
		if profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating then return end
		
		if DataCash.getCash(player) < GetMutationExtraInfo.Cost then 
			NotifyError:FireClient(player, "Not enough cash!")
			return
		end
		
		DataCash.reduceCash(player, GetMutationExtraInfo.Cost)
		
		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating = true
		
		DataPlots.SetSlotState(slot, false, true, 
			profileData.PlotData.Floors[floorNum].Slots[slotNum], player)
	end)
	
	Network.Plots.RevealMutation.OnServerEvent:Connect(function(player: Player,
		placeName: string, floorNum: number, slotNum: number)

		if typeof(placeName) ~= 'string' then return end
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end

		local character: Model = player.Character
		if not character then return end

		local floor: Model = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end

		local slots: Folder = floor:FindFirstChild("Slots")
		if not slots then return end

		local slot: Model = slots:FindFirstChild(slotNum)
		if not slot then return end

		local slotData: PlotUtil.SlotWorldData = PlotUtil.getSlotData(slot)
		if not slotData then return end

		local Placements: Folder = PlotUtil.getSlotsPlacements(slots)
		if not Placements then return end

		if slotData.IsForSale then return end
		if not slotData.IsOccupied then return end
		if not slotData.IsMutatable then return end

		local dropper: Folder? = PlotUtil.getPlotDropper(plot)
		if not dropper then return end

		local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
			PlotUtil.getDropperSpinScreen(dropper)
		if not Screen then return end

		local Placement = PlotUtil.getPlacementFromIndex(
			Placements, slotNum
		)
		if not Placement then return end
		if Placement.Name ~= placeName then return end

		if Placement:GetAttribute("Type") ~= "Labubu" then return end

		local labubuData = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement
		if not labubuData then return end

		local GetMutationExtraInfo = PlotUtil.GetMutationExtraInfo(labubuData)
		if not GetMutationExtraInfo then return end

		if not GetMutationExtraInfo.NextMutationTier then return end
		if not profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating then return end

		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating = false


		local success = Random.new():NextNumber(0, 100) <= GetMutationExtraInfo.SuccessRate
		-- success = false
		-- success = true
		if success then
			DataPlots.MutateLabubu(player, Placement, slot, floorNum, slotNum)

			-- NotifySuccess:FireClient(player, "You've successfully mutated your Labubu!")
			return
		else
			profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.MutationTime =
				GetMutationExtraInfo.MutationTime
			Placement:SetAttribute("IsMutating", false)
			
			-- NotifyError:FireClient(player, "Your Labubu mutation failed!")
			
			PlotUtil.setHatchableInfoUI(Placement, GetMutationExtraInfo.CurrentMutationName,
				labubuData.IsMutating, labubuData
			)
			
			local Id = profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.Id
			PlayerAttributes.setAttribute(player, 
				"LastMutationFail",
				{
					Id = Id,
					SlotNum = slotNum,
					FloorNum = floorNum
				}
			)
			
			if GetMutationExtraInfo.CurrentMutationTier > 1 then
				local newMutationTier = DataPlots.DowngradeLabubuMutation(player, Placement, slot, floorNum, slotNum)
				newMutationTier = newMutationTier or 1
				Network.Plots.MutateFail:FireClient(player, labubuData.Name, Id, newMutationTier)				
				return
			end
		end
		
		DataPlots.SetSlotState(slot, false, true, 
			profileData.PlotData.Floors[floorNum].Slots[slotNum], player)
		clientData.PlotData(deepCopy(profileData.PlotData))
	end)
	
	Network.Plots.TakeLabubu.OnServerEvent:Connect(function(
		player: Player, placeName: string, floorNum: number, slotNum: number)

		if typeof(placeName) ~= 'string' then return end
		if typeof(floorNum) ~= 'number' then return end
		if typeof(slotNum) ~= 'number' then return end

		if PlayerCooldowns.isOnCooldown(player, "GlobalRemoteEventCooldown") then return end
		PlayerCooldowns.setCooldown(player, "GlobalRemoteEventCooldown", 0.05)

		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData or not clientData then
			return nil
		end

		local character: Model = player.Character
		if not character then return end

		local floor: Model = PlotUtil.getFloor(plot, floorNum)
		if not floor then return end

		local slots: Folder = floor:FindFirstChild("Slots")
		if not slots then return end

		local slot: Model = slots:FindFirstChild(slotNum)
		if not slot then return end

		local slotData: PlotUtil.SlotWorldData = PlotUtil.getSlotData(slot)
		if not slotData then return end

		local Placements: Folder = PlotUtil.getSlotsPlacements(slots)
		if not Placements then return end

		if slotData.IsForSale then return end
		if not slotData.IsOccupied then return end

		local dropper: Folder? = PlotUtil.getPlotDropper(plot)
		if not dropper then return end

		local Screen, Button, GoButtonUI, BarUI, NextMutationUI = 
			PlotUtil.getDropperSpinScreen(dropper)
		if not Screen then return end
		
		local Placement = PlotUtil.getPlacementFromIndex(
			Placements, slotNum
		)
		if not Placement then return end
		if Placement.Name ~= placeName then return end

		if Placement:GetAttribute("Type") ~= "Labubu" then return end
		if profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement.IsMutating then return end

		if DataBackpack.Labubus.getLength(player) >= GlobalSettings.BackpackHatchablesLimit then
			return NotifyError:FireClient(player, "Your backpack is full, Place or Sell your Labubus!")
		end
		
		local LabubuTool: Tool = PlotUtil.getHatchableTool(Placement.Name)
		if not LabubuTool then return end
		
		local PlacementAttributes = Placement:GetAttributes()
		PlacementAttributes.ParentIndex = nil
		
		Placement:Destroy()
		
		profileData.PlotData.Floors[floorNum].Slots[slotNum].Placement = {}
		
		DataPlots.CollectAllSlotCash(profileData.PlotData.Floors[floorNum].Slots[slotNum],
			player
		)
		
		local LabubuToolClone = LabubuTool:Clone()
		copyAttributesFromTable(PlacementAttributes, LabubuToolClone)
		DataBackpack.Labubus.addToBackpackByInstance(player, LabubuToolClone, true)
		
		DataPlots.SetSlotState(slot, false, false)
		clientData.PlotData(deepCopy(profileData.PlotData))
	end)
	

	--[[
	workspace:WaitForChild("ResetEggsBackpack"):WaitForChild("ProximityPrompt").Triggered:Connect(function(player: Player)
		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end

		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData then
			return nil
		end
		
		DataBackpack.Eggs.ResetAll(player)
	end)

	-- adding a new floor to player
	workspace:WaitForChild("UnlockNewFloor"):WaitForChild("ProximityPrompt").Triggered:Connect(function(player: Player)
		local plot = DataPlots.GetPlayerPlot(player)
		if not plot then return end
		
		local profileData, clientData = DataHandler.getProfileData(player)
		if not profileData then
			return nil
		end
		
		local floorNum = DataPlots.CountFloorsFromPlotData(profileData.PlotData)
		if not floorNum then return end
		
		local nextFloorNum = floorNum + 1
		
		local wasfloorfound = plot:FindFirstChild("Floor" .. nextFloorNum)
		if wasfloorfound then return end
		
		for _, floor in pairs(CachedPlotsFloors[plot]) do
			if floor.Name == "Floor" .. tostring(nextFloorNum) then
				DataPlots.ExpandPlotFloors(plot, floorNum)
				DataPlots.AddFloorToPlayerData(player, nextFloorNum)
				
				NotifySuccess:FireClient(player, "You unlocked a new floor!")
				
				break
			end
		end
	end)
	--]]
	
	PlotsInitialized = true
end

----------------------------------------------------
-- Lookup helpers
----------------------------------------------------
function DataPlots.GetPlayerPlot(player: Player): Model?
	return PlayerPlots[player]
end

function DataPlots.GetPlotOwner(plot: Model): Player?
	return PlotStates[plot]
end

function DataPlots.GetFloorsFromPlotData(plotData: Types.PlotData?): { [number]: Types.FloorData }
	if not plotData or not plotData.Floors then
		return nil
	end

	return plotData.Floors
end

function DataPlots.CountFloorsFromPlotData(plotData: Types.PlotData?): number
	local floors = DataPlots.GetFloorsFromPlotData(plotData)

	local count = 0
	for floorNum in pairs(floors) do
		if typeof(floorNum) == "number" then
			count += 1
		end
	end

	return count
end



function DataPlots.WaitForPlot(player: Player): Model?
	-- Already assigned
	local existing = PlayerPlots[player]
	if existing then
		return existing
	end
	
	-- Player already gone
	if not player or not player:IsDescendantOf(Players) then
		return nil
	end

	-- Wait loop
	while player:IsDescendantOf(Players) do
		local plot = PlayerPlots[player]
		if plot then
			return plot
		end

		task.wait(0.05)
	end

	-- Player left while waiting
	return nil
end

-- Datastore Methods

function DataPlots.AddFloorToPlayerData(
	player: Player,
	floorNum: number
): boolean
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then
		return false
	end

	-- Validate
	if floorNum < 1 then
		return false
	end

	-- Ensure PlotData
	profileData.PlotData = profileData.PlotData or {}
	profileData.PlotData.Floors = profileData.PlotData.Floors or {}

	local floors = profileData.PlotData.Floors

	-- Already exists
	if floors[floorNum] ~= nil then
		return false
	end

	floors[floorNum] = {
		Slots = {
			
		}
	}

	-- Sync client
	if clientData then
		clientData.PlotData(deepCopy(profileData.PlotData))
	end

	return true
end

function DataPlots.AddNextAvailableFloorToPlayerData(player: Player): number?
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then
		return nil
	end

	-- Ensure PlotData
	profileData.PlotData = profileData.PlotData or {}
	profileData.PlotData.Floors = profileData.PlotData.Floors or {}

	local floors = profileData.PlotData.Floors

	-- Find first missing floor starting from 1
	local floorNum = 1
	while floors[floorNum] ~= nil do
		floorNum += 1
	end

	-- Create missing floor
	floors[floorNum] = {
		Slots = {}
	}
	
	if clientData then
		clientData.PlotData(deepCopy(profileData.PlotData))
	end

	return floorNum
end

function DataPlots.AddSlotToPlayerData(
	player: Player,
	floorNum: number,
	slotNum: number
): boolean
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then
		return false
	end

	-- Ensure PlotData
	profileData.PlotData = profileData.PlotData or {}
	profileData.PlotData.Floors = profileData.PlotData.Floors or {}

	-- Ensure floor
	local floors = profileData.PlotData.Floors
	floors[floorNum] = floors[floorNum] or { Slots = {} }

	local floorData = floors[floorNum]
	floorData.Slots = floorData.Slots or {}
	
	floorData.Slots[slotNum] = floorData.Slots[slotNum] or {}

	-- Already owned?
	if floorData.Slots[slotNum].Placement ~= nil then
		return false
	end

	-- ✅ Own the slot (empty)
	floorData.Slots[slotNum].Placement = {}
	floorData.Slots[slotNum].Cash = floorData.Slots[slotNum].Cash or 0
	floorData.Slots[slotNum].OfflineCash = floorData.Slots[slotNum].OfflineCash or 0
	
	if clientData then
		clientData.PlotData(deepCopy(profileData.PlotData))
	end

	return true
end

function DataPlots.characterAdded(player: Player, character: Model) -- automatic
	DataPlots.AssignPlot(player)
	
	local plot: Model = DataPlots.GetPlayerPlot(player)
	if not plot then return end
	DataPlots.TeleportPlayerToPlot(player, plot)
	
	local profileData, clientData = DataHandler.waitForPlayerData(player)
	if profileData == nil or clientData == nil then return end
	
	DataBackpack.Eggs.EquipAll(player)
	DataBackpack.Labubus.EquipAll(player)
end

function DataPlots.earlyPlayerAdded(player: Player) -- automatic

end

function DataPlots.latePlayerRemoving(player: Player) -- automatic
	
end

function DataPlots.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	local plot: Model = DataPlots.WaitForPlot(player)
	if plot then
		profileData.PlotData.Floors = profileData.PlotData.Floors or {}
		profileData.PlotData.Floors[1] = profileData.PlotData.Floors[1] or {}
		
		profileData.PlotData.Floors[1].Slots = profileData.PlotData.Floors[1].Slots or {}
		
		profileData.PlotData.Floors[1].Slots[1] = profileData.PlotData.Floors[1].Slots[1] or {}
		profileData.PlotData.Floors[1].Slots[2] = profileData.PlotData.Floors[1].Slots[2] or {}
		profileData.PlotData.Floors[1].Slots[3] = profileData.PlotData.Floors[1].Slots[3] or {}
		
		profileData.PlotData.Floors[1].Slots[1] = 
			Reconcile(Types.Slot, profileData.PlotData.Floors[1].Slots[1])
		profileData.PlotData.Floors[1].Slots[2] = 
			Reconcile(Types.Slot, profileData.PlotData.Floors[1].Slots[2])
		profileData.PlotData.Floors[1].Slots[3] = 
			Reconcile(Types.Slot, profileData.PlotData.Floors[1].Slots[3])
		
		--profileData.PlotData.SpinInfo = profileData.PlotData.SpinInfo or Types.PlotSpinInfo
		profileData.PlotData.SpinInfo = Reconcile(Types.PlotSpinInfo, profileData.PlotData.SpinInfo)
		--profileData.PlotData.RollsInfo = profileData.PlotData.RollsInfo or Types.PlotRollsInfo
		profileData.PlotData.RollsInfo = Reconcile(Types.PlotRollsInfo, profileData.PlotData.RollsInfo)
		
		profileData.Backpack = Reconcile(Types.Backpack, profileData.Backpack)
		
		if profileData.LastDailyRewardTime == 0 then
			profileData.LastDailyRewardTime = os.time()
			clientData.LastDailyRewardTime(profileData.LastDailyRewardTime)
		end
		
		if profileData.PlotData.SpinInfo.CanSpin == false then
			local connections = PlayerConnections:Get(player)

			connections:Add(
				task.defer(function()
					DataPlots.UpdatePlayerSpinInfo(player, true)
				end)
			)
		end
		
		DataPlots.ApplyPlotData(plot, profileData.PlotData, player)
		
		clientData.Plot(plot)
		clientData.PlotData(deepCopy(profileData.PlotData))
		
		plot:SetAttribute("Initialized", true)
		player:SetAttribute("PlotInitialized", true)
		plot:SetAttribute("OwnerUserId", player.UserId)
	end
	
	--warn(player.Name, "data loaded")
	--print(profileData, clientData)
end

function DataPlots.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	
	local Plot = DataPlots.GetPlayerPlot(player)
	if Plot then
		if profileData then
			DataPlots.BeforePlayerLeave(player, Plot, profileData.PlotData)
		end
	end
	DataPlots.UnassignPlot(player)
	
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data unloading")
end

DataPlots.InitAllPlots()

return DataPlots