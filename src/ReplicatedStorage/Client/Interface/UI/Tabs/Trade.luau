local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)

local TradeRequestEvent = Network.Trading.TradeRequest
local TradeResponseEvent = Network.Trading.TradeResponse
local TradeUpdateEvent = Network.Trading.TradeUpdate
local TradeAcceptEvent = Network.Trading.TradeAccept
local TradeCancelEvent = Network.Trading.TradeCancel

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

-- Frame references from NewUI.Frames
local newUI = playerGui:WaitForChild("NewUI")
local frames = newUI.Frames

local tradeListGui = frames.TradeList
local tradeGui = frames.Trade
local tradeRequestGui = frames.TradeRequest

-- TradeList elements
local tradeListTop = tradeListGui.Top
local tradeListClose = tradeListTop.Close
local tradeListTitle = tradeListTop.Main.Title
local tradeListMain = tradeListGui.Main
local tradeListScroll = tradeListMain.ScrollingFrame

-- Trade elements
local tradeTop = tradeGui.Top
local tradeClose = tradeTop.Close
local tradeTitle = tradeTop.Main.Title
local tradeMain = tradeGui.Main
local yourOfferFrame = tradeMain.YourOffer
local otherOfferFrame = tradeMain.OtherOffer
local searchFrame = tradeMain.Search
local acceptButton = tradeMain.Accept
local declineButton = tradeMain.Decline
local otherNameLabel = tradeMain.OtherName
local yourNameLabel = tradeMain.YourName

-- YourOffer and OtherOffer each have a ScrollingFrame child
local yourOfferScroll = yourOfferFrame:FindFirstChild("ScrollingFrame")
local otherOfferScroll = otherOfferFrame:FindFirstChild("ScrollingFrame")
local searchScroll = searchFrame:FindFirstChild("ScrollingFrame")

-- TradeRequest elements
local tradeReqTop = tradeRequestGui.Top
local tradeReqClose = tradeReqTop.Close
local tradeReqMain = tradeRequestGui.Main
local tradeReqTitle = tradeReqMain.Title
local tradeReqYes = tradeReqMain.Yes
local tradeReqNo = tradeReqMain.No

-- State
local inTrade = false
local tradePartnerName = nil
local pendingRequestSender = nil
local myOffer: {string} = {} -- list of labubu names offered
local myAccepted = false
local otherAccepted = false

-- Animation helpers
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
		TweenService:Create(scaleObj, tClick, {Scale = 0.9}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scaleObj, tRelease, {Scale = 1.05}):Play()
	end)
end

-- Clear children of a scrolling frame (except layout objects)
local function clearScroll(scroll: ScrollingFrame)
	if not scroll then return end
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end
end

-- Create a simple item card for the offer display
local function createItemCard(parent: Instance, itemName: string, interactive: boolean?): Frame
	local card = Instance.new("Frame")
	card.Name = itemName
	card.Size = UDim2.new(0.95, 0, 0, 40)
	card.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	card.BackgroundTransparency = 0.3
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local label = Instance.new("TextLabel")
	label.Name = "ItemName"
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = itemName
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = card

	return card
end

-- Reset trade state
local function resetTradeState()
	inTrade = false
	tradePartnerName = nil
	myOffer = {}
	myAccepted = false
	otherAccepted = false
end

-- Close trade UI and cancel if in active trade
local function closeTrade()
	if inTrade then
		TradeCancelEvent:FireServer()
	end
	tradeGui.Visible = false
	resetTradeState()
	clearScroll(yourOfferScroll)
	clearScroll(otherOfferScroll)
	clearScroll(searchScroll)
end

-- Close trade request popup
local function closeTradeRequest()
	tradeRequestGui.Visible = false
	pendingRequestSender = nil
end

-----------------------------------------
-- TradeList: populate player entries
-----------------------------------------

-- Clone a template entry from the ScrollingFrame or create one
local templateEntry = nil
for _, child in tradeListScroll:GetChildren() do
	if child:IsA("Frame") and child.Name ~= "UIListLayout" then
		templateEntry = child:Clone()
		break
	end
end

