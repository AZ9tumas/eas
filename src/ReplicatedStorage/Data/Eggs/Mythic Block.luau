local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Mythic Block",
	Rarity = "Mythic",
	Price = 4000000,
	RobuxPreferred = true,
	HatchTime = 1200,
	SkipProductId = Products["Skip Mythic Hatch"],
	Weight = 0.05, -- Spawn chance %
	Items = nil
}

return Egg