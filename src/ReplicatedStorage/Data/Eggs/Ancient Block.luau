local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Ancient Block",
	Rarity = "Rare",
	Price = 50000,
	HatchTime = 120,
	SkipProductId = Products["Skip Rare Hatch"],
	Weight = 3, -- Spawn chance %
	Items = nil
}

return Egg