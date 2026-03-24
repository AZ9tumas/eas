local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Parent.Types)
local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom


local SyncedState = {
	LeaderboardCache = atom({}) :: Charm.Atom<Types.LeaderboardCache>,
	LeaderboardNextUpdateTime = atom(0),
	
	CurrentSessionTime = atom(0),
	WeatherEvents = atom({}),
}

return SyncedState