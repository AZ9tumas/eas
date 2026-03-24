--!nocheck

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductsStaticPrices = require(ReplicatedStorage.Shared.Info.Products.ProductsStaticPrices)
local GamepassesStaticPrice = require(ReplicatedStorage.Shared.Info.Gamepasses.GamepassesStaticPrices)

local TypedPromise = require(ReplicatedStorage.Shared.Classes.TypedPromise)

return function (assetId: number, infoType: Enum.InfoType): typeof(TypedPromise.new(function(result: { PriceInRobux: number, IconImageAssetId: number, Name: string }) end))
	return TypedPromise.new(function(resolve: ({ PriceInRobux: number, IconImageAssetId: number, Name: string }) -> (), reject, onCancel)
		local thread: thread?
		thread = task.spawn(function()
			local success, result
			repeat
				success, result = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId, infoType)
				if not success then
					task.wait(1) 
				end
			until success
			thread = nil
			if result then
				if not result.PriceInRobux or result.PriceInRobux == 0 then
					if infoType == Enum.InfoType.GamePass then
						local Price: number? = GamepassesStaticPrice[result.Name]

						if Price then
							if result.PriceInRobux ~= Price then
								result.PriceInRobux = Price
							end
						end
					elseif infoType == Enum.InfoType.Product then
						local Price: number? = ProductsStaticPrices[result.Name]
						
						if Price then
							if result.PriceInRobux ~= Price then
								result.PriceInRobux = Price
							end
						end
					end
				end
			end
			resolve(result)
		end)

		onCancel(function()
			if thread == nil then
				return
			end
			task.cancel(thread)
		end)
	end)
end