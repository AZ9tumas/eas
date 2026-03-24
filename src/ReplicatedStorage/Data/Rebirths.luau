export type HatchableRequirement = {
	Rarity: string,
	Mutation: string,
	RequiredAmount: number?, -- optional, if not specified, 1 is assumed
}

export type RebirthRequirements = {
	Cash: number,
	Hatchables: { HatchableRequirement },
}

export type RebirthRewards = {
	Slots: number?,
	CashMulti: number?,
	EggLuck: number?,
	OfflineEarningExtension: number?,
	UnlockFloorNum: number?,
}

export type RebirthData = {
	Requirements: RebirthRequirements,
	Rewards: RebirthRewards,
}

export type Rebirths = {
	[number]: RebirthData,
}

local Rebirths = {
	[1] = {
		Requirements = {
			Cash = 5000000,
			Hatchables = {
				{ Rarity = "Epic", Mutation = "Thunder" },
				{ Rarity = "Rare", Mutation = "Rainbow" },
			}
		},
		Rewards = {
			Slots = 2,
			CashMulti = 0.1, -- 10%+
			EggLuck = 0.1, -- 10%+
			OfflineEarningExtension = 60 * 10, -- 10 mins additional time
			UnlockFloorNum = 2,
		},
	},
	
	[2] = {
		Requirements = {
			Cash = 30000000,
			Hatchables = {
				{ Rarity = "Epic", Mutation = "Conqueror" },
				{ Rarity = "Epic", Mutation = "Thunder" },
			},
		},
		Rewards = {
			Slots = 2,
			CashMulti = 0.1,
			EggLuck = 0.1,
			OfflineEarningExtension = 60 * 10,
		},
	},

	[3] = {
		Requirements = {
			Cash = 50000000,
			Hatchables = {
				{ Rarity = "Legendary", Mutation = "Conqueror" },
				{ Rarity = "Epic", Mutation = "Corrupted" },
			},
		},
		Rewards = {
			Slots = 2,
			CashMulti = 0.1,
			EggLuck = 0.1,
			OfflineEarningExtension = 60 * 10,
		},
	},

	[4] = {
		Requirements = {
			Cash = 75000000,
			Hatchables = {
				{ Rarity = "Legendary", Mutation = "Corrupted" },
				{ Rarity = "Legendary", Mutation = "Thunder" },
			},
		},
		Rewards = {
			Slots = 2,
			CashMulti = 0.1,
			EggLuck = 0.1,
			OfflineEarningExtension = 60 * 10,
		},
	},

	[5] = {
		Requirements = {
			Cash = 100000000,
			Hatchables = {
				{ Rarity = "Godlike", Mutation = "Divine" },
				{ Rarity = "Secret", Mutation = "Divine" },
			},
		},
		Rewards = {
			Slots = 2,
			CashMulti = 0.1,
			EggLuck = 0.1,
			OfflineEarningExtension = 60 * 10,
		},
	},

	[6] = {
		Requirements = {
			Cash = 130000000,
			Hatchables = {
				{ Rarity = "Godlike", Mutation = "Galaxy" },
				{ Rarity = "Secret", Mutation = "Conqueror", RequiredAmount = 2 },
			},
		},
		Rewards = {
			Slots = 2,
			CashMulti = 0.1,
			EggLuck = 0.1,
			OfflineEarningExtension = 60 * 10,
		},
	},

	[7] = {
		Requirements = {
			Cash = 165000000,
			Hatchables = {
				{ Rarity = "Secret", Mutation = "Divine", RequiredAmount = 2 },
				{ Rarity = "Godlike", Mutation = "Divine" },
			},
		},
		Rewards = {
			Slots = 2,
			CashMulti = 0.1,
			EggLuck = 0.1,
			OfflineEarningExtension = 60 * 10,
		},
	},
}

return Rebirths :: Rebirths
