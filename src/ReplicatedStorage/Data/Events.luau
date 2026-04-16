local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local Events = {
	Frequency = 60 * 5, -- Every 5 mins
	Duration = 2 * 60, -- each lasting 2 minutes

	Events = {
		["Clear Weather"] = {
			EventType = "Clear Weather",
			TraitName = "Shiny",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://140294665523120",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		["Sunny Event"] = {
			EventType = "Sunny Event",
			TraitName = "Radiant",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://123992771143587",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		["Divine Event"] = {
			EventType = "Divine Event",
			TraitName = "Blessed",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://134617612912546",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		["Hell Event"] = {
			EventType = "Hell Event",
			TraitName = "Infernal",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://135962529656273",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		["Storm Event"] = {
			EventType = "Storm Event",
			TraitName = "Thunder",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://99721972655693",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		["Flame Event"] = {
			EventType = "Flame Event",
			TraitName = "Fire",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://98110762659114",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		["Ice Event"] = {
			EventType = "Ice Event",
			TraitName = "Frozen",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://124120006023625",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		
		["Poison Event"] = {
			EventType = "Poison Event",
			TraitName = "Toxic",
			Rarity = 0.05,
			CashBonus = 1.25,
			Icon = "rbxassetid://128112633880540",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		},
		
		["Golden Rain"] = {
			EventType = "Golden Rain",
			TraitName = "Golden",
			Rarity = 0.01,
			CashBonus = 1.25,
			Icon = "rbxassetid://74363419073497",

			OnActivation = function()

			end,
			OnDeactivation = function()

			end,
		}
	} :: {[string]: Types.WeatherData}
}

return Events