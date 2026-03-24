
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gamepasses =
	require(ReplicatedStorage.Shared.Info.Gamepasses)

local Products =
	require(ReplicatedStorage.Shared.Info.Products)

local ProductsStaticPrices =
	require(ReplicatedStorage.Shared.Info.Products.ProductsStaticPrices)

local GamepassesStaticPrices =
	require(ReplicatedStorage.Shared.Info.Gamepasses.GamepassesStaticPrices)

-- reverse maps
local GamepassIdToName: { [number]: string } = {}
local ProductIdToName: { [number]: string } = {}

-- build once
for name, id in pairs(Gamepasses) do
	GamepassIdToName[id] = name
end

for name, id in pairs(Products) do
	ProductIdToName[id] = name
end

--=========================================
-- Instant asset name lookup (no yielding)
--=========================================

return function(
	assetId: number,
	infoType: Enum.InfoType
): { Name: string?, PriceInRobux: number? }

	if infoType == Enum.InfoType.GamePass then
		local Name = GamepassIdToName[assetId]
		return { 
			Name = Name,
			PriceInRobux = Name and GamepassesStaticPrices[Name] or nil
		}

	elseif infoType == Enum.InfoType.Product then
		local Name = ProductIdToName[assetId]
		return { 
			Name = Name,
			PriceInRobux = Name and ProductsStaticPrices[Name] or nil
		}
	end

	return nil
end