local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Weather = require(Modules.Weather)
local WeatherData = require(ReplicatedStorage.Data.Events)

local PickableWeathers = {}


local function FillWeatherTable()
	PickableWeathers = {}
	for _, weather in WeatherData.Events do
		table.insert(PickableWeathers, weather.EventType)
	end

	for i = #PickableWeathers, 2, -1 do
		local j = math.random(1, i)
		PickableWeathers[i], PickableWeathers[j] = PickableWeathers[j], PickableWeathers[i]
	end
end

local function getNextWeather()
	if #PickableWeathers == 0 then
		FillWeatherTable()
	end

	return table.remove(PickableWeathers)
end


FillWeatherTable()

--while wait(WeatherData.Frequency) do
while wait(WeatherData.Frequency) do
	local NextWeather = getNextWeather()
	local NewWeather = Weather.new(NextWeather)
end