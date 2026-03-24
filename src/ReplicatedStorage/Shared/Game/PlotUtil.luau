local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isClient = RunService:IsClient()

local Data = ReplicatedStorage.Data
local DataEggs = Data.Eggs
local Eggs = ReplicatedStorage.Assets.Eggs
local EggTools = ReplicatedStorage.Assets.EggTools
local LabubuTools = ReplicatedStorage.Assets.LabubuTools

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)
local getProductStaticPrice = require(ReplicatedStorage.Shared.Utility.Roblox.getProductStaticPrice)
local Network = require(ReplicatedStorage.Network)
local Types = require(ReplicatedStorage.Shared.Types)
local RatelimitUtil = require(ReplicatedStorage.Shared.Utility.RatelimitUtil)
local RngUtil = require(ReplicatedStorage.Shared.Utility.RngUtil)
local Pity = require(ReplicatedStorage.Data.Pity)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local RarityTextColors = require(ReplicatedStorage.Data.TextColors.Rarity)
local MutationTextColors = require(ReplicatedStorage.Data.TextColors.Mutation)
local MutationTier = require(ReplicatedStorage.Data.MutationTier)
local EggsMutation = require(ReplicatedStorage.Data.EggsMutation)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)
local getProductStaticPrice = require(ReplicatedStorage.Shared.Utility.Roblox.getProductStaticPrice)
local TimeFormat = require(ReplicatedStorage.Shared.Utility.Format.TimeFormat)
local getUTCtimeMS = require(ReplicatedStorage.Shared.Utility.Time.getUTCtimeMS)
local getUTCtime = require(ReplicatedStorage.Shared.Utility.Time.getUTCtime)
local generateGUID = require(ReplicatedStorage.Shared.Utility.String.generateGUID)
local copyAttributesFromTable = require(ReplicatedStorage.Shared.Utility.Roblox.copyAttributesFromTable)
local InterfaceTabUtil = isClient and
	require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil) or nil
local LabubusData = require(ReplicatedStorage.Data.Labubus)
local HatchableAssets = ReplicatedStorage.Assets.Hatchables
local mergeTables = require(ReplicatedStorage.Shared.Utility.Table.mergeTables)
local Events = require(ReplicatedStorage.Data.Events)

local shuffleTable = require(ReplicatedStorage.Shared.Utility.Table.shuffleTable)

local GlobalSettings = require(ReplicatedStorage.GlobalSettings)

local ButtonRatelimit = RatelimitUtil.new(0.1)

local EggInfoUI: BillboardGui = ReplicatedStorage.Assets.Interface.BillboardGui.InfoUI
local HatchableInfoUI: BillboardGui = ReplicatedStorage.Assets.Interface.BillboardGui.HatchableInfoUI

local ModelsMutationEffects = ReplicatedStorage.Assets.Effects.ModelsMutationEffects

local InterfaceSounds = ReplicatedStorage.Assets.Sounds.Interface
local ClickSound = InterfaceSounds.ButtonClick
local HoverSound = InterfaceSounds.ButtonHover

local BuyVIPSlotProduct = Products.BuyVIPSlot
local BuyVIPSlotProductInfo = getProductStaticPrice(BuyVIPSlotProduct, Enum.InfoType.Product)
local BuyVIPSlotPrice = BuyVIPSlotProductInfo and BuyVIPSlotProductInfo.PriceInRobux or 0

local BuyLegendaryInstantProduct = Products["Instant Legendary Block"]
local BuyLegendaryInstantProductInfo = getProductStaticPrice(
	BuyLegendaryInstantProduct, Enum.InfoType.Product)
local BuyLegendaryInstantProductPrice = BuyLegendaryInstantProductInfo and 
	BuyLegendaryInstantProductInfo.PriceInRobux or 0

local BuyMythicInstantProduct = Products["Instant Mythic Block"]
local BuyMythicInstantProductInfo = getProductStaticPrice(
	BuyMythicInstantProduct, Enum.InfoType.Product)
local BuyMythicInstantProductPrice = BuyMythicInstantProductInfo and 
	BuyMythicInstantProductInfo.PriceInRobux or 0

local RepairProduct = Products["Repair Button"]

--task.spawn(function()
--	getProductInfo(BuyLegendaryInstantProduct, Enum.InfoType.Product):andThen(function(productInfo)
--		BuyLegendaryInstantProductPrice = productInfo.PriceInRobux or 0
--	end)

--	getProductInfo(BuyMythicInstantProduct, Enum.InfoType.Product):andThen(function(productInfo)
--		BuyMythicInstantProductPrice = productInfo.PriceInRobux or 0
--	end)
	
--	getProductInfo(BuyVIPSlotProduct, Enum.InfoType.Product):andThen(function(productInfo)
--		BuyVIPSlotPrice = productInfo.PriceInRobux or 0
--	end)
--end)

local constantTrove = Trove.new()
local slotTrove = Trove.new()

local PlotUtil = {
	EggsData = {},
	EggChances = {},
	EggChancesRarity = {},
	
	ButtonRatelimit = ButtonRatelimit,
	
	ProductsInfo = {
		BuyVIPSlot = BuyVIPSlotProductInfo,
		BuyLegendaryInstant = BuyLegendaryInstantProductInfo,
		BuyMythicInstant = BuyMythicInstantProductInfo,
	}
}

local ClientInitialized = false
local CurrentlyInitializingPlotClient = false
local CachedClientPlotData: Types.PlotData = nil :: Types.PlotData

export type LabubuType = {
	DisplayName: string,
	Rarity: string,
	CPS: number,
	Weight: number,
}

export type SlotWorldData = {
	SlotNum: number?,
	floorNum: number?,
	IsVipSlot: boolean?,
	IsOccupied: boolean?,
	IsForSale: boolean?,
	IsHatchable: boolean?,
	IsHatching: boolean?,
	IsMutatable: boolean?,
	ReadyToBeginMutate: boolean?,
	ReadyToMutate: boolean?,
	IsMutating: boolean?,
	Price: number?,
	MainStand: BasePart?
}

export type SlotsWorldPartsData = {
	Display: BasePart?,
	CollectPart: BasePart?,
	FloatingCollectUI: BillboardGui?,
	Screen: Model?,
	Button: Model?,
	ScreenGo: BasePart?,
	ScreenMain: BasePart?,
	GoButtonUI: BillboardGui?,
	NextMutationUI: BillboardGui?,
}

export type WorldPlotData = {
	Initialized: boolean?,
	FloorsCount: number,
	Floors: { Model },
	FrontSurfaceUITextLabel: TextLabel,
	SpawnPart: BasePart,
	OwnerUserId: number?,
}

for _, module in pairs(Data.Eggs:GetChildren()) do
	if module:IsA("ModuleScript") then
		PlotUtil.EggsData[module.Name] = require(module) :: Types.EggData
		
		local Weight = PlotUtil.EggsData[module.Name].Weight
		local Rarity = PlotUtil.EggsData[module.Name].Rarity
		
		if Weight ~= nil then
			PlotUtil.EggChances[module.Name] = PlotUtil.EggsData[module.Name].Weight
			
			PlotUtil.EggChancesRarity[Rarity] = PlotUtil.EggChancesRarity[Rarity] or {}
			PlotUtil.EggChancesRarity[Rarity][module.Name] = Weight
		end
	end
end

function PlotUtil.getRollsLeft(RollsAmount: number, pityValue: number)
	if RollsAmount == 0 then
		return pityValue, false
	end

	local remainder = RollsAmount % pityValue

	-- pity just triggered
	if remainder == 0 then
		return pityValue, true
	end

	return pityValue - remainder, false
end

function PlotUtil.getLabubuData(labubuName: string) : LabubuType
	return LabubusData[labubuName]
end

function PlotUtil.getLabubusWithRarity(rarity: string) : { [string]: LabubuType }?
	local Labubus: { [string]: LabubuType } = {}
	
	for name, tbl: LabubuType in LabubusData do
		if tbl.Rarity == rarity then -- Common to Basic
			if HatchableAssets:FindFirstChild(name) then
				Labubus[name] = tbl
			else
				warn("NOT FOUND:", name)
			end
		end
	end
	
	return Labubus
end

