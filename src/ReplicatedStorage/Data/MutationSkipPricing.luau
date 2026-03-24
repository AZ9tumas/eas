local MutationSkipPricing = {
	Transitions = {
		["Default"] = {
			Next = "Silver",
			RobuxCost = 3,
			ProductId = 0, -- TODO: replace with real DevProductId
		},
		["Silver"] = {
			Next = "Gold",
			RobuxCost = 9,
			ProductId = 0,
		},
		["Gold"] = {
			Next = "Diamond",
			RobuxCost = 9,
			ProductId = 0,
		},
		["Diamond"] = {
			Next = "Rainbow",
			RobuxCost = 14,
			ProductId = 0,
		},
		["Rainbow"] = {
			Next = "Thunder",
			RobuxCost = 19,
			ProductId = 0,
		},
		["Thunder"] = {
			Next = "Saiyan",
			RobuxCost = 29,
			ProductId = 0,
		},
		["Saiyan"] = {
			Next = "Conqueror",
			RobuxCost = 39,
			ProductId = 0,
		},
		["Conqueror"] = {
			Next = "Corrupted",
			RobuxCost = 49,
			ProductId = 0,
		},
		["Corrupted"] = {
			Next = "Galaxy",
			RobuxCost = 59,
			ProductId = 0,
		},
		["Galaxy"] = {
			Next = "Divine",
			RobuxCost = 99,
			ProductId = 0,
		},
	},
}

return MutationSkipPricing
