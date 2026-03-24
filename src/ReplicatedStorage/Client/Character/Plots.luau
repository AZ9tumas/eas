local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local Bases = workspace:WaitForChild("Bases")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Types = require(ReplicatedStorage.Shared.Types)

local Notification = require(ReplicatedStorage.Client.Interface.UI.Overlays.Notification)
local stringRemoveTrailingSpaces = require(ReplicatedStorage.Shared.Utility.String.stringRemoveTrailingSpaces)

local InterfaceSounds = ReplicatedStorage.Assets.Sounds.Interface
local ClickSound = InterfaceSounds.ButtonClick
local HoverSound = InterfaceSounds.ButtonHover

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local SlotsData: { { Slot: Model, Prompt: ProximityPrompt} } = {}
local LastSlotPlacementToolName: string? = nil :: string

local Plots = {}
local PlayerPlot
local PlayerPlotData

local Initialized = false

local function HandleSlotsPlacements(state: boolean, name: string?)
	if name then
		LastSlotPlacementToolName = name
	end
	
	for _, slotData in ipairs(SlotsData) do
		local Slot = slotData.Slot
		local Prompt = slotData.Prompt
		
		local getSlotData = PlotUtil.getSlotData(Slot)
		if not getSlotData then continue end
		
		if getSlotData.IsForSale or getSlotData.IsOccupied then
			Prompt.Enabled = false
			
			continue
		end
		
		if name then
			Prompt.ObjectText = name
		end
		
		Prompt.Enabled = state
	end
end

local function attachLabubuPrompt(model: Model)
	local Placements = model.Parent
	if not Placements then return end
	local SlotsFolder = Placements.Parent
	if not SlotsFolder then return end
	local FloorModel = SlotsFolder.Parent
	if not FloorModel then return end
	
	local floorNum = tonumber(string.match(FloorModel.Name, "%d+"))
	if not floorNum then return end
	
	if model:GetAttribute("Type") ~= "Labubu" then
		return
	end

	-- Pick a sensible part for the prompt
	local promptPart =
		model.PrimaryPart or model:WaitForChild("RootPart", 2)
		model:FindFirstChildWhichIsA("BasePart")

	if not promptPart then
		warn("Labubu model has no BasePart:", model:GetFullName())
		return
	end

	-- Avoid duplicates
	if promptPart:FindFirstChild("LabubuPrompt") then
		return
	end
	
	local ParentIndex = model:GetAttribute("ParentIndex")
	if not ParentIndex then return end
	local LabubuSlot = PlotUtil.getPlacementFromIndex(Placements, ParentIndex)
	if not LabubuSlot then return end
	
	local Attachment = Instance.new("Attachment")
	Attachment.Position = Vector3.new(0, -1.5, 0)
	Attachment.Name = "LabubuPromptAttachment"

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LabubuPrompt"
	prompt.ActionText = "Take"
	prompt.ObjectText = "Labubu"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	
	prompt.Parent = Attachment
	Attachment.Parent = promptPart

	local promptTrove = Trove.new()
	
	promptTrove:Add(
		model:GetPropertyChangedSignal("Parent"):Connect(function()
			Attachment:Destroy()
			promptTrove:Destroy()
		end)
	)
	
	promptTrove:Add(
		model:GetAttributeChangedSignal("IsMutating"):Connect(function()
			if not model:GetAttribute("IsMutating") then
				prompt.Enabled = true
			else
				prompt.Enabled = false
			end
		end)
	)
	
	promptTrove:Add(
		prompt.Triggered:Connect(function(player)
			if player ~= localPlayer then return end
			local ParentIndex = model:GetAttribute("ParentIndex")
			if not ParentIndex then return end

			--print("Labubu pressed:", model.Name)

			-- Tell server
			Network.Plots.TakeLabubu:FireServer(model.Name, floorNum, ParentIndex)
			ClickSound:Play()
		end)
	)
	
	prompt.Enabled = not model:GetAttribute("IsMutating")
end

