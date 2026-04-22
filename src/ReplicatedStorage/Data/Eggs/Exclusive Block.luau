local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Exclusive Block",
	Rarity = "Exclusive",
	Price = 150_000_000,
	HatchTime = 300,
	SkipProductId = Products["Skip Exclusive Hatch"],
	Weight = 0, -- Spawn chance %
	Items = nil
}

return Egg