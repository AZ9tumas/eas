local MutationTier = {
	Default = {
		Tier = 1,
		Multiplier = 1,
		SuccessRateNext = 80, -- %
		FailureDowngrade = "Default",
		MutationTime = 5, -- seconds
		CostMultiplier = 1,
	},

	Silver = {
		Tier = 2,
		Multiplier = 2,
		SuccessRateNext = 75,
		FailureDowngrade = "Default",
		MutationTime = 10,
		CostMultiplier = 10,
	},

	Gold = {
		Tier = 3,
		Multiplier = 4,
		SuccessRateNext = 70,
		FailureDowngrade = "Silver",
		MutationTime = 20,
		CostMultiplier = 18,
	},

	Diamond = {
		Tier = 4,
		Multiplier = 8,
		SuccessRateNext = 65,
		FailureDowngrade = "Gold",
		MutationTime = 45,
		CostMultiplier = 34,
	},

	Rainbow = {
		Tier = 5,
		Multiplier = 16,
		SuccessRateNext = 60,
		FailureDowngrade = "Diamond",
		MutationTime = 90,
		CostMultiplier = 66,
	},

	Thunder = {
		Tier = 6,
		Multiplier = 32,
		SuccessRateNext = 55,
		FailureDowngrade = "Rainbow",
		MutationTime = 180,
		CostMultiplier = 130,
	},

	Saiyan = {
		Tier = 7,
		Multiplier = 64,
		SuccessRateNext = 50,
		FailureDowngrade = "Thunder",
		MutationTime = 420,
		CostMultiplier = 258,
	},

	["Conqueror"] = {
		Tier = 8,
		Multiplier = 128,
		SuccessRateNext = 45,
		FailureDowngrade = "Saiyan",
		MutationTime = 600,
		CostMultiplier = 514,
	},

	Corrupted = {
		Tier = 9,
		Multiplier = 256,
		SuccessRateNext = 40,
		FailureDowngrade = "Conqueror",
		MutationTime = 900,
		CostMultiplier = 1026,
	},

	Galaxy = {
		Tier = 10,
		Multiplier = 512,
		SuccessRateNext = 35,
		FailureDowngrade = "Corrupted",
		MutationTime = 1200,
		CostMultiplier = 2050,
	},

	Divine = {
		Tier = 11,
		Multiplier = 1024,
		SuccessRateNext = nil, -- Max tier
		FailureDowngrade = "Galaxy",
		MutationTime = 1800,
		CostMultiplier = 4098,
	},
}

return MutationTier