local function populateTradeList()
	-- Clear existing entries
	for _, child in tradeListScroll:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	-- Check trading setting
	local settings = ClientData.Settings()
	if settings and settings.Trading == false then
		return
	end

	local playerList = Players:GetPlayers()
	for i, player in playerList do
		if player == localPlayer then continue end

		local entry: Frame
		if templateEntry then
			entry = templateEntry:Clone()
		else
			-- Fallback: create a simple entry
			entry = Instance.new("Frame")
			entry.Size = UDim2.new(1, 0, 0, 50)
			entry.BackgroundTransparency = 1
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = entry
		end

		entry.Name = player.Name
		entry.LayoutOrder = i
		entry.Parent = tradeListScroll

		-- Update title text
		local titleLabel = entry:FindFirstChild("Title", true)
		if titleLabel and titleLabel:IsA("TextLabel") then
			titleLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
		end

		-- Find and wire the "Trade" button inside the entry
		local tradeBtn = entry:FindFirstChild("Trade", true)
		if tradeBtn and tradeBtn:IsA("TextButton") then
			bindButtonAnimations(tradeBtn)
			tradeBtn.Activated:Connect(function()
				-- Check trading setting before sending request
				local currentSettings = ClientData.Settings()
				if currentSettings and currentSettings.Trading == false then
					return
				end
				TradeRequestEvent:FireServer(player.Name)
				InterfaceTabUtil.closeAllTabs()
			end)
		end
	end
end

-----------------------------------------
-- Search/Inventory: populate items
-----------------------------------------