local function attachStealPrompt(model: Model, plot: Model)
	-- Only Labubus
	if model:GetAttribute("Type") ~= "Labubu" then
		return
	end

	local base = plot
	if not base then return end

	-- Skip my own plot
	if base == PlayerPlot then
		return
	end

	local ownerUserId = base:GetAttribute("OwnerUserId")
	if ownerUserId == localPlayer.UserId then
		return
	end
	
	local ownerPlayer = Players:GetPlayerByUserId(ownerUserId)
	if not ownerPlayer then return end

	local promptPart =
		model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")

	if not promptPart then return end

	-- Prevent duplicates
	if promptPart:FindFirstChild("StealPrompt") then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "StealPromptAttachment"
	attachment.Position = Vector3.new(0, -1.5, 0)
	attachment.Parent = promptPart

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = "Labubu"
	prompt.HoldDuration = 2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = attachment
	
	local function UpdatePromptState()
		prompt.Enabled = not model:GetAttribute("IsMutating") 
			and model:GetAttribute("IsStealable") and not player:GetAttribute("MagicShield")
	end

	local promptTrove = Trove.new()

	promptTrove:Add(
		player:GetAttributeChangedSignal("MagicShield"):Connect(function()
			UpdatePromptState()
		end)
	)

	promptTrove:Add(
		model:GetPropertyChangedSignal("Parent"):Connect(function()
			attachment:Destroy()
			promptTrove:Destroy()
		end)
	)

	promptTrove:Add(
		model:GetAttributeChangedSignal("IsMutating"):Connect(function()
			UpdatePromptState()
		end)
	)
	
	promptTrove:Add(
		model:GetAttributeChangedSignal("IsStealable"):Connect(function()
			UpdatePromptState()
		end)
	)

	promptTrove:Add(
		prompt.Triggered:Connect(function(player)
			if player ~= localPlayer then return end

			local floorNum = tonumber(
				string.match(model.Parent.Parent.Parent.Name, "%d+")
			)
			local parentIndex = model:GetAttribute("ParentIndex")
			if not floorNum or not parentIndex then return end

			Network.Plots.StealLabubu:FireServer(
				base,
				ownerUserId,
				model.Name,
				floorNum,
				parentIndex
			)
		end)
	)

	UpdatePromptState()
end

local function hookFloor(floor: Model)
	local Plot = floor.Parent
	
	local slots = floor:WaitForChild("Slots", 3)
	if not slots then return end

	local placements = slots:WaitForChild("Placements", 3)
	if not placements then return end

	-- Existing placements
	for _, placement in ipairs(placements:GetChildren()) do
		if placement:IsA("Model") then
			attachStealPrompt(placement, Plot)
		end
	end

	-- Future placements
	placements.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			attachStealPrompt(child, Plot)
		end
	end)
end

local function hookBase(base: Model)
	-- Existing floors
	for _, child in ipairs(base:GetChildren()) do
		if child:IsA("Model") and child.Name:match("^Floor") then
			hookFloor(child)
		end
	end

	-- Floors added later
	base.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child.Name:match("^Floor") then
			hookFloor(child)
		end
	end)
end

