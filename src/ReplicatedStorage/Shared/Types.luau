local Types = {}

--Types.EquippedItems = {
--    RocketLauncher = "",
--    KillSound = "",
--    Trail = "",
--    VictoryAnim = "",

--    BlockUpgrade = "",
--    SpeedUpgrade = "",
--}
--export type EquippedItems = typeof(Types.EquippedItems)

--Types.Flags = {
--    PurchasedStarterPack = false,

--    BlockCollected = false,
--    BlockPlaced = false,
--}
--export type Flags = typeof(Types.Flags)

--export type RoundStates = "Waiting" | "Intermission" | "Ongoing" | "Ended"

local Gamepasses = {
	["Starter Pack"] = false,
	["VIP Status"] = false,
	["Unbreakable Button"] = false,
	["Auto-Collect"] = false,
	["Index Reader"] = false,
	["Triple Hatch"] = false,
	["Lucky Clover"] = false,
	["Magic Shield (Perm)"] = false,
}
export type Gamepasses = typeof(Gamepasses)
Types.Gamepasses = Gamepasses

-- Define the color type and the color table
export type TypeColors = {
	Success: Color3,
	Error: Color3,
	Warning: Color3,
	Info: Color3,
	Default: Color3,
	[any]: Color3, -- allow future dynamic keys
}

local Colors: TypeColors = {
	Success = Color3.fromRGB(85, 255, 127),
	Error = Color3.fromRGB(255, 85, 85),
	Warning = Color3.fromRGB(255, 200, 0),
	Info = Color3.fromRGB(125, 181, 255),
	Default = Color3.fromRGB(240, 240, 240),
}

Types.Colors = Colors :: TypeColors

-- Define the sound type and the sound table
export type TypeSounds = {
	Success: string,
	Error: string,
	Warning: string,
	Info: string,
	Default: string,
	Notify: string,
	Purchase: string,
	[any]: string, -- allow future dynamic keys
}

local Sounds: TypeSounds = {
	Success = "Success",
	Error = "Error",
	Warning = "Warning",
	Info = "Notify",
	Default = "Notify",
	Notify = "Notify",
	Purchase = "Purchase"
}

Types.Sounds = Sounds :: TypeSounds

export type ColorKey = "Success" | "Error" | "Warning" | "Info" | "Default"
export type SoundKey = "Success" | "Error" | "Warning" | "Info" | "Notify" | "Purchase"

--export type WorkerData = {
--	Name: string,
--	Mutation: string,
--}

--export type PlotData = {
--	Floors: number,
--	Monsters: { [number]: WorkerData }, -- or { [string]: WorkerData } if it's keyed by name
--}

--Types.PlotData = {
--	Floors = 1,

--	Monsters = {

--	},
--} :: PlotData

export type LeaderboardPageCache = { { key: string, value: number, icon: string? } }
export type LeaderboardCache = {
	[string]: LeaderboardPageCache
}

Types.Plot = nil :: Model

Types.PlayerStats = {
	--Cash = 0,
	--Steals = 0,
	--RobuxSpent = 0,
	--Rebirths = 0,
}
export type PlayerStats = typeof(Types.PlayerStats)

export type Setting = (number | boolean)?
local Settings = {
	Music = true,
	SFX = true,
	--FPS = false,
	GFX = true,
	Trading = true,
	Vibration = true,
}
export type Settings = typeof(Settings)
Types.Settings = Settings :: Settings & {
    [string]: Setting
}

export type StringList = { string }
Types.StringList = {} :: StringList

export type NumberList = { number }
Types.NumberList = {} :: NumberList

export type IndexType = { [string]: StringList }
Types.IndexType = {} :: IndexType

--export type InventoryList = { Tools: {[number]: string} }
--Types.Inventory = {} :: InventoryList

--export type PlaytimeRewards = { [string]: boolean }
--Types.PlaytimeRewards = {} :: PlaytimeRewards

export type Badges = {
	[string]: number,
}
Types.Badges = {} :: Badges

export type RedeemedCodes = StringList
Types.RedeemedCodes = {} :: RedeemedCodes

export type Labubu = {
	Id: number,
	Name: string?,
	Type: string?,

	-- Origin / Rarity
	Source: "Normal" | "Exclusive" | "Event",
	EggType: "Normal" | "Blue" | "Purple" | "Ancient" | "Arcane" | "King" | "Mythic",
	EggRarity: "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Exclusive", -- Common to Basic

	-- Progression
	MutationTier: number,       -- current tier (1–11)
	MaxMutationTier: number,    -- usually 11
	BaseCPS: number,            -- CPS before multipliers

	-- Mutation State
	IsMutating: boolean,
	MutationTime: number?,

	-- Final Calculated Output
	CPS: number,                -- BaseCPS × mutation × traits × rebirth
	
	-- Collection & Rules
	IsStealable: boolean,       -- false if mutating / exclusive / event
	Traits: { [string]: boolean },

	-- Metadata
	CreatedAt: number,
	LastCollectedAt: number,
}

