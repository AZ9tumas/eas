local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataPlots = require(ServerStorage.DataComponents.DataPlots)

local WeatherData = require(ReplicatedStorage.Data.Events)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local SyncedState = require(ReplicatedStorage.Shared.SyncedState)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)

local Network = require(ReplicatedStorage.Network)
local TriggerWeatherEvent = ServerStorage.BindableEvents.TriggerWeatherEvent

local Weather = {}
Weather.__index = Weather

-- Active weathers by name
Weather.ActiveWeathers = {} :: {[string]: any}
Weather.ActiveWeathersNames = {} :: {[string]: boolean}

-- ⏱️ How often to roll triggers (seconds)
local TRIGGER_CHECK_INTERVAL = 60

-- 🔧 Create / activate a weather
function Weather.new(WeatherName: string)
	assert(WeatherData.Events[WeatherName] ~= nil, "Could not find event data!")

	-- Prevent duplicate same weather
	if Weather.ActiveWeathers[WeatherName] then
		return Weather.ActiveWeathers[WeatherName]
	end

	local self = setmetatable({}, Weather)

	self.WeatherData = WeatherData.Events[WeatherName]
	self.WeatherName = self.WeatherData.EventType
	self.OnActivateFunction = self.WeatherData.OnActivation
	self.OnDeactivateFunction = self.WeatherData.OnDeactivation

	-- Activate
	if self.OnActivateFunction then
		self.OnActivateFunction()
	end

	-- Register as active
	Weather.ActiveWeathers[self.WeatherName] = self
	Weather.ActiveWeathersNames[self.WeatherName] = true
	SyncedState.WeatherEvents(deepCopy(Weather.ActiveWeathersNames))
	Network.Notifications.Info:FireAllClients("It is now " .. self.WeatherName .. ".", 8)

	-- Auto cleanup after duration
	task.delay(WeatherData.Duration, function()
		self:Cleanup()
	end)

	return self
end

-- 🧹 Cleanup / deactivate
function Weather:Cleanup()
	if not Weather.ActiveWeathers[self.WeatherName] then
		return
	end

	if self.OnDeactivateFunction then
		self.OnDeactivateFunction()
	end

	Weather.ActiveWeathers[self.WeatherName] = nil
	Weather.ActiveWeathersNames[self.WeatherName] = nil
	
	SyncedState.WeatherEvents(deepCopy(Weather.ActiveWeathersNames))
end


function Weather.CleanupAll()
	for _, weather in pairs(Weather.ActiveWeathers) do
		weather.OnDeactivateFunction()
	end
	Weather.ActiveWeathers = {}
	Weather.ActiveWeathersNames = {}
	
	SyncedState.WeatherEvents(deepCopy(Weather.ActiveWeathersNames))
	Network.Notifications.Info:FireAllClients("The Weather is now clear.", 8)
end

-- 📊 Utility APIs

function Weather.GetActiveWeathers()
	return Weather.ActiveWeathers
end

function Weather.GetActiveCount()
	local count = 0
	for _ in pairs(Weather.ActiveWeathers) do
		count += 1
	end
	return count
end

function Weather.IsActive(weatherName: string)
	return Weather.ActiveWeathers[weatherName] ~= nil
end

-- 🎲 Roll rarity for all active weathers
function Weather.RollActiveWeatherTriggers(rng: Random?)
	rng = rng or Random.new()

	local triggered = false

	for name, weather in pairs(Weather.ActiveWeathers) do
		local rarity = weather.WeatherData.Rarity
		if typeof(rarity) == "number" and rarity > 0 then
			local roll = rng:NextNumber(0, 1)
			--if roll <= rarity then
			if true == true then
				-- This weather triggered
				warn("[Weather Triggered On Plots]:", name)
				triggered = true

				DataPlots.TriggerWeatherPlotsTrait(name)
				-- If you want per-weather behavior, you can do:
				-- if weather.WeatherData.OnTrigger then
				--     weather.WeatherData.OnTrigger()
				-- end
			end
		end
	end

	return triggered
end

function Weather.StartTriggerLoop()
	task.spawn(function()
		while true do
			task.wait(TRIGGER_CHECK_INTERVAL)

			if Weather.GetActiveCount() > 0 then
				local anyTriggered = Weather.RollActiveWeatherTriggers()
				if anyTriggered then
					--warn("⚠️ At least one active weather triggered!")
				end
			end
		end
	end)
end

Weather.StartTriggerLoop()

TriggerWeatherEvent.Event:Connect(function(weatherName: string)
	Weather.new(weatherName)
end)

return Weather