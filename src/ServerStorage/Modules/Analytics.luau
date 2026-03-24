local module = {}

--[[
local AnalyticsModule = require(game:GetService("ServerScriptService"):WaitForChild("Modules")
	:WaitForChild("AnalyticsModule"))
--]]

-- Note: We don't wanna reset their cached data, so they are once per server.

local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CachedData = {}

local UUID = HttpService:GenerateGUID(false)

module.Kicked = function(player: Player, KickReason: string)
	--[[CachedData[tostring(player.UserId)] = CachedData[tostring(player.UserId)] or {}
	if CachedData[tostring(player.UserId)][KickReason] then return end

	CachedData[tostring(player.UserId)][KickReason] = true]]

	task.spawn(function()
		AnalyticsService:LogFunnelStepEvent(
			player,
			KickReason, -- Step number
			UUID,
			100
		)
	end)
end

module.DataCorruptionFix = function(player: Player)
	task.spawn(function()
		AnalyticsService:LogFunnelStepEvent(
			player,
			"User PlotData Corruption has been Fixed",
			UUID,
			1
		)
	end)
end

return module