function PlotUtil.CreateLabubuTemplateFromEggData(
	name: string, defaultLabubuData: LabubuType, labubuData: Types.Labubu?, 
	eggRarity: string?, eggName: string?	
)
	: Types.Labubu?
	local currentTime = getUTCtime()

	local eggRarity: string? = eggRarity
	local eggNameSplit: string? = eggName:split(" ")[1]
	
	local MutationTier = labubuData.MutationTier or 1
	local MutationName = PlotUtil.MutationTierToName(MutationTier)
	local MutationTierInfo = PlotUtil.getMutationInfo(MutationName)
	
	local traits = labubuData.Traits or Types.Traits

	local Template = {
		Id = labubuData.Id or generateGUID(),
		Name = labubuData.Name or name,
		Type = "Labubu",

		-- Origin / Rarity
		Source = labubuData.Source or "Normal",
		EggRarity = labubuData.EggRarity or eggRarity or "Common", -- Common to Basic
		EggType = labubuData.EggType or eggNameSplit,

		-- Progression
		MutationTier = MutationTier, -- current tier (1–11)
		MaxMutationTier = labubuData.MaxMutationTier or nil, -- usually 11
		BaseCPS = labubuData.BaseCPS or defaultLabubuData.CPS, -- CPS before multipliers

		-- Mutation State
		IsMutating = labubuData.IsMutating or false,
		MutationTime = labubuData.MutationTime or (MutationTierInfo and MutationTierInfo.MutationTime),

		-- Final Calculated Output
		--CPS = labubuData.CPS or defaultLabubuData.CPS,  -- BaseCPS × mutation × traits × rebirth
		CPS = labubuData.CPS or PlotUtil.CalculateCPSbyName(name, MutationName, nil, traits),  
		-- BaseCPS × mutation × traits × rebirth

		-- Collection & Rules
		IsStealable = labubuData.IsStealable or true,       -- false if mutating / exclusive / event
		Traits = traits,

		-- Metadata
		CreatedAt = labubuData.CreatedAt or currentTime,
		LastCollectedAt = labubuData.LastCollectedAt or nil,
	}

	return Template
end

function PlotUtil.TranslateEggToHatchable(egg: Model | string) : (string?, LabubuType?)
	local eggName = typeof(egg) == "string" and egg or egg.Name
	local eggData = PlotUtil.EggsData[eggName]
	if not eggData then return end
	
	local eggRarity = eggData.Rarity
	if not eggRarity then return end
	
	local Labubus = PlotUtil.getLabubusWithRarity(eggRarity)
	
	if not Labubus then return end
	
	local SortedByWeights: { [string]: number } = {}
	
	for name, tbl: LabubuType in pairs(Labubus) do
		SortedByWeights[name] = tbl.Weight
	end
	
	local RNG = RngUtil(SortedByWeights)
	
	for name, tbl: LabubuType in pairs(Labubus) do
		if RNG == name then
			return RNG, tbl
		end
	end
	
	return RNG
end

function PlotUtil.getPlotDropper(plot: Model) : Folder?
	local Floor1: Model = plot:FindFirstChild("Floor1")
	if not Floor1 then return end

	local Dropper: Model = Floor1:FindFirstChild("Dropper")
	return Dropper
end

function PlotUtil.getEggPillars(dropper: Folder) : { Model }
	local tbl: { Model } = {}
	
	for _, model in pairs(dropper:GetChildren()) do
		if model.Name == "EggPillar" then
			table.insert(tbl, model)
		end
	end
	
	return tbl
end

function PlotUtil.getDropperEggsFolder(dropper: Folder) : Folder
	return dropper:FindFirstChild("EggRolls")
end

export type MutationTierInfo = {
	Tier: number,
	Multiplier: number,
	SuccessRateNext: number, -- %
	FailureDowngrade: string,
	MutationTime: number, -- seconds
	CostMultiplier: number?,
}

function PlotUtil.getMutationInfo(mutation: string) : MutationTierInfo
	return MutationTier[mutation]
end

function PlotUtil.MutationTierToName(tier: number) : string?
	for name, info in pairs(MutationTier) do
		if info.Tier == tier then
			return name
		end
	end
end

function PlotUtil.MutationNameToTier(name: string): number?
	local info = MutationTier[name]
	return info and info.Tier or nil
end

export type EggMutationInfo = {
	HatchTime: number,
	SkipRobuxCost: number,

	Mutations: {
		Default     : { Cost: number, FusionChance: number? },
		Silver      : { Cost: number, FusionChance: number? },
		Gold        : { Cost: number, FusionChance: number? },
		Diamond     : { Cost: number, FusionChance: number? },
		Rainbow     : { Cost: number, FusionChance: number? },
		Thunder     : { Cost: number, FusionChance: number? },
		Saiyan      : { Cost: number, FusionChance: number? },
		Conqueror   : { Cost: number, FusionChance: number? },
		Corrupted   : { Cost: number, FusionChance: number? },
		Galaxy      : { Cost: number, FusionChance: number? },
		Divine      : { Cost: number, FusionChance: number? },
	}
}

function PlotUtil.getEggMutationInfo(eggName: string) : EggMutationInfo
	return EggsMutation[eggName]
end
	
function PlotUtil.getEggPillarFromIndex(eggPillars: { Model }, index: number) : Model?
	for _, eggPillar in pairs(eggPillars) do
		local EggPillarIndex = eggPillar:GetAttribute("Index")
		if not EggPillarIndex then continue end
		
		if EggPillarIndex == index then
			return eggPillar
		end
	end
end

function PlotUtil.getPlacementFromIndex(placements: Folder, index: number) : Model?
	for _, placement in pairs(placements:GetChildren()) do
		local PlacementIndex = placement:GetAttribute("ParentIndex")
		if not PlacementIndex then continue end
		
		if PlacementIndex == index then
			return placement
		end
	end
end

function PlotUtil.getPlacementFromId(placements: Folder, id: number) : Model?
	for _, placement in pairs(placements:GetChildren()) do
		local PlacementId = placement:GetAttribute("Id")
		if not PlacementId then continue end

		if PlacementId == id then
			return placement
		end
	end
end

function PlotUtil.getEggFromIndex(eggRolls: Folder, index: number) : Model?
	for _, egg in pairs(eggRolls:GetChildren()) do
		local EggIndex = egg:GetAttribute("ParentIndex")
		if not EggIndex then continue end

		if EggIndex == index then
			return egg
		end
	end
end

function PlotUtil.getEggPillarInfo(eggPillar: Model): { 
	UpperPart: BasePart, LowerPart: BasePart, Premium: boolean?, Rarity: string?, Index: number? }
	local UpperPart: BasePart = eggPillar:WaitForChild("Model"):WaitForChild("UpperPart")
	local LowerPart: BasePart = eggPillar:WaitForChild("BottomPart"):WaitForChild("LowerPart")

	return {
		UpperPart = UpperPart,
		LowerPart = LowerPart,

		Premium = eggPillar:GetAttribute("Premium"),
		Rarity = eggPillar:GetAttribute("Rarity"),
		Index = eggPillar:GetAttribute("Index"),
	}
end

function PlotUtil.RollFusionMutation(eggName: string, luck: number?, seed: number?)
	: (string?, number?)
	
	local tier = EggsMutation[eggName]
	if not tier then
		eggName = eggName:split(" ")[1]
		tier = EggsMutation[eggName]
	end
	
	if not tier then
		error(("Invalid mutation tier: %s"):format(eggName))
	end

	local rngTable = {}

	for mutationName, data in pairs(tier.Mutations) do
		if data.FusionChance then
			rngTable[mutationName] = data.FusionChance
		end
	end

	-- Roll mutation
	local result = RngUtil(rngTable, luck or 1, seed)
	
	local MutationTier = result and PlotUtil.MutationNameToTier(result) or 1

	-- Fallback safety
	return result or "Default", MutationTier
end

function PlotUtil.getTraitData(traitName: string) : Types.WeatherData
	return Events.Events[traitName]
end

--function PlotUtil.getLabubuTraits(model: Model | Types.Labubu)
function PlotUtil.getLabubuTraits(labubu: Types.Labubu)
	--if typeof(model) == "Instance" then
	--	local Attributes = model:GetAttributes()
	--	if not Attributes then return end
		
	--	local Traits = {}
		
	--	for name, value in pairs(Attributes) do
	--		if Events.Events[name] then
	--			Traits[name] = true
	--		end
	--	end
		
	--	return Traits
	--else
	--return model.Traits
	--end
	
	return labubu.Traits or {}
end

