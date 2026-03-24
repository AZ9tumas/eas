local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Rare Egg",
	Rarity = "Rare",
	Price = 25000,
	HatchTime = 60,
	SkipProductId = Products["Skip Rare Hatch"],
	Weight = 15, -- Spawn chance %
	Items = nil
}

return Egg