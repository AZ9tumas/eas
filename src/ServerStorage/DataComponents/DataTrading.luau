local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Network)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)
local DataHandler = require(ServerStorage.DataHandler)

local NotifyError = Network.Notifications.Error
local NotifySuccess = Network.Notifications.Success

local TradeRequest = Network.Trading["TradeRequest"]
local TradeResponse = Network.Trading["TradeResponse"]
local TradeUpdate = Network.Trading["TradeUpdate"]
local TradeAccept = Network.Trading["TradeAccept"]
local TradeCancel = Network.Trading["TradeCancel"]

local DataTrading = {}

local ActiveTrades = {}
local PendingRequests = {}
local REQUEST_TIMEOUT = 30

-- Utility
local function findTrade(player)
	for _, trade in pairs(ActiveTrades) do
		if trade.P1 == player or trade.P2 == player then
			return trade
		end
	end
end

local function ownsItem(player, itemName)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return false end
	return backpack:FindFirstChild(itemName) ~= nil
end

local function removeTrade(trade)
	for i,v in pairs(ActiveTrades) do
		if v == trade then
			table.remove(ActiveTrades, i)
			break
		end
	end
end

-- Trade Request
TradeRequest.OnServerEvent:Connect(function(sender, targetName)
	local target = Players:FindFirstChild(targetName)
	if not target then return end
	if sender == target then return end

	if findTrade(sender) or findTrade(target) then return end
	if PendingRequests[target] then return end -- already has request

	-- Store pending request
	PendingRequests[target] = {
		Sender = sender,
		ExpireTime = os.clock() + REQUEST_TIMEOUT
	}

	TradeRequest:FireClient(target, sender.Name)

	-- Timeout task
	task.delay(REQUEST_TIMEOUT, function()
		local pending = PendingRequests[target]
		if not pending then return end

		-- If still same request and not answered
		if pending.Sender == sender then
			PendingRequests[target] = nil

			NotifyError:FireClient(sender, "Trade request expired.")
		end
	end)
end)

-- Accept / Decline
TradeResponse.OnServerEvent:Connect(function(receiver, senderName, accepted)
	local pending = PendingRequests[receiver]
	if not pending then return end

	local sender = pending.Sender
	if not sender or sender.Name ~= senderName then return end

	-- Clear pending request
	PendingRequests[receiver] = nil

	if not accepted then
		NotifyError:FireClient(sender, "Trade declined.")
		return
	end

	local trade = {
		P1 = sender,
		P2 = receiver,
		Offer1 = {},
		Offer2 = {},
		Accepted1 = false,
		Accepted2 = false
	}

	table.insert(ActiveTrades, trade)

	TradeUpdate:FireClient(sender, "Start", receiver.Name)
	TradeUpdate:FireClient(receiver, "Start", sender.Name)
end)

-- Update Offer
TradeUpdate.OnServerEvent:Connect(function(player, newItems)
	local trade = findTrade(player)
	if not trade then return end

	for _, itemName in pairs(newItems) do
		if not ownsItem(player, itemName) then
			return
		end
	end

	if trade.P1 == player then
		trade.Offer1 = newItems
		trade.Accepted1 = false
	else
		trade.Offer2 = newItems
		trade.Accepted2 = false
	end
	
	trade.Accepted1 = false
	trade.Accepted2 = false
	
	TradeUpdate:FireClient(trade.P1, "AcceptUpdate", trade.Accepted1, trade.Accepted2)
	TradeUpdate:FireClient(trade.P2, "AcceptUpdate", trade.Accepted1, trade.Accepted2)

	TradeUpdate:FireClient(trade.P1, "Sync", trade.Offer1, trade.Offer2)
	TradeUpdate:FireClient(trade.P2, "Sync", trade.Offer1, trade.Offer2)
end)

-- Accept
TradeAccept.OnServerEvent:Connect(function(player)
	local trade = findTrade(player)
	if not trade then return end

	if trade.P1 == player then
		trade.Accepted1 = true
	else
		trade.Accepted2 = true
	end
	
	TradeUpdate:FireClient(trade.P1, "AcceptUpdate", trade.Accepted1, trade.Accepted2)
	TradeUpdate:FireClient(trade.P2, "AcceptUpdate", trade.Accepted1, trade.Accepted2)

	if trade.Accepted1 and trade.Accepted2 then

		-- Final validation
		for _, item in pairs(trade.Offer1) do
			if not ownsItem(trade.P1, item) then return end
		end
		for _, item in pairs(trade.Offer2) do
			if not ownsItem(trade.P2, item) then return end
		end

		-- Execute trade
		for _, itemName in pairs(trade.Offer1) do
			local item = trade.P1.Backpack:FindFirstChild(itemName)
			if item then
				item.Parent = trade.P2.Backpack
			end
		end

		for _, itemName in pairs(trade.Offer2) do
			local item = trade.P2.Backpack:FindFirstChild(itemName)
			if item then
				item.Parent = trade.P1.Backpack
			end
		end

		TradeUpdate:FireClient(trade.P1, "Complete")
		TradeUpdate:FireClient(trade.P2, "Complete")

		removeTrade(trade)
	end
end)

-- Cancel
TradeCancel.OnServerEvent:Connect(function(player)
	local trade = findTrade(player)
	if not trade then return end

	TradeUpdate:FireClient(trade.P1, "Cancel")
	TradeUpdate:FireClient(trade.P2, "Cancel")

	removeTrade(trade)
end)

function DataTrading.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data loaded")
	--print(profileData, clientData)
end

function DataTrading.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end
	
	--warn(player.Name, "data unloading")
	local trade = findTrade(player)
	if trade then
		if trade.P1 then TradeUpdate:FireClient(trade.P1, "Cancel") end
		if trade.P2 then TradeUpdate:FireClient(trade.P2, "Cancel") end
		removeTrade(trade)
	end
end

return DataTrading