local function InitSlotsPlacements()
	if Initialized then return end
	Initialized = true
	
	local plot: Model = PlayerPlot
	
	local dropper: Model = PlotUtil.getPlotDropper(plot)
	if not dropper then return end
	
	for _, floor in ipairs(plot:GetChildren()) do
		local floorNum = tonumber(string.match(floor.Name, "%d+"))

		local Slots: Folder = floor:FindFirstChild("Slots")
		if not Slots then continue end
		
		local Placements: Folder = PlotUtil.getSlotsPlacements(Slots)
		if not Placements then continue end
		
		Placements.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				attachLabubuPrompt(child)
			end
		end)
		
		for _, placement in ipairs(Placements:GetChildren()) do
			if placement:IsA("Model") then
				attachLabubuPrompt(placement)
			end
		end

		for _, slot in ipairs(Slots:GetChildren()) do
			local Button: Model = slot:FindFirstChild("Button")
			if not Button then continue end

			local getSlotData = PlotUtil.getSlotData(slot)
			if not getSlotData then continue end
			
			local SlotMainScreen: BasePart? = PlotUtil.getSlotScreenMain(slot)
			if not SlotMainScreen then continue end
			
			if slot:GetAttribute("ForSale") then
				slot:GetAttributeChangedSignal("ForSale"):Connect(function()
					if not slot:GetAttribute("ForSale") then
						local Tool: Tool = localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Tool")

						if Tool then
							if Tool:GetAttribute("Placeable") then
								HandleSlotsPlacements(true, Tool.Name)
							end
						end
					end
				end)
			end
			
			slot:GetAttributeChangedSignal("Occupied"):Connect(function()
				local Tool: Tool = localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Tool")
				local IsPlaceable = Tool and Tool:GetAttribute("Placeable")
				
				if IsPlaceable then
					local IsOccupied = slot:GetAttribute("Occupied")

					HandleSlotsPlacements(not IsOccupied, Tool.Name)
				end
			end)
			
			local ProximityPrompt: ProximityPrompt = SlotMainScreen:FindFirstChild("ProximityPrompt")
			if not ProximityPrompt then
				local NewProximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
				NewProximityPrompt.RequiresLineOfSight = false
				NewProximityPrompt.ActionText = "Place"
				NewProximityPrompt.ObjectText = "Placeholder"
				NewProximityPrompt.HoldDuration = 0.5
				NewProximityPrompt.MaxActivationDistance = 10
				NewProximityPrompt.Enabled = false
				
				ProximityPrompt = NewProximityPrompt
				ProximityPrompt.Parent = SlotMainScreen
				
				table.insert(SlotsData, {
					Slot = slot,
					Prompt = ProximityPrompt
				})
				
				ProximityPrompt.Triggered:Connect(function(player: Player)
					if player ~= localPlayer then return end
					if not plot:GetAttribute("Initialized") then return end

					if not PlotUtil.ButtonRatelimit:Try() then return end
					
					if not LastSlotPlacementToolName then return end
					Network.Plots.PlaceAtSlot:FireServer(
						LastSlotPlacementToolName, floorNum, getSlotData.SlotNum
					)
					
					ClickSound:Play()
				end)
			end
		end
	end
	
	
	-- Existing bases
	for _, base in ipairs(Bases:GetChildren()) do
		if base:IsA("Folder") then
			hookBase(base)
		end
	end

	-- Bases added later
	Bases.ChildAdded:Connect(function(base)
		if base:IsA("Folder") then
			hookBase(base)
		end
	end)
end

function Plots.init()
	local function UpdatePlotData()
		if not PlayerPlot then return end

		local plotData = ClientData.PlotData()
		if not plotData then return end

		PlayerPlotData = plotData
		InitSlotsPlacements()
	end
	
	local function UpdatePlot()
		local Plot = ClientData.Plot()
		if Plot then
			PlayerPlot = Plot
			UpdatePlotData()
		end
	end
	
	Charm.subscribe(ClientData.Plot, UpdatePlot)
	UpdatePlot()
	
	Charm.subscribe(ClientData.PlotData, UpdatePlotData)
end

function Plots.characterAdded(character: Model)
	char = character
	
	local trove = Trove.new()
	trove:AttachToInstance(character)
	
	trove:Add(
		character.ChildAdded:Connect(function(child: Instance)
			if child:IsA("Tool") then
				local Tool: Tool = child
				
				if Tool:GetAttribute("Placeable") then
					HandleSlotsPlacements(true, Tool.Name)
				end
			end
		end)
	)
	
	trove:Add(
		character.ChildRemoved:Connect(function(child: Instance)
			if child:IsA("Tool") then
				local Tool: Tool = child

				if Tool:GetAttribute("Placeable") then
					HandleSlotsPlacements(false)
				end
			end
		end)
	)
end

function Plots.characterRemoving(character: Model)
	
end

return Plots