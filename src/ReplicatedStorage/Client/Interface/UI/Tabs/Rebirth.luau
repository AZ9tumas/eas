local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local TimeFormat = require(ReplicatedStorage.Shared.Utility.Format.TimeFormat)
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)

local RebirthsModule = require(ReplicatedStorage.Data.Rebirths)

local CASH_ICON = "rbxassetid://140608273316708"

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

-- New UI references: NewUI.Frames.Rebirths
local rebirthsGui = playerGui:WaitForChild("NewUI").Frames.Rebirths
local topFrame = rebirthsGui.Top
local headerTitle = topFrame.Main.Title
local closeButton = topFrame.Close

local rebirth1Frame = rebirthsGui.Rebirth1
local requirementsFrame = rebirth1Frame.Requirements
local rewardsFrame = rebirth1Frame.Rewards
local rebirthButton = rebirth1Frame.Rebirth

-- Collect requirement Item frames from Requirements.Holder
local requirementsHolder = requirementsFrame:FindFirstChild("Holder")
local requirementItems: {Frame} = {}
if requirementsHolder then
	for _, child in requirementsHolder:GetChildren() do
		if child:IsA("Frame") and child.Name == "Item" then
			table.insert(requirementItems, child)
		end
	end
	table.sort(requirementItems, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
end

-- Collect reward frames from Rewards.Main.Holder (each named "Reward1")
local rewardsMain = rewardsFrame:FindFirstChild("Main")
local rewardsHolder = rewardsMain and rewardsMain:FindFirstChild("Holder")
local rewardFrames: {Frame} = {}
if rewardsHolder then
	for _, child in rewardsHolder:GetChildren() do
		if child:IsA("Frame") then
			table.insert(rewardFrames, child)
		end
	end
	table.sort(rewardFrames, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
end

-- Reward frames are indexed by position (matching their default text):
-- [1] = Slots (+2), [2] = Offline (+10min), [3] = Luck (+5%)
local REWARD_SLOTS_INDEX = 1
local REWARD_OFFLINE_INDEX = 2
local REWARD_LUCK_INDEX = 3

-- Animation helpers (matching old handler + Index.luau patterns)
local tHover = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tClick = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tRelease = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

local function bindButtonAnimations(btn: GuiButton)
	local scaleObj = btn:FindFirstChild("UIScale")
	if not scaleObj then
		scaleObj = Instance.new("UIScale")
		scaleObj.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(scaleObj, tHover, {Scale = 1.05}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(scaleObj, tHover, {Scale = 1.0}):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(scaleObj, tClick, {Scale = 0.85}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scaleObj, tRelease, {Scale = 1.05}):Play()
	end)
end

-- Ray rotation animations (continuous 360° spin for elements with IsRay attribute)
for _, ray in rebirthsGui:GetDescendants() do
	if ray:GetAttribute("IsRay") then
		local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
		TweenService:Create(ray, tweenInfo, {Rotation = 360}):Play()
	end
end

-- Bind button animations
bindButtonAnimations(closeButton)
bindButtonAnimations(rebirthButton)

-- Close button
closeButton.MouseButton1Click:Connect(function()
	InterfaceTabUtil.closeAllTabs()
end)

local Rebirth = {}

function Rebirth.init()
	local function UpdateRebirthsUI()
		local Rebirths = ClientData.Rebirths()
		if not Rebirth then return end

		local NextRebirth = Rebirths + 1
		local NextRebirthData = RebirthsModule[NextRebirth] :: RebirthsModule.RebirthData

		-- Update header title
		headerTitle.Text = `Rebirth: {NextRebirth}`

		if not NextRebirthData then
			-- Max rebirths reached
			rebirthButton.Visible = false
			rebirth1Frame.Visible = false
			return
		end

		rebirth1Frame.Visible = true
		rebirthButton.Visible = true

		-- Get player's current plot placements and cash for requirement checking
		local plot = ClientData.Plot()
		local allPlacements = if plot then PlotUtil.GetAllPlacements(plot) else {}
		local currentCash = ClientData.Cash()

		-- Update Requirements
		-- Item frames: hatchables first, then cash last
		local reqIndex = 1
		if NextRebirthData.Requirements.Hatchables then
			for _, hatchable in NextRebirthData.Requirements.Hatchables do
				local item = requirementItems[reqIndex]
				if item then
					local titleLabel = item:FindFirstChild("Title") :: TextLabel?
					if titleLabel then
						titleLabel.Text = `{hatchable.RequiredAmount or 1}x {hatchable.Rarity} {hatchable.Mutation}`
					end

					-- Check if hatchable requirement is met
					local requiredAmount = hatchable.RequiredAmount or 1
					local _, count = PlotUtil.LabubuPlacementFilterBy(allPlacements, hatchable.Rarity, hatchable.Mutation)
					local claimed = count >= requiredAmount

					local claimedFrame = item:FindFirstChild("Claimed")
					if claimedFrame then
						claimedFrame.Visible = claimed
					end

					item.Visible = true
					reqIndex += 1
				end
			end
		end

		-- Cash requirement in the next available Item frame
		if NextRebirthData.Requirements.Cash then
			local item = requirementItems[reqIndex]
			if item then
				local titleLabel = item:FindFirstChild("Title") :: TextLabel?
				if titleLabel then
					titleLabel.Text = `${formatCommaValue(NextRebirthData.Requirements.Cash)}`
				end

				-- Set cash icon
				local iconLabel = item:FindFirstChild("Icon") :: ImageLabel?
				if iconLabel then
					iconLabel.Image = CASH_ICON
				end

				-- Check if cash requirement is met
				local claimed = currentCash >= NextRebirthData.Requirements.Cash
				local claimedFrame = item:FindFirstChild("Claimed")
				if claimedFrame then
					claimedFrame.Visible = claimed
				end

				item.Visible = true
				reqIndex += 1
			end
		end

		-- Hide remaining unused Item frames and reset their Claimed overlay
		for i = reqIndex, #requirementItems do
			requirementItems[i].Visible = false
			local claimedFrame = requirementItems[i]:FindFirstChild("Claimed")
			if claimedFrame then
				claimedFrame.Visible = false
			end
		end

		-- Update Rewards (index-based: 1=Slots, 2=Offline, 3=Luck)
		local slotsFrame = rewardFrames[REWARD_SLOTS_INDEX]
		if slotsFrame then
			local title = slotsFrame:FindFirstChild("Title") :: TextLabel?
			if NextRebirthData.Rewards.Slots then
				if title then title.Text = `+{NextRebirthData.Rewards.Slots}` end
				slotsFrame.Visible = true
			else
				slotsFrame.Visible = false
			end
		end

		local offlineFrame = rewardFrames[REWARD_OFFLINE_INDEX]
		if offlineFrame then
			local title = offlineFrame:FindFirstChild("Title") :: TextLabel?
			if NextRebirthData.Rewards.OfflineEarningExtension then
				local mins = math.floor(NextRebirthData.Rewards.OfflineEarningExtension / 60)
				if title then title.Text = `+{mins}min` end
				offlineFrame.Visible = true
			else
				offlineFrame.Visible = false
			end
		end

		local luckFrame = rewardFrames[REWARD_LUCK_INDEX]
		if luckFrame then
			local title = luckFrame:FindFirstChild("Title") :: TextLabel?
			if NextRebirthData.Rewards.EggLuck then
				if title then title.Text = `+{math.floor(NextRebirthData.Rewards.EggLuck * 100)}%` end
				luckFrame.Visible = true
			else
				luckFrame.Visible = false
			end
		end
	end

	-- Rebirth action button
	rebirthButton.Activated:Connect(function()
		local Rebirths = ClientData.Rebirths()
		if not Rebirth then return end

		local NextRebirth = Rebirths + 1
		Network.Plots.Rebirth:FireServer(NextRebirth)
	end)

	Charm.subscribe(ClientData.Rebirths, UpdateRebirthsUI)
	Charm.subscribe(ClientData.Cash, UpdateRebirthsUI)

	InterfaceTabUtil.OnTabOpen:Connect(function(tabName)
		if tabName == "Rebirths" then
			UpdateRebirthsUI()
		end
	end)

	UpdateRebirthsUI()
end

return Rebirth