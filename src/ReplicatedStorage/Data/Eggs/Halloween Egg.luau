local ReplicaetdStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicaetdStorage.Shared.Info.Products)

local Egg = {
	DisplayName = "Halloween Egg",
	Rarity = "Secret",
	Price = nil,
	HatchTime = 300,
	--SkipProductId = Products["Skip Exclusive Hatch"],
	Weight = 0, -- Spawn chance %
	Items = nil
}

return Egg