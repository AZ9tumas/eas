local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom


local ClientData = {
 --   Flags = atom(Types.Flags),

	Cash = atom(0),
	Candy = atom(0),
	Mutations = atom(0),
	Rebirths = atom(0),
	LastDailyRewardTime = atom(0),
	
	-- Tutorial
	HasCompletedTutorial = atom(nil),
	TutorialStep = atom(nil),
	EggsReceived = atom(nil),
	EggsPlaced = atom(nil),
	EggsHatched = atom(nil),
	
	-- DataPlots
	Plot = atom(Types.Plot),
	PlotData = atom(Types.PlotData),
	
	-- DataIndex
	Index = atom(Types.Index),
	
	-- DataBackpack
	Backpack = atom(Types.Backpack),

	-- DataGamepasses
	Gamepasses = atom(Types.Gamepasses),
	
	-- DataGroupRewards
	GroupRewardClaimTime = atom(0),
	
	-- Robux Spent
	RobuxSpent = atom(0),
	
	-- Some Stats
	Playtime = atom(0),
	FirstTimePlayed = atom(0),
	CurrentSessionTime = atom(0),
	LeftSessionAt = atom(0),
	
	-- Spins
	Spins = atom(0),
	NextSpinAt = atom(0),

 --   -- DataPlayerStats
 --   PlayerStats = atom(Types.PlayerStats),

	-- DataSettings
	Settings = atom(Types.Settings),
}

return ClientData