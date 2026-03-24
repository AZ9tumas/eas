local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerStorage.Modules
local TriggerWeatherEvent = ServerStorage.BindableEvents.TriggerWeatherEvent
local WeatherData = require(ReplicatedStorage.Data.Events)

return function (_, value)
	if WeatherData.Events[value] == nil then
		return ("Weather Event: %s does not exist."):format(value)
	end
	
	TriggerWeatherEvent:Fire(value)

	return ("Triggered Weather Event: %s."):format(value)
end