local Products = {
	["1 Spin"] = 3516252220,
	["3 Spins"] = 3516252336,
	
	["BuyVIPSlot"] = 3519633022,
	
	["Repair Button"] = 3516251533,
	
	["Steal Labubu"] = 3516251703,
	["Steal High-Tier Labubu"] = 3516251827,
	
	["Magic Shield (24h)"] = 3516251353,
	
	["Instant Legendary Egg"] = 3516249015,
	["Instant Mythic Egg"] = 3516249140,
	["Exclusive Egg"] = 3516243852,
	
	["x2 Cash (15m)"] = 3525073499,
	["x2 Luck (15m)"] = 3525080293,
	["Super Speed"] = 3525083382,
	
	["Server Luck (Tier 1)"] = 3516252480,
	["Server Luck (Tier 2)"] = 3516252597,
	["Server Luck (Tier 3)"] = 3526234832,
	
	["Golden Rain"] = 3525085423,
	
	["Keep Lost Mutation"] = 3530469129,
	
	["Skip Mutation 1"] = 3516250335,
	["Skip Mutation 2"] = 3516250465,
	["Skip Mutation 3"] = 3516250561,
	["Skip Mutation 4"] = 3516250675,
	["Skip Mutation 5"] = 3516250761,
	["Skip Mutation 6"] = 3516250846,
	["Skip Mutation 7"] = 3516250930,
	["Skip Mutation 8"] = 3516251003,
	["Skip Mutation 9"] = 3516251156,
	["Skip Mutation 10"] = 3516251253,
	
	["Skip Common Hatch"] = 3516249508, -- = basic hatch
	["Skip Rare Hatch"] = 3516249603,
	["Skip Epic Hatch"] = 3516249689,
	["Skip Legendary Hatch"] = 3516249761,
	["Skip Mythic Hatch"] = 3516249854,
	["Skip Exclusive Hatch"] = 3523845076,
	
	-- Gifting
	
	["Gifting | Product | x2 Cash (15m)"] = 3546202506,
	["Gifting | Product | x2 Luck (15m)"] = 3546202557,
	["Gifting | Product | Super Speed"] = 3546202625,
	
	["Gifting | Pass | Starter Pack"] = 3546202714,
	["Gifting | Pass | VIP Status"] = 3546202774,
	["Gifting | Pass | Unbreakable Button"] = 3546202818,
	["Gifting | Pass | Auto-Collect"] = 3546202856,
	["Gifting | Pass | Index Reader"] = 3546202904,
	["Gifting | Pass | Triple Hatch"] = 3546202955,
	["Gifting | Pass | Lucky Clover"] = 3546202996,
	["Gifting | Pass | Magic Shield (Perm)"] = 3546203047,
}

export type Products = typeof(Products)

return Products :: Products & {
	[string]: number,
}