local AS = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

funnelSessionId = HttpService:GenerateGUID()


local AnalyticsService = {}
function AnalyticsService.LogFunnelStepEvent(Player: Player, FunnelGroup: string, StepNumber: number, StepName: string)
	AS:LogFunnelStepEvent(
		Player, -- The player to log
		FunnelGroup, -- The Funnel Group
		funnelSessionId,
		StepNumber, -- Step number
		StepName -- Step name
	)
	
	print("Logged Analytic for "..Player.Name, " :", FunnelGroup, StepNumber, StepName)
end

return AnalyticsService
