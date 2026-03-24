local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Normal Lucky Block",
	Rarity = "Basic",
	Price = 25,
	HatchTime = 10,
	SkipProductId = Products["Skip Common Hatch"],
	Weight = 50, -- Spawn chance %
	Items = nil
}

return Egg