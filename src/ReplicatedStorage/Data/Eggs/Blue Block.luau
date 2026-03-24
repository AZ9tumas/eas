local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Blue Lucky Block",
	Rarity = "Common", -- Common to Basic
	Price = 500,
	HatchTime = 30,
	SkipProductId = Products["Skip Common Hatch"],
	Weight = 30, -- Spawn chance %
	Items = nil
}

return Egg