local GroupRewardConfig = {

	-- Seconds after joining before the GroupReward popup appears
	PopupDelay = 30,

	-- Reward granted upon claiming
	Reward = {
		Rarity = "Exclusive",
		MutationTier = 1,
		ObtainedFrom = "GroupReward",
	},

	-- Notification shown after successful claim
	NotifyMessage = "You've claimed your Group Reward!",
}

return GroupRewardConfig
