local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "King Block",
	Rarity = "Legendary",
	Price = 750000,
	RobuxPreferred = true,
	HatchTime = 600,
	SkipProductId = Products["Skip Legendary Hatch"],
	Weight = 0.45, -- Spawn chance %
	Items = nil,
}

return Egg