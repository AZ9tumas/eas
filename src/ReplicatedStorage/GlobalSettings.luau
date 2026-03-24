local module = {
	
	-- Plot Spin (Roll)
	BreakSpinEveryTry = 15,
	BreakForSeconds = 30,
	SpinCooldown = 1,
	EggFusionEnabled = true,
	
	-- Backpack
	BackpackEggsLimit = 15,
	BackpackHatchablesLimit = 15, -- labubu
	
	-- Durations
	x2CashDuration = 15 * 60,
	x2LuckDuration = 15 * 60,
	SuperSpeedDuration = 15 * 60,
	GOLDEN_RAIN_DURATION = 15 * 60,
	
	-- Seller
	SellerPricePercentage = 50, -- 50% of the price
	
	-- Collect Cash
	IndexReaderMultiplier = 2,
	
	-- Offline Cash
	OfflineEarningDuration = 5 * 60 * 60, -- 5 hours
	
	-- Mutations
	HighTierMutationsAreOver = 5, -- > 5
	SuperSpeedMultiplier = 2,
	
	-- Luck
	SERVER_LUCK_DURATION = 15 * 60,

	SERVER_LUCK_MULTIPLIERS = {
		[1] = 2,
		[2] = 4,
		[3] = 8
	}

}

return module