Types.Labubu = {} :: Labubu

export type PlotSpinInfo = { 
	CanSpin: boolean, 
	SpinCooldown: number,
	LastSpinTime: number,
	SpinsCount: number,
	SpinBroken: boolean,
}

export type PlotRollsInfo = { 
	EggRollsCount: number,
	LastEggRollTime: number,
	EggRolls: { [number]: string }
}

export type Slot = {
	Placement: (Labubu | Egg)?,
	Cash: number?,
	OfflineCash: number?,
	LastOfflineCashCollected: number?,
	LastOfflineCashHolderLeaveSession: number?,
	HasBeenHoldingOfflineCash: boolean?
}
export type Slots = { [number]: Slot }

export type FloorData = {
	Slots: Slots
}

export type PlotData = {
	Floors: { [number]: FloorData },
	SpinInfo: PlotSpinInfo,
	RollsInfo: PlotRollsInfo
}

Types.Slot = {
	Placement = {},
	Cash = 0,
	OfflineCash = 0,
	LastOfflineCashCollected = 0,
} :: Slot

Types.PlotData = {} :: PlotData
Types.FloorData = {} :: FloorData
Types.Slots = {} :: Slots
Types.PlotSpinInfo = {
	CanSpin = true,
	SpinCooldown = 0,
	LastSpinTime = 0,
	SpinsCount = 0,
	SpinBroken = false
} :: PlotSpinInfo

Types.PlotRollsInfo = {
	EggRollsCount = 0,
	LastEggRollTime = 0,
	EggRolls = {}
} :: PlotRollsInfo

--[[
local DEFAULT_PLOT: PlotData = {
	Floors = {
		[1] = {
			Slots = {
				[1] = nil,
				[2] = nil,
				[3] = nil,
			}
		},

		[2] = {
			Slots = {
				[1] = nil,
				[2] = nil,
				[3] = nil,
			}
		}
	}
}
--]]

export type Egg = {
	-- Identity
	Id: string,
	Name: string?,
	Type: string?,
	
	EggMutationTier: number?,

	IsExclusive: boolean?,

	-- Acquisition
	ObtainedFrom: "SpinRoll" | "Shop" | "Event" | "SpinWheel" | "Admin" | "Unknown",
	
	-- Hatching
	IsHatching: boolean?,
	HatchTimeLeft: number?,

	-- Fusion
	--CanFuse: boolean,
	--FuseInto: string?, -- "Mutated Egg"
	--FusionMutationBoost: number?, -- % bonus

	-- Pity System
	--PityGroup: "Normal" | "Legendary" | "Mythic" | "Exclusive" | "Event" | nil,
	--PityRequired: number?, -- pulls required

	-- Weighted rewards
	--LabubuPool: {
	--	[speciesName: string]: {
	--		Weight: number,
	--		BaseMutationTier: number,
	--		MaxMutationTier: number
	--	}
	--},

	-- Mutation chances (applies when hatched)
	--MutationRolls: {
	--	[Tier: number]: number -- % chance
	--},
	
	-- UI / Info
	PriceOnly: boolean?,

	-- Restrictions
	CanBeStolen: boolean?,
	CanBeTraded: boolean?,

	-- Event metadata
	EventName: string?,
	EventCurrencyCost: number?,
}

export type Backpack = {
	Eggs: { Egg },
	Labubus: { Labubu }
}

Types.Backpack = {
	Eggs = {},
	Labubus = {}
} :: Backpack

export type EggData = {
	DisplayName: string,
	Rarity: string,
	HatchTime: number,
	Weight: number,
	Price: number?,
	SkipProductId: number,
	Items: {},
}

Types.EggData = {} :: EggData
Types.Egg = {} :: Egg

export type Index = {
	[number]: {
		[string]: boolean
	}
}

Types.Index = {} :: Index

export type Traits = {
	[string]: number | boolean,
}

Types.Traits = {} :: Traits

export type WeatherData = {
	EventType: string,
	TraitName: string,
	CashBonus: number,
	Rarity: number,
	Icon: string,

	OnActivation: () -> (),
	OnDeactivation: () -> (),
}

Types.WeatherData = {} :: WeatherData


return Types