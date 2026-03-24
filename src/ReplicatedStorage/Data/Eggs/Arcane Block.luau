local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Arcane Block",
	Rarity = "Epic",
	Price = 150000,
	HatchTime = 300,
	SkipProductId = Products["Skip Epic Hatch"],
	Weight = 1.5, -- Spawn chance %
	Items = nil
}

return Egg