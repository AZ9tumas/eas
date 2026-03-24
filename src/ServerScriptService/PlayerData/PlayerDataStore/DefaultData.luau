-- Your Default Player Data Template Here
-- You can use most of other data types such as Vector3 if BufferEncoder is enabled (its enabled as default)
-- However, if you use them, you shouldn't disable BufferEncoder after, or your data could get corrupted!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

return {
	JoinedSessionAt = 0,
	LeftSessionAt = 0,
	
	Playtime = 0,
	FirstTimePlayed = 0,
	CurrentSessionTime = 0,
	
	RobuxSpent = 0,
	Donated = 0,
	
	Cash = 1000,
	Candy = 0,
	
	Mutations = 0,
	Rebirths = 0,
	
	OfflineEarningExtension = 0,
	
	CashMulti = 1,
	EggLuck = 1,
	
	HasCompletedTutorial = false,
	HasBeenRewardedBeginnerLabubu = false,
	
	TutorialStep = 1,
	EggsReceived = 0,
	EggsPlaced = 0,
	EggsHatched = 0,
	
	LastDailyRewardTime = 0,
	
	-- DataPlots
	PlotData = Types.PlotData,
	Index = Types.Index,
	
	Traits = Types.Traits,
	
	-- DataBackpack
	Backpack = Types.Backpack,
	
	-- DataGroupRewards
	GroupRewardClaimTime = 0,
	
	-- DataSpin
	Spins = 0,
	NextSpinAt = 0,
	
	-- DataGamepasses
	Gamepasses = Types.Gamepasses,
	
	-- DataSettings
	Settings = Types.Settings,
	
	-- Badges
	Badges = Types.Badges,
	
	-- Codes
	RedeemedCodes = Types.RedeemedCodes,
	
	-- Cache
	PurchaseIdCache = {},
	
	
	-- Do not edit this // This is used for DataStoreModule
	__meta = {
		Queue = {},
		QueueTbl = {}
	},
}