function PlotUtil.setHatchableInfoUI(hatchable: Model, mutation: string?, isMutating: boolean?,
	labubuData: Types.Labubu?
)
	local HatchableData = PlotUtil.getLabubuData(hatchable.Name)
	if not HatchableData then return end

	local HatchablePart: BasePart = hatchable:FindFirstChild("RootPart") or hatchable.PrimaryPart
	local InfoUI: BillboardGui = HatchablePart:FindFirstChild("HatchableInfoUI")

	if not InfoUI then
		InfoUI = HatchableInfoUI:Clone()
		InfoUI.Parent = HatchablePart
	end

	local CPS = formatCommaValue(HatchableData.CPS)
	
	if mutation then 
		local CalculatedCPS = PlotUtil.CalculateCPSbyName(hatchable.Name, mutation,
			nil, labubuData and PlotUtil.getLabubuTraits(labubuData)
		)
		CPS = formatCommaValue(CalculatedCPS)
	end
	
	local WasAnyTraitFound = false
	if labubuData then
		local Traits = PlotUtil.getLabubuTraits(labubuData)
		if Traits then
			for name, value in pairs(Traits) do
				WasAnyTraitFound = true
				
				if InfoUI.Traits:FindFirstChild(name) then continue end
				
				local Icon = PlotUtil.getTraitData(name).Icon
				
				local ImageLabel = Instance.new("ImageLabel")
				ImageLabel.Image = Icon
				ImageLabel.ScaleType = Enum.ScaleType.Fit
				ImageLabel.Name = name
				ImageLabel.Parent = InfoUI.Traits
			end
		end
	end
	
	InfoUI.Traits.Visible = WasAnyTraitFound

	InfoUI.NameLabel.Text = HatchableData.DisplayName
	InfoUI.RarityLabel.Text = HatchableData.Rarity
	InfoUI.RarityLabel.TextColor3 = RarityTextColors[HatchableData.Rarity]
	InfoUI.CPSLabel.Text = "$" .. CPS .. "/s"
	
	if mutation and mutation ~= "Default" then
		PlotUtil.addMutationEffect(hatchable, mutation)
		InfoUI.MutationLabel.Text = mutation
		
		local color = MutationTextColors[mutation]
		if color then
			InfoUI.MutationLabel.TextColor3 = color
		end
		
		InfoUI.MutationLabel.Visible = true
	else
		InfoUI.MutationLabel.Visible = false
	end
	
	InfoUI.IsMutatingLabel.Visible = isMutating
end

function PlotUtil.setEggPriceInfoUI(egg: Model, priceOnly: boolean?, hidePrice: boolean?)
	local EggData = PlotUtil.EggsData[egg.Name]

	local EggPart: BasePart = egg:FindFirstChild("EggPart") or egg.PrimaryPart
	local InfoUI: BillboardGui = EggPart:FindFirstChild("InfoUI")
	
	if not InfoUI then
		InfoUI = EggInfoUI:Clone()
		InfoUI.Parent = EggPart
	end
	
	local MutationTier = egg:GetAttribute("EggMutationTier") or 1
	local MutationName = PlotUtil.MutationTierToName(MutationTier)
	
	PlotUtil.addMutationEffect(egg, MutationTier)
	
	local EggCost, EggSellerCost = PlotUtil.CalculateCost({
		Name = egg.Name,
		EggMutationTier = MutationTier,
		Type = "Block"
	})

	--local Price = formatCommaValue(EggData.Price)
	local Price = formatCommaValue(EggCost)

	InfoUI.NameLabel.Text = EggData.DisplayName
	InfoUI.RarityLabel.Text = EggData.Rarity
	InfoUI.RarityLabel.TextColor3 = RarityTextColors[EggData.Rarity]
	
	if MutationName and MutationName ~= "Default" then
		InfoUI.MutationLabel.Text = MutationName

		local color = MutationTextColors[MutationName]
		if color then
			InfoUI.MutationLabel.TextColor3 = color
		end

		InfoUI.MutationLabel.Visible = true
	else
		InfoUI.MutationLabel.Visible = false
	end

	if EggData.RobuxPreferred and not priceOnly then
		if EggData.Rarity == "Mythic" then
			Price = formatCommaValue(BuyMythicInstantProductPrice)
		elseif EggData.Rarity == "Legendary" then
			Price = formatCommaValue(BuyLegendaryInstantProductPrice)
		end

		InfoUI.PriceLabel.Text = "R$ " .. Price
		InfoUI.PriceLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
	else
		InfoUI.PriceLabel.Text = "$" .. Price
		
		if priceOnly then
			egg:SetAttribute("PriceOnly", true)
		end
	end
	
	InfoUI.PriceLabel.Visible = not hidePrice
end

function PlotUtil.getMutationEffect(mutation: (number | string))
	if typeof(mutation) == "number" then
		mutation = PlotUtil.MutationTierToName(mutation)
	end
	
	local Effect = ModelsMutationEffects:FindFirstChild(mutation)
	if not Effect and mutation ~= "Default" then
		warn("Mutation effect not found: " .. tostring(mutation))
		return nil
	end
	
	return Effect
end

function PlotUtil.addMutationEffect(model: Model | Tool, mutation: (number | string))
	local Effect = PlotUtil.getMutationEffect(mutation)
	if not Effect then return end
	
	for _, effect in pairs(Effect:GetChildren()) do
		if not model:FindFirstChild(effect.Name) then
			local EffectClone = effect:Clone()
			EffectClone:AddTag("FX")
			EffectClone.Parent = model
		end
	end
end

function PlotUtil.spawnEggRoll(
	eggName: string, parent: Instance, 
	priceOnly: boolean?, obtainedFrom: string?,
	mutationTier: number?
)
	mutationTier = mutationTier or 1
	local egg: Model = Eggs:FindFirstChild(eggName)

	if not egg then
		warn("Egg not found: " .. eggName)
		return nil
	end

	local clone = egg:Clone()
	
	local ParentIndex = parent and parent:GetAttribute("Index")
	if ParentIndex then
		clone:SetAttribute("ParentIndex", ParentIndex)
	end
	if obtainedFrom then
		clone:SetAttribute("ObtainedFrom", obtainedFrom)
	end
	clone:SetAttribute("Type", "Block")
	clone:SetAttribute("EggMutationTier", mutationTier)
	
	PlotUtil.setEggPriceInfoUI(clone, priceOnly)

	clone:AddTag("EggModel")
	if parent then
		PlotUtil.deployWorldEggRoll(clone, parent)
	end

	return clone
end

function PlotUtil.deployWorldEggRoll(egg: Model, eggPillar: Model) : Model
	local PillarInfo = PlotUtil.getEggPillarInfo(eggPillar)
	local GetExtentsSize: Vector3 = egg:GetExtentsSize()
	local GetExtentsSizeY: number = GetExtentsSize.Y

	egg:PivotTo(
		PillarInfo.LowerPart.CFrame + Vector3.new(0, GetExtentsSizeY / 2 + PillarInfo.LowerPart.Size.Y/2, 0)
	)
	
	return egg
end

function PlotUtil.getEggRollsScreen(dropper: Folder) : (BasePart?, BillboardGui?)
	local EggRollsInfo: Model = dropper:FindFirstChild("EggRollsInfo")
	if not EggRollsInfo then return end
	
	local Screen: Model = EggRollsInfo:FindFirstChild("Screen")
	if not Screen then return end
	
	local LuckBoardUI: BillboardGui = Screen:FindFirstChild("LuckBoardUI")
	if not LuckBoardUI then return end
	
	return Screen, LuckBoardUI
end

function PlotUtil.setEggsRollScreenUIState(plot: Model, state: boolean)
	local dropper: Folder? = PlotUtil.getPlotDropper(plot)
	if not dropper then return end
	local EggRollsScreen: BasePart?, EggRollsScreenUI: BillboardGui? = PlotUtil.getEggRollsScreen(dropper)
	if not EggRollsScreen or not EggRollsScreenUI then
		return
	end

	EggRollsScreenUI.Enabled = state
end

function PlotUtil.getDropperSpinScreen(dropper: Folder) : 
	(Model?, BasePart?, BillboardGui?, BillboardGui?)
	local SpinEggs: Model = dropper:FindFirstChild("SpinEggs")
	if not SpinEggs then return end
	
	local Screen: Model = SpinEggs:FindFirstChild("Screen")
	if not Screen then return end
	
	local Button: BasePart = Screen:FindFirstChild("Button")
	if not Button then return end
	
	local GoButtonUI: BillboardGui = Button:FindFirstChild("GoButtonUI")
	if not GoButtonUI then return end
	
	local BarUI: BillboardGui = Button:FindFirstChild("BarUI")
	if not BarUI then return end
	
	return Screen, Button, GoButtonUI, BarUI
end

