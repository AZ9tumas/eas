local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Network = require(ReplicatedStorage.Network)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local ProductPurchaseHandlers = require(ServerStorage.PurchaseHandlers.ProductPurchaseHandlers)
local DataHandler = require(ServerStorage.DataHandler)
--local DataPlayerStats = require(ServerStorage.DataComponents.DataPlayerStats)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)


local DataDeveloperProducts = {}

function DataDeveloperProducts.init()
	local existingIds = {}
	for name, id in pairs(Products) do
		if table.find(existingIds, id) then
			warn("[DataDeveloperProducts] Duplicate id for gamepass:", name)
		end
		table.insert(existingIds, id)

		if ProductPurchaseHandlers[name] == nil then
			warn("[DataDeveloperProducts] No product purchase handler found for:", name)
		end
	end

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return DataDeveloperProducts.processReceipt(receiptInfo)
	end
end

function DataDeveloperProducts.processReceipt(receiptInfo: {PlayerId: number, PurchaseId: number, ProductId: number})
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile, clientData = DataHandler.getProfileData(player)
	if profile == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	task.spawn(function()
		-- Get product info
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product)
		end)

		if success and productInfo and productInfo.PriceInRobux
			and productInfo.PriceInRobux > 0 then
			local cost = productInfo.PriceInRobux

			-- Update the player’s stat
			task.spawn(function()
				profile.RobuxSpent += cost
				clientData.RobuxSpent(profile.RobuxSpent)
				--DataPlayerStats.incrementStat(player, "MostRobuxSpent", cost)
			end)
		else
			warn("Failed to get price for product ID:", receiptInfo.ProductId)
		end
	end)

	return DataHandler.purchaseIdCheckAsync(
		profile,
		receiptInfo.PurchaseId,
		function()
			local name: string?
			for _name, id in pairs(Products) do
				--print(receiptInfo.ProductId, id)
				if receiptInfo.ProductId == id then
					name = _name
					break
				end
			end
			assert(name, "[DataDeveloperProducts] Cannot grant product with id:", receiptInfo.ProductId)
			DataDeveloperProducts.grantProduct(player, name)
		end
	)
end

function DataDeveloperProducts.grantProduct(player: Player, name: string)
	print(player, name)
	local profileData = DataHandler.getProfileData(player)
	assert(profileData)

	local productHandler = ProductPurchaseHandlers[name]
	assert(productHandler, "[DataDeveloperProducts] No product handler found for:", name)
	productHandler(player)


	local productId = Products[name]
	if productId == nil then
		return
	end
	local trove = Trove.new()
	trove:AttachToInstance(player)
	trove:AddPromise(getProductInfo(productId, Enum.InfoType.Product):andThen(function(productInfo)
		Network.Notifications.ProductBought:FireClient(player, productInfo.Name)
	end))
end

return DataDeveloperProducts