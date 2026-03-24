local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)

local TutorialBeam = ReplicatedStorage.Assets.Beams.TutorialBeam

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local TutorialText = playerGui.HUD.Top.Tutorial

local trove = Trove.new()
local ShowTutorial: boolean = false
local TutBeam: Instance? = nil :: Beam

local Tutorial = {}

function Tutorial.init()
	-- Once initialized, this gets called

	local function checkEligibility(new: number, cash: number?)
		local new = (new ~= nil and new) or ClientData.HasCompletedTutorial()
		if new == false then
			-- Show Tutorial
			
			ShowTutorial = true
		elseif new == true then
			-- Hide Tutorial
			
			ShowTutorial = false
			TutorialText.Visible = false
			
			if TutBeam then
				Notification.Success("Tutorial Complete.")
				
				if (TutBeam and TutBeam.Parent) then
					TutBeam:Destroy()
				end
				TutBeam = nil
			end
		end
	end

	-- Listen to Value Changes
	trove:Add(
		Charm.subscribe(ClientData.HasCompletedTutorial, checkEligibility)
	)

	checkEligibility(ClientData.HasCompletedTutorial())
end

local function SetupTutorialBeam(HRP, Target)
	-- Reuse existing beam if possible, otherwise clone a new one
	TutBeam = (TutBeam and TutBeam.Parent) and TutBeam or TutorialBeam:Clone()

	-- Attachment on player (HRP)
	TutBeam.Attachment1 = HRP:FindFirstChild("RootAttachment")
		or HRP:FindFirstChildOfClass("Attachment")
		or Instance.new("Attachment", HRP)

	-- Attachment on monster root (create if missing)
	local attachment = Target:FindFirstChildOfClass("Attachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Parent = Target
	end
	TutBeam.Attachment0 = attachment
	
	TutBeam.Parent = workspace.Cache

	return TutBeam
end

local HasBeenNotifiedYet: boolean = false

local Steps = {
	-- Mutation
	[1] = function(hrp)
		local HasEverMutated = ClientData.Mutations() > 0
		if HasEverMutated then
			Network.Tutorial.Progress:FireServer(2)
			
			return
		end
		
		TutorialText.Text = "Mutate the Labubu"
		
		local function FindASlotLabubu()
			local Plot = ClientData.Plot()
			local Slots = Plot:WaitForChild("Floor1")
				:WaitForChild("Slots")
			local Placements = Slots:WaitForChild("Placements")
			
			for _, Placement in Placements:GetChildren() do
				if Placement:GetAttribute("Type") == "Labubu" and 
					not Placement:GetAttribute("IsMutating")
				then
					local ParentIndex = Placement:GetAttribute("ParentIndex")
					if not ParentIndex then continue end
					
					local Slot = Slots:FindFirstChild(ParentIndex)
					if not Slot then continue end
					
					return Slot:WaitForChild("Display"):WaitForChild("Screen")
						:WaitForChild("Go")
				end
			end
		end
		
		local ClosestTarget = FindASlotLabubu()
		if ClosestTarget then
			SetupTutorialBeam(hrp, ClosestTarget)
			
			return true
		end
	end,
	
	-- Egg Roll
	[2] = function(hrp)
		local PlotData = ClientData.PlotData()
		
		if not PlotData then return end
		
		if PlotData.SpinInfo.SpinsCount > 0 then
			Network.Tutorial.Progress:FireServer(3)
			
			return
		end
		
		local Plot = ClientData.Plot()
		if not Plot then return end
		local dropper = PlotUtil.getPlotDropper(Plot)
		if not dropper then return end
		
		local Screen, Button, GoButtonUI, BarUI = PlotUtil.getDropperSpinScreen(dropper)
		if not Screen or not Button then return end
		
		TutorialText.Text = "Roll for eggs"
		SetupTutorialBeam(hrp, Button)
		
		return true
	end,
	
	-- Mutation
	[3] = function(hrp)
		local EggsReceived = ClientData.EggsReceived() > 0
		if EggsReceived then
			Network.Tutorial.Progress:FireServer(4)

			return
		end

		TutorialText.Text = "Buy an Egg"

		local function FindAEggRoll()
			local Plot = ClientData.Plot()
			local Dropper = Plot:WaitForChild("Floor1")
				:WaitForChild("Dropper")
			local Placements = Dropper:WaitForChild("EggRolls")
			local eggPillars = PlotUtil.getEggPillars(Dropper)

			local function getCheapestPlacement(Placements, eggPillars)
				local cheapestPlacement = nil
				local cheapestPrice = math.huge

				for _, Placement in Placements:GetChildren() do
					local ParentIndex = Placement:GetAttribute("ParentIndex")
					if not ParentIndex then continue end

					local eggPillar = PlotUtil.getEggPillarFromIndex(eggPillars, ParentIndex)
					if not eggPillar then continue end
					if eggPillar:GetAttribute("Premium") then continue end

					local eggInfo = PlotUtil.EggsData[Placement.Name]
					if not eggInfo then continue end

					local price = eggInfo.Price
					if typeof(price) ~= "number" then continue end

					if price < cheapestPrice then
						cheapestPrice = price
						cheapestPlacement = Placement
					end
				end

				return cheapestPlacement, cheapestPrice
			end
			
			local placement, price = getCheapestPlacement(Placements, eggPillars)

			return placement
		end

		local ClosestTarget = FindAEggRoll()
		if ClosestTarget then
			SetupTutorialBeam(hrp, ClosestTarget)
			
			return true
		end
	end,
	
	-- Place Egg
	[4] = function(hrp)
		local EggsPlaced = ClientData.EggsPlaced() > 0
		if EggsPlaced then
			Network.Tutorial.Progress:FireServer(5)

			return
		end
		
		TutorialText.Text = "Place Egg At An Empty Slot"
		
		local Plot = ClientData.Plot()
		
		local GetEmptySlot = PlotUtil.FindEmptySlotAvailable(Plot)
		if GetEmptySlot then
			SetupTutorialBeam(hrp, GetEmptySlot:WaitForChild("MainStand"):WaitForChild("Main"))
			
			return true
		end
	end,
	
	-- Hatch Egg
	[5] = function(hrp)
		local HasEverHatched = ClientData.EggsHatched() > 0
		if HasEverHatched then
			Network.Tutorial.Progress:FireServer(6, true)

			return
		end

		TutorialText.Text = "Hatch Egg"

		local function FindASlotEgg()
			local Plot = ClientData.Plot()
			local Slots = Plot:WaitForChild("Floor1")
				:WaitForChild("Slots")
			local Placements = Slots:WaitForChild("Placements")

			for _, Placement in Placements:GetChildren() do
				if Placement:GetAttribute("Type") == "Egg" then
					local ParentIndex = Placement:GetAttribute("ParentIndex")
					if not ParentIndex then continue end

					local Slot = Slots:FindFirstChild(ParentIndex)
					if not Slot then continue end

					return Slot:WaitForChild("Display"):WaitForChild("Screen")
						:WaitForChild("Go")
				end
			end
		end

		local ClosestTarget = FindASlotEgg()
		if ClosestTarget then
			SetupTutorialBeam(hrp, ClosestTarget)

			return true
		end
	end,
}

local function UpdateState()
	if not ClientData.Plot() or not ClientData.PlotData() then return end
	if ClientData.HasCompletedTutorial() then return end
	
	local function Hide(isNotConfident: boolean?)
		TutorialText.Visible = isNotConfident

		if TutBeam and TutBeam.Parent then
			TutBeam.Parent = ReplicatedStorage.Cache
		end
	end
	
	local CurrentStep = ClientData.TutorialStep()
	if not CurrentStep then 
		Hide()
		return
	end

	local PlayerCharacter: Model? = localPlayer.Character
	local HRP = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")

	if not HRP then
		Hide()
		return
	end

	if ShowTutorial then
		--CurrentStep = 5
		local results = Steps[CurrentStep] and Steps[CurrentStep](HRP)

		if results then
			TutorialText.Visible = true
		else
			Hide(true)
		end
	else
		Hide()
		return true
	end
end

Charm.subscribe(ClientData.TutorialStep, UpdateState)

task.spawn(function()
	while task.wait(0.1) do
		if ClientData.Plot() and ClientData.PlotData() then break end
	end
	
	if ClientData.HasCompletedTutorial() then return end
	
	wait(1)
	
	while task.wait(1) do
		if UpdateState() then
			break
		end
	end
end)

return Tutorial