function PlotUtil.getSlotWorldData(slot: Model) : SlotsWorldPartsData
	local Button: Model = slot:FindFirstChild("Button")
	if not Button then return end

	local CollectPart: BasePart = Button:FindFirstChild("CollectPart")
	if not CollectPart then return end

	local FloatingCollectUI: BillboardGui = CollectPart:FindFirstChild("FloatingCollectUI")
	if not FloatingCollectUI then return end

	local Display: BasePart = slot:FindFirstChild("Display")
	if not Display then return end

	local Screen: Model = Display:FindFirstChild("Screen")
	if not Screen then return end

	local ScreenGo: BasePart = Screen:FindFirstChild("Go")
	if not ScreenGo then return end

	local ScreenMain: BasePart = Screen:FindFirstChild("Main")
	if not ScreenMain then return end

	local GoButtonUI: BillboardGui = ScreenGo:FindFirstChild("GoButtonUI")
	if not GoButtonUI then return end

	local NextMutationUI: BillboardGui = ScreenMain:FindFirstChild("NextMutationUI")
	if not NextMutationUI then return end
	
	return {
		Display = Display,
		CollectPart = CollectPart,
		FloatingCollectUI = FloatingCollectUI,
		Screen = Screen,
		Button = Button,
		ScreenGo = ScreenGo,
		ScreenMain = ScreenMain,
		GoButtonUI = GoButtonUI,
		NextMutationUI = NextMutationUI,
	} :: SlotsWorldPartsData
end

function PlotUtil.getPlotOwner(plot: Model) : Player?
	local plotOwnerUserId = plot:GetAttribute("OwnerUserId")
	if not plotOwnerUserId then return end
	
	local plotOwner = Players:GetPlayerByUserId(plotOwnerUserId)
	if not plotOwner then return end
	
	return plotOwner
end

function PlotUtil.getPlotOwnerFromSlot(slot: Model) : Player?
	local plot = slot.Parent.Parent
	if not plot then return end
	
	return PlotUtil.getPlotOwner(plot)
end

function PlotUtil.getFloor(plot: Model, floorNum: number) : Model?
	return plot:FindFirstChild("Floor" .. floorNum)
end

function PlotUtil.getSlotsPlacements(slots: Folder) : Folder?
	return slots:FindFirstChild("Placements")
end

function PlotUtil.getSlotData(slot: Model): SlotWorldData
	local floor = slot.Parent.Parent
	local floorNum = tonumber(string.match(floor.Name, "%d+"))
	
	local IsOccupied = slot:GetAttribute("Occupied")
	local IsForSale = slot:GetAttribute("ForSale")
	local IsVipSlot = slot:GetAttribute("VipSlot")
	local Price = slot:GetAttribute("Price")
	local IsHatchable = slot:GetAttribute("Hatchable")
	local IsHatching = slot:GetAttribute("IsHatching")
	local IsMutatable = slot:GetAttribute("IsMutatable")
	local ReadyToBeginMutate = slot:GetAttribute("ReadyToBeginMutate")
	local ReadyToMutate = slot:GetAttribute("ReadyToMutate")
	local IsMutating = slot:GetAttribute("IsMutating")
	
	local MainStand = slot:FindFirstChild("MainStand")
	if not MainStand then return end
	
	local Main: BasePart = MainStand:FindFirstChild("Main")
	if not Main then return end
	
	-- check if a valid slot
	if IsOccupied == nil and IsForSale == nil and IsVipSlot == nil and Price == nil	 then return end
	
	return {
		SlotNum = tonumber(slot.Name),
		floorNum = floorNum,
		IsVipSlot = IsVipSlot,
		IsOccupied = IsOccupied,
		IsForSale = IsForSale,
		IsHatchable = IsHatchable,
		IsHatching = IsHatching,
		IsMutatable = IsMutatable,
		IsMutating = IsMutating,
		ReadyToBeginMutate = ReadyToBeginMutate,
		ReadyToMutate = ReadyToMutate,
		Price = Price,
		MainStand = Main,
	}
end

function PlotUtil.getSlotScreenMain(slot: Model) : Model
	local Display: BasePart = slot:FindFirstChild("Display")
	if not Display then return end

	local Screen: Model = Display:FindFirstChild("Screen")
	if not Screen then return end

	local ScreenGo: BasePart = Screen:FindFirstChild("Go")
	if not ScreenGo then return end

	local ScreenMain: BasePart = Screen:FindFirstChild("Main")
	if not ScreenMain then return end

	return ScreenMain
end

function PlotUtil.getWorldPlotData(plot: Model): WorldPlotData
	local Floor1: Model = plot:WaitForChild("Floor1")
	local Architecture: Folder = Floor1:WaitForChild("Architecture")
	local BackSurface: BasePart = Architecture:WaitForChild("BackSurface")
	local SurfaceGui: SurfaceGui = BackSurface:WaitForChild("SurfaceGui")
	local TextLabel: TextLabel = SurfaceGui:WaitForChild("TextLabel")
	
	local SpawnPart: BasePart = Floor1:WaitForChild("Spawn")
	
	local floors = plot:GetChildren()
	local floorsCount = #floors

	return {
		Initialized = plot:GetAttribute("Initialized"),
		OwnerUserId = plot:GetAttribute("OwnerUserId"),
		FloorsCount = floorsCount,
		Floors = floors,
		FrontSurfaceUITextLabel = TextLabel,
		SpawnPart = SpawnPart,
	}
end

function PlotUtil.getEggTool(model_or_name: string | Model) : Tool?
	if typeof(model_or_name) == "string" then
		model_or_name = EggTools:FindFirstChild(model_or_name)
	elseif typeof(model_or_name) == "Instance" and 
		(model_or_name:IsA("Model") or model_or_name:IsA("Tool")) then
		model_or_name = EggTools:FindFirstChild(model_or_name.Name)
	end
	return model_or_name
end

function PlotUtil.getEggModel(model_or_name: string | Model) : Model?
	if typeof(model_or_name) == "string" then
		model_or_name = Eggs:FindFirstChild(model_or_name)
	elseif typeof(model_or_name) == "Instance" and model_or_name:IsA("Model") then
		model_or_name = Eggs:FindFirstChild(model_or_name.Name)
	end
	return model_or_name
end

function PlotUtil.getHatchableTool(model_or_name: string | Model) : Tool?
	if typeof(model_or_name) == "string" then
		model_or_name = LabubuTools:FindFirstChild(model_or_name)
	elseif typeof(model_or_name) == "Instance" and 
		(model_or_name:IsA("Model") or model_or_name:IsA("Tool")) then
		model_or_name = LabubuTools:FindFirstChild(model_or_name.Name)
	end
	return model_or_name
end

function PlotUtil.getHatchableModel(model_or_name: string | Model) : Model?
	if typeof(model_or_name) == "string" then
		model_or_name = HatchableAssets:FindFirstChild(model_or_name)
	elseif typeof(model_or_name) == "Instance" and model_or_name:IsA("Model") then
		model_or_name = HatchableAssets:FindFirstChild(model_or_name.Name)
	end
	return model_or_name
end