local function populateSearch()
	if not searchScroll then return end
	clearScroll(searchScroll)

	local backpack = ClientData.Backpack()
	if not backpack or not backpack.Labubus then return end

	for _, labubu in backpack.Labubus do
		local itemName = labubu.Name or labubu.Type or "Unknown"
		local isInOffer = table.find(myOffer, itemName) ~= nil

		local btn = Instance.new("TextButton")
		btn.Name = itemName
		btn.Size = UDim2.new(0.95, 0, 0, 40)
		btn.BackgroundColor3 = if isInOffer then Color3.fromRGB(50, 50, 50) else Color3.fromRGB(60, 60, 60)
		btn.BackgroundTransparency = if isInOffer then 0.6 else 0.3
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = searchScroll

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = if isInOffer then Color3.fromRGB(90, 255, 100) else Color3.fromRGB(0, 0, 0)
		stroke.Thickness = if isInOffer then 3 else 1
		stroke.Parent = btn

		local label = Instance.new("TextLabel")
		label.Name = "ItemName"
		label.Size = UDim2.new(1, -10, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = itemName
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = btn

		bindButtonAnimations(btn)
		btn.Activated:Connect(function()
			local idx = table.find(myOffer, itemName)
			if idx then
				table.remove(myOffer, idx)
			else
				table.insert(myOffer, itemName)
			end
			-- Reset accept when offer changes
			myAccepted = false
			otherAccepted = false
			TradeUpdateEvent:FireServer(myOffer)
			populateSearch() -- refresh visuals
			-- Update your offer display
			clearScroll(yourOfferScroll)
			for _, name in myOffer do
				createItemCard(yourOfferScroll, name)
			end
		end)
	end
end

-- Update other player's offer display
local function updateOtherOffer(items: {string})
	if not otherOfferScroll then return end
	clearScroll(otherOfferScroll)
	for _, itemName in items do
		createItemCard(otherOfferScroll, itemName)
	end
end

-- Update accept state visuals
local function updateAcceptVisuals()
	-- Visual indicator: change accept button appearance based on state
	local acceptMain = acceptButton:FindFirstChild("Main") or acceptButton
	if myAccepted then
		acceptButton.BackgroundColor3 = Color3.fromRGB(50, 210, 60)
		if acceptMain:IsA("GuiObject") and acceptMain ~= acceptButton then
			acceptMain.BackgroundColor3 = Color3.fromRGB(160, 245, 120)
		end
	else
		acceptButton.BackgroundColor3 = Color3.fromRGB(24, 182, 0)
		if acceptMain:IsA("GuiObject") and acceptMain ~= acceptButton then
			acceptMain.BackgroundColor3 = Color3.fromRGB(24, 182, 0)
		end
	end
end

-----------------------------------------
-- Button wiring (outside init, like Rebirth.luau)
-----------------------------------------

-- Ray animations
for _, ray in tradeListGui:GetDescendants() do
	if ray:GetAttribute("IsRay") then
		TweenService:Create(ray, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
	end
end
for _, ray in tradeGui:GetDescendants() do
	if ray:GetAttribute("IsRay") then
		TweenService:Create(ray, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
	end
end
for _, ray in tradeRequestGui:GetDescendants() do
	if ray:GetAttribute("IsRay") then
		TweenService:Create(ray, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
	end
end

-- Bind close buttons
bindButtonAnimations(tradeListClose)
bindButtonAnimations(tradeClose)
bindButtonAnimations(tradeReqClose)
bindButtonAnimations(acceptButton)
bindButtonAnimations(declineButton)
bindButtonAnimations(tradeReqYes)
bindButtonAnimations(tradeReqNo)

tradeListClose.MouseButton1Click:Connect(function()
	InterfaceTabUtil.closeAllTabs()
end)

tradeClose.MouseButton1Click:Connect(function()
	closeTrade()
	InterfaceTabUtil.closeAllTabs()
end)

tradeReqClose.MouseButton1Click:Connect(function()
	if pendingRequestSender then
		TradeResponseEvent:FireServer(pendingRequestSender, false)
	end
	closeTradeRequest()
end)

-- Accept / Decline in trade session
acceptButton.Activated:Connect(function()
	if not inTrade then return end
	myAccepted = not myAccepted
	TradeAcceptEvent:FireServer()
	updateAcceptVisuals()
end)

declineButton.Activated:Connect(function()
	closeTrade()
	InterfaceTabUtil.closeAllTabs()
end)

-- Trade request Yes/No
tradeReqYes.Activated:Connect(function()
	if pendingRequestSender then
		TradeResponseEvent:FireServer(pendingRequestSender, true)
	end
	closeTradeRequest()
end)

tradeReqNo.Activated:Connect(function()
	if pendingRequestSender then
		TradeResponseEvent:FireServer(pendingRequestSender, false)
	end
	closeTradeRequest()
end)

-----------------------------------------
-- Network event handlers
-----------------------------------------

-- Incoming trade request (we are the target)
TradeRequestEvent.OnClientEvent:Connect(function(senderName: string)
	-- Check trading setting
	local settings = ClientData.Settings()
	if settings and settings.Trading == false then
		TradeResponseEvent:FireServer(senderName, false)
		return
	end

	pendingRequestSender = senderName
	tradeReqTitle.Text = `@{senderName} sent you a trade request, do you want to accept?`
	tradeRequestGui.Visible = true
end)

-- Trade updates from server
TradeUpdateEvent.OnClientEvent:Connect(function(messageType: string, ...)
	local args = {...}

	if messageType == "Start" then
		local otherName = args[1] :: string
		tradePartnerName = otherName
		inTrade = true
		myOffer = {}
		myAccepted = false
		otherAccepted = false

		-- Set up trade UI
		tradeTitle.Text = `Trade with @{otherName}`
		yourNameLabel.Text = localPlayer.DisplayName
		otherNameLabel.Text = otherName

		-- Close trade list if open, open trade frame
		tradeListGui.Visible = false
		InterfaceTabUtil.closeAllTabs()

		-- Show trade frame directly (not through tab system since session is server-driven)
		tradeGui.Visible = true
		clearScroll(yourOfferScroll)
		clearScroll(otherOfferScroll)
		populateSearch()
		updateAcceptVisuals()

	elseif messageType == "Sync" then
		local offer1 = args[1] -- my offer from server perspective
		local offer2 = args[2] -- other's offer

		-- Server sends Offer1 = P1's items, Offer2 = P2's items
		-- We need to figure out which one is ours
		-- The server always sends in the same order (P1, P2), we don't know which we are
		-- But our local myOffer should match one of them
		-- Simpler: just update display with both, our offer from server overwrites display
		clearScroll(yourOfferScroll)
		if offer1 then
			for _, itemName in offer1 do
				createItemCard(yourOfferScroll, itemName)
			end
		end

		clearScroll(otherOfferScroll)
		if offer2 then
			for _, itemName in offer2 do
				createItemCard(otherOfferScroll, itemName)
			end
		end

	elseif messageType == "AcceptUpdate" then
		local accepted1 = args[1]
		local accepted2 = args[2]
		-- We don't know which player index we are, but we track our own state
		-- The server broadcasts both states; trust the visual from our own myAccepted
		-- We can use the pair to show the other player's state too
		myAccepted = accepted1 ~= nil and accepted1 or false
		otherAccepted = accepted2 ~= nil and accepted2 or false
		updateAcceptVisuals()

	elseif messageType == "Complete" then
		-- Trade completed successfully
		tradeTitle.Text = "Trade Completed!"
		task.delay(2, function()
			tradeGui.Visible = false
			resetTradeState()
			clearScroll(yourOfferScroll)
			clearScroll(otherOfferScroll)
			clearScroll(searchScroll)
		end)

	elseif messageType == "Cancel" then
		-- Trade was cancelled by other player or server
		tradeGui.Visible = false
		resetTradeState()
		clearScroll(yourOfferScroll)
		clearScroll(otherOfferScroll)
		clearScroll(searchScroll)
	end
end)

-----------------------------------------
-- Module
-----------------------------------------

local Trade = {}

function Trade.init()
	-- Set initial labels
	yourNameLabel.Text = localPlayer.DisplayName
	tradeListTitle.Text = "Trade"

	-- Populate trade list when tab opens
	InterfaceTabUtil.OnTabOpen:Connect(function(tabName)
		if tabName == "TradeList" then
			populateTradeList()
		end
	end)

	-- Close trade on tab close (safety)
	InterfaceTabUtil.OnTabClose:Connect(function()
		if inTrade then
			closeTrade()
		end
		closeTradeRequest()
	end)
end

return Trade