function PlotUtil.ConvertEggModelToEggTool(eggModel: Model)
	assert(eggModel and eggModel:IsA("Model"), "Invalid egg model")
	
	local EggPart: BasePart = eggModel:FindFirstChild("EggPart")
	if not EggPart then return end

	-- Create tool
	local tool = Instance.new("Tool")
	tool.Name = eggModel.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	-- Copy model attributes to tool
	for attributeName, attributeValue in pairs(eggModel:GetAttributes()) do
		tool:SetAttribute(attributeName, attributeValue)
	end
	
	EggPart.Name = "Handle"
	
	for _, obj in pairs(eggModel:GetChildren()) do
		obj.Parent = tool
	end

	-- Make sure parts behave correctly
	for _, obj in ipairs(tool:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = false
			obj.CanCollide = false
			obj.Massless = true
		end
	end
	
	tool.PrimaryPart = EggPart
	
	eggModel:Destroy()

	return tool
end

function PlotUtil.ConvertLabubuModelToLabubuTool(labubuModel: Model)
	assert(labubuModel and labubuModel:IsA("Model"), "Invalid egg model")

	local RootPart: BasePart = labubuModel:FindFirstChild("RootPart") or labubuModel.PrimaryPart
	if not RootPart then return end

	-- Create tool
	local tool = Instance.new("Tool")
	tool.Name = labubuModel.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	-- Copy model attributes to tool
	for attributeName, attributeValue in pairs(labubuModel:GetAttributes()) do
		tool:SetAttribute(attributeName, attributeValue)
	end

	RootPart.Name = "Handle"

	for _, obj in pairs(labubuModel:GetChildren()) do
		obj.Parent = tool
	end

	-- Make sure parts behave correctly
	for _, obj in ipairs(tool:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = false
			obj.CanCollide = false
			obj.Massless = true
		end
	end

	tool.PrimaryPart = RootPart

	labubuModel:Destroy()

	return tool
end

function PlotUtil.UpdateClientPlotData(plotData: Types.PlotData)
	CachedClientPlotData = plotData
end

function PlotUtil.GetAllPlacements(plot: Model) : { Model }
	local Placements = {}
	
	for _, floor in pairs(plot:GetChildren()) do
		local Slots: Folder = floor:FindFirstChild("Slots")
		if not Slots then continue end
		
		local PlacementsFolder = Slots:FindFirstChild("Placements")
		if not PlacementsFolder then continue end
		
		Placements = mergeTables(Placements, PlacementsFolder:GetChildren())
	end
	
	return Placements
end

function PlotUtil.GetAllSlots(plot: Model) : { Model }
	local Slots = {}
	
	local SlotsOnlyTbl = {}
	
	for _, floor in pairs(plot:GetChildren()) do
		local SlotsFolder: Folder = floor:FindFirstChild("Slots")
		if not SlotsFolder then continue end
		
		for _, slot in pairs(SlotsFolder:GetChildren()) do
			if slot:IsA("Model") and slot:FindFirstChild("Button") then
				table.insert(SlotsOnlyTbl, slot)
			end
		end
	end
	
	Slots = mergeTables(Slots, SlotsOnlyTbl)
	
	return Slots
end

function PlotUtil.FindWorkingLabubuSlot(plot: Model, floor: number?) : Model?
	local Slots: { Model } = {}

	if not floor then
		Slots = PlotUtil.GetAllSlots(plot)
	else
		local floor = PlotUtil.getFloor(plot, floor)
		if not floor then return end

		for _, slot in pairs(floor:WaitForChild("Slots"):GetChildren()) do
			if slot:IsA("Model") and slot:FindFirstChild("Button") then
				table.insert(Slots, slot)
			end
		end
	end
	
	Slots = shuffleTable(Slots)

	for _, slot in pairs(Slots) do
		local Placements = slot.Parent:WaitForChild("Placements")
		
		local slotPlacement = PlotUtil.getPlacementFromIndex(Placements,
			tonumber(slot.Name)
		)
		if not slotPlacement then continue end
		
		if slot:GetAttribute("Occupied") and not slot:GetAttribute("ForSale") 
			and slotPlacement:GetAttribute("Type") == "Labubu" and not slotPlacement:GetAttribute("IsMutating")
		then
			local floorNum = tonumber(string.match(slot.Parent.Parent.Name, "%d+"))
			
			return slot, floorNum
		end
	end
end

function PlotUtil.FindEmptySlotAvailable(plot: Model, floor: number?) : Model?
	local Slots: { Model } = {}
	
	if not floor then
		Slots = PlotUtil.GetAllSlots(plot)
	else
		local floor = PlotUtil.getFloor(plot, floor)
		if not floor then return end
		
		for _, slot in pairs(floor:WaitForChild("Slots"):GetChildren()) do
			if slot:IsA("Model") and slot:FindFirstChild("Button") then
				table.insert(Slots, slot)
			end
		end
	end
	
	for _, slot in pairs(Slots) do
		if not slot:GetAttribute("Occupied") and not slot:GetAttribute("ForSale") then
			local floorNum = tonumber(string.match(slot.Parent.Parent.Name, "%d+"))
			
			return slot, floorNum
		end
	end
end

function PlotUtil.LabubuPlacementFilterBy(placements: { Model }, rarity: string?, mutation: string?)
	: ( { Model }?, number )
	-- Mutation Tier: placement:GetAttribute("MutationTier")
	-- Mutation Rarity: placement:GetAttribute("EggType")
	
	-- Common to Basic: old placements may still have EggRarity="Basic"
	local FilteredPlacements = {}
	
	for _, placement in pairs(placements) do
		if rarity and placement:GetAttribute("EggRarity") ~= rarity then continue end
		if mutation and placement:GetAttribute("MutationTier") ~=
			PlotUtil.MutationNameToTier(mutation) then continue end
		
		table.insert(FilteredPlacements, placement)
	end
	
	return FilteredPlacements, #FilteredPlacements
end

function PlotUtil.GetRarity(data: Types.Labubu | Types.Egg) : (string, Color3)
	if data.Type == "Block" then
		local Rarity = data.Rarity or PlotUtil.EggsData[data.Name].Rarity
		
		return Rarity, RarityTextColors[Rarity]
	elseif data.Type == "Labubu" then
		return data.EggRarity, RarityTextColors[data.EggRarity]
	end
end

function PlotUtil.CalculateCost(data: Types.Labubu | Types.Egg) : (number?, number?)
	if data.Type == "Block" then
		local name = data.Name
		local info: EggMutationInfo = EggsMutation[name]
		if not info then
			info = EggsMutation[name:split(" ")[1]]
		end

		if not info then
			error(("Invalid mutation tier: %s"):format(name))
		end
		
		local MutationTier = data.EggMutationTier or 1
		local MutationName = PlotUtil.MutationTierToName(MutationTier)
		
		local Cost = info.Mutations[MutationName].Cost
		
		return math.floor(Cost), 
			math.floor(Cost * (GlobalSettings.SellerPricePercentage / 100))
	elseif data.Type == "Labubu" then
		local EggData = PlotUtil.EggsData[data.EggType .. " Block"]
		local BaseEggPrice = EggData.Price
		
		local LabubuMutationTier = data.MutationTier
		local LabubuMutation = PlotUtil.MutationTierToName(LabubuMutationTier)
		
		local MutationTierInfo = PlotUtil.getMutationInfo(LabubuMutation)
		
		local CostMultiplier = MutationTierInfo.CostMultiplier or 1
		
		local Traits = PlotUtil.getLabubuTraits(data)
		for name, trait in pairs(Traits) do
			local TraitData = PlotUtil.getTraitData(name)
			CostMultiplier += (TraitData.CashBonus - 1)
		end
		
		local Cost = BaseEggPrice * CostMultiplier
		
		return math.floor(Cost), math.floor(Cost * (GlobalSettings.SellerPricePercentage / 100))
	end
end

function PlotUtil.CalculateCPS(labubu: Types.Labubu, boostMulti: number?)
	boostMulti = boostMulti or 1
	
	local MutationName = PlotUtil.MutationTierToName(labubu.MutationTier)
	if not MutationName then return end
	
	local MutationTierInfo = PlotUtil.getMutationInfo(MutationName)
	if not MutationTierInfo then return end
	
	local Traits = PlotUtil.getLabubuTraits(labubu)
	for name, trait in pairs(Traits) do
		local TraitData = PlotUtil.getTraitData(name)
		boostMulti += (TraitData.CashBonus - 1)
	end
	
	return math.floor(labubu.BaseCPS * MutationTierInfo.Multiplier * boostMulti)
end

function PlotUtil.CalculateCPSbyName(labubuName: string, mutation: string, boostMulti: number?, traits: any?)
	boostMulti = boostMulti or 1
	
	local MutationTierInfo = PlotUtil.getMutationInfo(mutation)
	if not MutationTierInfo then return end
	
	local LabubuData = PlotUtil.getLabubuData(labubuName)
	if not LabubuData then return end
	
	if traits then
		for name, trait in pairs(traits) do
			local TraitData = PlotUtil.getTraitData(name)
			boostMulti += (TraitData.CashBonus - 1)
		end
	end

	return math.floor(LabubuData.CPS * MutationTierInfo.Multiplier * boostMulti)
end

export type MutationInfo = {
	CurrentMutationName: string,
	NextMutationName: string?,
	FailureMutationName: string,
	
	CurrentMutationTier: number,
	NextMutationTier: number?,
	PrevMutationTier: number?,

	CurrentMutationCPS: number,
	NextMutationCPS: number?,
	FailureMutationCPS: number,

	Cost: number,
	MutationTime: number,
	NextMutationTime: number,
	PrevMutationTime: number,

	SuccessRate: number,
	FailureRate: number,
}

function PlotUtil.UpdateMutationInfoUI(mutationData: MutationInfo)
	local playerGui = LocalPlayer.PlayerGui
	if not playerGui then return end
	
	local Tabs = playerGui:FindFirstChild("Tabs")
	if not Tabs then return end
	
	local MutationInfo = Tabs:FindFirstChild("MutationInfo")
	if not MutationInfo then return end
	
	local Container = MutationInfo:FindFirstChild("Container")
	if not Container then return end
	
	local SuccessChance: TextLabel = Container:FindFirstChild("SuccessChance")
	local FailChance: TextLabel = Container:FindFirstChild("FailChance")
	local MutationTime: TextLabel = Container:FindFirstChild("MutationTime")
	if not SuccessChance or not FailChance or not MutationTime then return end
	
	local FailItemFrame = Container:FindFirstChild("FailItem")
	if not FailItemFrame then return end
	
	local OriginalItemFrame = Container:FindFirstChild("OriginalItem")
	if not OriginalItemFrame then return end
	
	local SuccessItemFrame = Container:FindFirstChild("SuccessItem")
	if not SuccessItemFrame then return end
	
	local Buttons = Container:FindFirstChild("Buttons")
	if not Buttons then return end
	
	local OkButton = Buttons:FindFirstChild("Ok")
	if not OkButton then return end
	
	OriginalItemFrame.NameLabel.Text = mutationData.CurrentMutationName
	OriginalItemFrame.NameLabel.TextColor3 = MutationTextColors[mutationData.CurrentMutationName]
	OriginalItemFrame.CPSLabel.Text = 
		"$" .. formatCommaValue(mutationData.CurrentMutationCPS) .. "/s"

	SuccessItemFrame.NameLabel.Text = mutationData.NextMutationName
	SuccessItemFrame.NameLabel.TextColor3 = MutationTextColors[mutationData.NextMutationName]
	SuccessItemFrame.CPSLabel.Text = 
		"$" .. formatCommaValue(mutationData.NextMutationCPS) .. "/s"
	
	FailItemFrame.NameLabel.Text = mutationData.FailureMutationName
	FailItemFrame.NameLabel.TextColor3 = MutationTextColors[mutationData.FailureMutationName]
	FailItemFrame.CPSLabel.Text = 
		"$" .. formatCommaValue(mutationData.FailureMutationCPS) .. "/s"
	
	MutationTime.Text = `Mutation time: {TimeFormat.formatDuration(mutationData.MutationTime)}`
	
	SuccessChance.Text = mutationData.SuccessRate .. "%"
	FailChance.Text = mutationData.FailureRate .. "%"
	
	OkButton.Text = "$" .. formatCommaValue(mutationData.Cost)
end

function PlotUtil.GetMutationExtraInfo(labubu: Types.Labubu) : MutationInfo
	local MutationName = PlotUtil.MutationTierToName(labubu.MutationTier)
	if not MutationName then return end

	local MutationTierInfo = PlotUtil.getMutationInfo(MutationName)
	if not MutationTierInfo then return end


	local NextMutationTier = labubu.MutationTier + 1
	local NextMutationName = PlotUtil.MutationTierToName(NextMutationTier)

	local NextMutationTierInfo = NextMutationName
		and PlotUtil.getMutationInfo(NextMutationName)

	local EggMutationData = PlotUtil.getEggMutationInfo(labubu.EggType)
	if not EggMutationData then return end

	local EggMutationInfo = EggMutationData.Mutations[MutationName]
	if not EggMutationInfo then return end
	
	local SuccessRate = MutationTierInfo.SuccessRateNext
	local FailureRate = 0
	
	FailureRate = SuccessRate and 100 - SuccessRate or 0
	
	local PrevMutationTier = labubu.MutationTier - 1
	local PrevMutationName = PlotUtil.MutationTierToName(PrevMutationTier)

	local PrevMutationTierInfo = PrevMutationName
		and PlotUtil.getMutationInfo(PrevMutationName)
	
	return {
		CurrentMutationName = MutationName,
		NextMutationName = NextMutationName,
		FailureMutationName = MutationTierInfo.FailureDowngrade,
		
		CurrentMutationTier = labubu.MutationTier,
		NextMutationTier = NextMutationTierInfo and NextMutationTierInfo.Tier,
		PrevMutationTier = PrevMutationTierInfo and PrevMutationTierInfo.Tier,
		
		CurrentMutationCPS = PlotUtil.CalculateCPSbyName(labubu.Name, MutationName, nil, labubu.Traits),
		NextMutationCPS = PlotUtil.CalculateCPSbyName(labubu.Name, NextMutationName, nil, labubu.Traits),
		FailureMutationCPS = PlotUtil.CalculateCPSbyName(labubu.Name, 
			MutationTierInfo.FailureDowngrade, nil, labubu.Traits),
		
		Cost = EggMutationInfo.Cost,
		MutationTime = MutationTierInfo.MutationTime,
		NextMutationTime = NextMutationTierInfo and NextMutationTierInfo.MutationTime,
		PrevMutationTime = PrevMutationTierInfo and PrevMutationTierInfo.MutationTime,
		
		SuccessRate = SuccessRate,
		FailureRate = FailureRate
	}
end

function PlotUtil.SetClientSpin(plot: Model)
	if not plot or not plot.Parent then return end
	if not CachedClientPlotData then return end
	
	local Dropper: Folder? = PlotUtil.getPlotDropper(plot)
	if not Dropper then return end

	local SpinScreen: Model?, 
	Button: BasePart?, 
	GoButtonUI: BillboardGui?, BarUI: BillboardGui? = PlotUtil.getDropperSpinScreen(Dropper)

	if not SpinScreen or not Button or not GoButtonUI or not BarUI then return end
	
	local EggPillars: { Model } = PlotUtil.getEggPillars(Dropper)
	if not EggPillars then return end

	GoButtonUI.Enabled = CachedClientPlotData.SpinInfo.CanSpin
	BarUI.Enabled = CachedClientPlotData.SpinInfo.SpinBroken
	
	local ScreenGoClick: ClickDetector = Button:FindFirstChild("ClickDetector")

	if not ScreenGoClick then
		local RepairProximityPrompt: ProximityPrompt = Button:FindFirstChild("ProximityPrompt")
			:: ProximityPrompt

		if not RepairProximityPrompt then
			local NewRepairProximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
			NewRepairProximityPrompt.ActionText = "Repair Button"
			NewRepairProximityPrompt.RequiresLineOfSight = false
			NewRepairProximityPrompt.MaxActivationDistance = 15
			NewRepairProximityPrompt.Enabled = false
			NewRepairProximityPrompt.Parent = Button

			NewRepairProximityPrompt.Triggered:Connect(function(player: Player)
				if player ~= LocalPlayer then return end
				if not plot:GetAttribute("Initialized") then return end
				if CachedClientPlotData.SpinInfo.CanSpin then return end
				if not BarUI.Enabled then return end
				
				if not ButtonRatelimit:Try() then return end

				ClickSound:Play()
				
				PromptUtil.promptProduct(
					RepairProduct,
					true
				)
			end)
			
			RepairProximityPrompt = NewRepairProximityPrompt
		end

		
		local function UpdateBarUI()
			RepairProximityPrompt.Enabled = BarUI.Enabled
			
			if not BarUI.Enabled then 
				return 
			end
			local TimerText: TextLabel = BarUI:FindFirstChild("TimerText")
			if not TimerText then return end
			local Container: Frame = BarUI:FindFirstChild("Container")
			if not Container then return end
			local FillBar: Frame = Container:FindFirstChild("FillBar")
			if not FillBar then return end
			
			FillBar.BackgroundColor3 = Color3.fromRGB(255, 0, 4)
			FillBar.Size = UDim2.new(1, 0, 1, 0)
			task.spawn(function()
				while true do
					if not BarUI.Enabled then break end
					
					local SpinCooldown: number = CachedClientPlotData.SpinInfo.SpinCooldown
					local Remaining: number = SpinCooldown - getUTCtime()

					if Remaining <= 0 then break end

					TimerText.Text = "Broken for: " .. TimeFormat.formatDuration(Remaining)
					
					local BarSizeX = math.clamp(Remaining / GlobalSettings.BreakForSeconds, 0, 1)
					FillBar.Size = UDim2.new(BarSizeX, 0, 1, 0)

					task.wait(1)
				end
			end)
		end
		
		BarUI:GetPropertyChangedSignal("Enabled"):Connect(function()
			UpdateBarUI()
		end)
		
		UpdateBarUI()
		
		local NewScreenGoClick: ClickDetector = Instance.new("ClickDetector")

		ScreenGoClick = NewScreenGoClick
		
		ScreenGoClick.MouseClick:Connect(function(player: Player)
			if player ~= LocalPlayer then return end
			if not plot:GetAttribute("Initialized") then return end
			if not CachedClientPlotData.SpinInfo.CanSpin then return end
			
			if not ButtonRatelimit:Try() then return end
			
			ClickSound:Play()

			Network.Plots.EggRoll:FireServer()
		end)

		local Highlight: Highlight? = nil :: Highlight

		ScreenGoClick.MouseHoverEnter:Connect(function(player: Player)
			if player ~= LocalPlayer then return end
			if not plot:GetAttribute("Initialized") then return end
			if not CachedClientPlotData.SpinInfo.CanSpin then return end

			if not Highlight then
				Highlight = Instance.new("Highlight")
				Highlight.FillColor = Color3.fromRGB(255, 255, 255)
				Highlight.FillTransparency = 0.9
				Highlight.Parent = Button
			end
			
			HoverSound:Play()
		end)

		ScreenGoClick.MouseHoverLeave:Connect(function(player: Player)
			if player ~= LocalPlayer then return end

			if Highlight then
				Highlight:Destroy()
				Highlight = nil
			end
		end)
		
		
		-- Eggs ProximityPrompt
		local EggRolls: Folder = PlotUtil.getDropperEggsFolder(Dropper)
		if EggRolls then
			local function SetupEggRollProximityPrompt(egg: Model)
				if not egg.Parent then return end
				
				local eggRollTrove = Trove.new()
				
				local EggRollProximityPrompt: ProximityPrompt = egg:FindFirstChild("EggRollProximityPrompt")
				
				if not EggRollProximityPrompt then
					local NewEggRollProximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
					NewEggRollProximityPrompt.RequiresLineOfSight = false
					NewEggRollProximityPrompt.MaxActivationDistance = 10
					NewEggRollProximityPrompt.HoldDuration = 0.25
					NewEggRollProximityPrompt.ActionText = "Buy Egg"
					
					eggRollTrove:Add(
						NewEggRollProximityPrompt.Triggered:Connect(function(player: Player)
							if player ~= LocalPlayer then return end
							if not plot:GetAttribute("Initialized") then return end
							if not ButtonRatelimit:Try() then return end
							
							local ParentIndex: number? = egg:GetAttribute("ParentIndex")
							if not ParentIndex then return end
						
							local eggPillar: Model? = PlotUtil.getEggPillarFromIndex(
								EggPillars, ParentIndex
							)
							if not eggPillar then return end
						
							ClickSound:Play()
							
							Network.Plots.BuyEggRoll:FireServer(egg.Name, ParentIndex)
						end)
					)
					
					EggRollProximityPrompt = NewEggRollProximityPrompt
					EggRollProximityPrompt.Parent = egg
				end
				
				eggRollTrove:AttachToInstance(egg)
			end
			
			EggRolls.ChildAdded:Connect(function(egg: Model)
				SetupEggRollProximityPrompt(egg)
			end)			

			for _, egg in ipairs(EggRolls:GetChildren()) do
				SetupEggRollProximityPrompt(egg)
			end
		end
	end
	
	if not CachedClientPlotData.SpinInfo.CanSpin then 
		local Highlight: Highlight = Button:FindFirstChild("Highlight")
		if Highlight then
			Highlight:Destroy()
		end
	end
	
	if ScreenGoClick then
		ScreenGoClick.MaxActivationDistance = CachedClientPlotData.SpinInfo.CanSpin and 25 or 0
		ScreenGoClick.Parent = Button
	end
end

local MutationInfoTabCache = {
	Placement = nil,
	FloorNum = nil,
	SlotNum = nil,
}

function PlotUtil.initClientPlot(plot: Model)
	if not plot or not plot.Parent then return end
	
	if CurrentlyInitializingPlotClient then
		repeat 
			warn("Waiting for other plot init to complete")
			task.wait() 
		until not CurrentlyInitializingPlotClient
	end
	CurrentlyInitializingPlotClient = true
	
	if not ClientInitialized then
		constantTrove:Clean()
		
		local function SetupFloor(floor)
			local floorNum = tonumber(string.match(floor.Name, "%d+"))

			local Slots: Folder = floor:FindFirstChild("Slots")
			if not Slots then return end

			constantTrove:Add(
				Slots.ChildAdded:Connect(function(slot: Model)
					local Button: Model = slot:FindFirstChild("Button")
					if not Button then return end

					PlotUtil.initClientPlot(plot)
				end)
			)
		end
		
		constantTrove:Add(
			plot.ChildAdded:Connect(function(floor: Model)
				SetupFloor(floor)
				PlotUtil.initClientPlot(plot)
			end)
		)
		
		for _, floor in ipairs(plot:GetChildren()) do
			SetupFloor(floor)
		end
		
		-- MutationInfo Ok Button
		local function InitMutationInfo()
			local playerGui = LocalPlayer.PlayerGui
			if not playerGui then return end

			local Tabs = playerGui:FindFirstChild("Tabs")
			if not Tabs then return end

			local MutationInfo = Tabs:FindFirstChild("MutationInfo")
			if not MutationInfo then return end

			local Container = MutationInfo:FindFirstChild("Container")
			if not Container then return end

			local SuccessChance: TextLabel = Container:FindFirstChild("SuccessChance")
			local FailChance: TextLabel = Container:FindFirstChild("FailChance")
			local MutationTime: TextLabel = Container:FindFirstChild("MutationTime")
			if not SuccessChance or not FailChance or not MutationTime then return end

			local FailItemFrame = Container:FindFirstChild("FailItem")
			if not FailItemFrame then return end

			local OriginalItemFrame = Container:FindFirstChild("OriginalItem")
			if not OriginalItemFrame then return end

			local SuccessItemFrame = Container:FindFirstChild("SuccessItem")
			if not SuccessItemFrame then return end

			local Buttons = Container:FindFirstChild("Buttons")
			if not Buttons then return end

			local OkButton = Buttons:FindFirstChild("Ok")
			if not OkButton then return end
			
			OkButton.Activated:Connect(function()
				if not plot:GetAttribute("Initialized") then return end

				if not ButtonRatelimit:Try() then return end
				
				Network.Plots.Mutate:FireServer(MutationInfoTabCache.Placement.Name, 
					MutationInfoTabCache.FloorNum, MutationInfoTabCache.SlotNum)
				
				InterfaceTabUtil.closeAllTabs(true)
			end)
		end
		
		InitMutationInfo()
	end
	
	ClientInitialized = true

	slotTrove:Clean()
	
	for _, floor in ipairs(plot:GetChildren()) do
		local floorNum = tonumber(string.match(floor.Name, "%d+"))

		local Slots: Folder = floor:FindFirstChild("Slots")
		if not Slots then continue end
		
		local Placements: Folder = PlotUtil.getSlotsPlacements(Slots)
		if not Placements then continue end

		for _, slot in ipairs(Slots:GetChildren()) do
			local Button: Model = slot:FindFirstChild("Button")
			if not Button then continue end
			
			local slotNum = tonumber(slot.Name)

			local SlotWorldPartsData = PlotUtil.getSlotWorldData(slot)
			if not SlotWorldPartsData then continue end

			local CollectPart: BasePart = SlotWorldPartsData.CollectPart
			if not CollectPart then continue end

			local FloatingCollectUI: BillboardGui = SlotWorldPartsData.FloatingCollectUI
			if not FloatingCollectUI then continue end

			local Display: BasePart = SlotWorldPartsData.Display
			if not Display then continue end

			local Screen: Model = SlotWorldPartsData.Screen
			if not Screen then continue end

			local ScreenGo: BasePart = SlotWorldPartsData.ScreenGo
			if not ScreenGo then continue end

			local ScreenMain: BasePart = SlotWorldPartsData.ScreenMain
			if not ScreenMain then continue end

			local GoButtonUI: BillboardGui = SlotWorldPartsData.GoButtonUI
			if not GoButtonUI then continue end

			local NextMutationUI: BillboardGui = SlotWorldPartsData.NextMutationUI
			if not NextMutationUI then continue end
			
			local function ResetCachedStuff()
				local ScreenGoClick: ClickDetector = ScreenGo:FindFirstChild("ClickDetector")

				if ScreenGoClick then
					ScreenGoClick:Destroy()
				end

				local Highlight: Highlight = ScreenGo:FindFirstChild("Highlight")
				if Highlight then
					Highlight:Destroy()
				end
				
				if MutationInfoTabCache then
					if MutationInfoTabCache.SlotNum == slotNum then
						if MutationInfoTabCache.FloorNum == floorNum then
							if InterfaceTabUtil.isTabOpen("MutationInfo") then
								InterfaceTabUtil.closeAllTabs()
							end
						end
					end
				end
			end

			slotTrove:Add(slot:GetAttributeChangedSignal("ForSale"):Connect(
				function()
					ResetCachedStuff()
					PlotUtil.initClientPlot(plot)
				end)
			)

			slotTrove:Add(slot:GetAttributeChangedSignal("Hatchable"):Connect(
				function()
					ResetCachedStuff()
					PlotUtil.initClientPlot(plot)
				end)
			)

			slotTrove:Add(slot:GetAttributeChangedSignal("IsHatching"):Connect(
				function()
					ResetCachedStuff()
					PlotUtil.initClientPlot(plot)
				end)
			)
			
			slotTrove:Add(slot:GetAttributeChangedSignal("IsMutatable"):Connect(
				function()
					ResetCachedStuff()
					PlotUtil.initClientPlot(plot)
				end)
			)
			
			slotTrove:Add(slot:GetAttributeChangedSignal("ReadyToBeginMutate"):Connect(
				function()
					ResetCachedStuff()
					PlotUtil.initClientPlot(plot)
				end)
			)
			
			slotTrove:Add(slot:GetAttributeChangedSignal("ReadyToMutate"):Connect(
				function()
					ResetCachedStuff()
					PlotUtil.initClientPlot(plot)
				end)
			)
			
			slotTrove:Add(slot:GetAttributeChangedSignal("IsMutating"):Connect(
				function()
					ResetCachedStuff()
					PlotUtil.initClientPlot(plot)
				end)
			)

			local PriceAttribute = slot:GetAttribute("Price")
			local IsVipSlot: boolean? = slot:GetAttribute("VipSlot")
			local IsSlotForSale: boolean? = slot:GetAttribute("ForSale")
			local IsSlotOccupied: boolean? = slot:GetAttribute("Occupied")
			local IsHatchable: boolean? = slot:GetAttribute("Hatchable")
			local IsHatching: boolean? = slot:GetAttribute("IsHatching")
			local IsMutatable: boolean? = slot:GetAttribute("IsMutatable")
			local ReadyToBeginMutate: boolean? = slot:GetAttribute("ReadyToBeginMutate")
			local ReadyToMutate: boolean? = slot:GetAttribute("ReadyToMutate")
			local IsMutating: boolean? = slot:GetAttribute("IsMutating")

			local ProximityPrompt: ProximityPrompt = CollectPart:FindFirstChild("BuySlotProximityPrompt")
			if not ProximityPrompt then
				local NewProximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
				if not IsVipSlot then
					NewProximityPrompt.ActionText = "Buy Slot"
				else
					NewProximityPrompt.ActionText = "Buy Vip Slot"
				end
				
				local PriceAttribute = formatCommaValue(PriceAttribute)
				local BuyVIPSlotPrice = formatCommaValue(BuyVIPSlotPrice)
				
				NewProximityPrompt.ObjectText =
					"Slot " .. slotNum .. " | " ..
					(IsVipSlot and ("R$" .. BuyVIPSlotPrice) or ("$" .. PriceAttribute))
				NewProximityPrompt.RequiresLineOfSight = false
				NewProximityPrompt.Name = "BuySlotProximityPrompt"
				NewProximityPrompt.HoldDuration = 0.5
				NewProximityPrompt.Enabled = false
				NewProximityPrompt.Parent = CollectPart

				ProximityPrompt = NewProximityPrompt
			end

			if IsSlotForSale then
				ProximityPrompt.Enabled = true
			else
				ProximityPrompt.Enabled = false
			end
			
			if IsHatching or IsMutating then
				GoButtonUI.Background.Frame.GoText.Text = "SKIP"
			else
				GoButtonUI.Background.Frame.GoText.Text = "GO"
			end
		
			FloatingCollectUI.Enabled = IsMutatable
			--FloatingCollectUI.Enabled = IsMutatable and 
			--	(not IsMutating and not ReadyToMutate)
			
			local Placement = PlotUtil.getPlacementFromIndex(
				Placements, slotNum
			)
			
			local PlacementAndPlacementMutatinTierNotDefault = Placement and 
				Placement:GetAttribute("MutationTier") and
				Placement:GetAttribute("MutationTier") > 1
			
			if not IsSlotForSale and IsSlotOccupied and 
				(IsHatchable or IsHatching or ReadyToBeginMutate or 
					(ReadyToMutate or (IsMutating and PlacementAndPlacementMutatinTierNotDefault))
				) then
				local ScreenGoClick: ClickDetector = ScreenGo:FindFirstChild("ClickDetector")
				
				if not ScreenGoClick then
					local NewScreenGoClick: ClickDetector = Instance.new("ClickDetector")
					NewScreenGoClick.MaxActivationDistance = 25
					NewScreenGoClick.Parent = ScreenGo
					
					ScreenGoClick = NewScreenGoClick
				end
				
				slotTrove:Add(Placements.ChildAdded:Connect(
					function()
						ResetCachedStuff()
						PlotUtil.initClientPlot(plot)
					end)
				)

				slotTrove:Add(Placements.ChildRemoved:Connect(
					function()
						ResetCachedStuff()
						PlotUtil.initClientPlot(plot)
					end)
				)
				
				slotTrove:Add(
					ScreenGoClick.MouseClick:Connect(function(player: Player)
						if player ~= LocalPlayer then return end
						if not plot:GetAttribute("Initialized") then return end
						
						if not ButtonRatelimit:Try() then return end
						
						if IsHatchable then
							if Placement then
								Network.Plots.HatchEgg:FireServer(Placement.Name, floorNum, slotNum)
								
								ClickSound:Play()
							end
						else
							if IsHatching then
								Network.Plots.SkipEggHatch:FireServer(floorNum, slotNum)
								
								ClickSound:Play()
							end
							
							if ReadyToBeginMutate then
								if Placement then
									local Attributes = Placement:GetAttributes()
						
									local MutationInfo = PlotUtil.GetMutationExtraInfo(Attributes)
									
									PlotUtil.UpdateMutationInfoUI(
										MutationInfo
									)
									
									MutationInfoTabCache.Placement = Placement
									MutationInfoTabCache.SlotNum = slotNum
									MutationInfoTabCache.FloorNum = floorNum
									
									InterfaceTabUtil.openTab("MutationInfo", true)
								end
							else
								if ReadyToMutate then
									if Placement then
										Network.Plots.RevealMutation:FireServer(
											Placement.Name, floorNum, slotNum
										)
										
										ClickSound:Play()
									end
								else
									if IsMutating then
										if Placement then
											Network.Plots.SkipMutation:FireServer(
												Placement.Name, floorNum, slotNum
											)

											ClickSound:Play()
										end
									end
								end
							end
						end
					end)
				)
				
				local Highlight: Highlight? = nil
				
				slotTrove:Add(
					ScreenGoClick.MouseHoverEnter:Connect(function(player: Player)
						if player ~= LocalPlayer then return end
						if not plot:GetAttribute("Initialized") then return end

						if not Highlight then
							Highlight = Instance.new("Highlight")
							Highlight.FillColor = Color3.fromRGB(255, 255, 255)
							Highlight.FillTransparency = 0.9
							Highlight.Parent = ScreenGo
						end
						
						HoverSound:Play()
					end)
				)
				
				slotTrove:Add(
					ScreenGoClick.MouseHoverLeave:Connect(function(player: Player)
						if player ~= LocalPlayer then return end

						if Highlight then
							Highlight:Destroy()
							Highlight = nil
						end
					end)
				)
				
				slotTrove:Add(
					ScreenGoClick.Destroying:Connect(function()
						if Highlight then
							Highlight:Destroy()
							Highlight = nil
						end
					end)
				)
				
				GoButtonUI.Enabled = true
			else
				ResetCachedStuff()
				
				GoButtonUI.Enabled = false
			end
			
			if ProximityPrompt.Enabled then
				slotTrove:Add(
					ProximityPrompt.Triggered:Connect(function(player: Player)
						if player ~= LocalPlayer then return end
						if not plot:GetAttribute("Initialized") then return end
						
						--warn("Trigger Buy Slot:" .. slotNum, floorNum)
						Network.Plots.BuySlot:FireServer(floorNum, slotNum)
					end)
				)
			end
		end
	end
	
	CurrentlyInitializingPlotClient = false
end

return PlotUtil