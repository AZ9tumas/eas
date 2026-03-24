local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local SyncedState = require(ReplicatedStorage.Shared.SyncedState)
local Types = require(ReplicatedStorage.Shared.Types)
local TimeFormat = require(ReplicatedStorage.Shared.Utility.Format.TimeFormat)
local formatLargeNumberThousands = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumberThousands)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local Queue = 0

playerGui:WaitForChild("Templates")
local leaderboardGuiTemplate = playerGui.Templates.LeaderboardMain
local exampleFramesTemplate = playerGui.Templates.ExampleLeaderboardFrames.ScrollingFrame
local frameTemplates = {
    [1] = exampleFramesTemplate.First,
    [2] = exampleFramesTemplate.Second :: any,
    [3] = exampleFramesTemplate.Third :: any,
    [4] = exampleFramesTemplate.Fourth :: any,
    [5] = exampleFramesTemplate.Fifth :: any,
    [6] = exampleFramesTemplate.Sixth :: any,
}


--local leaderboardGuis = {} :: {
--    [string]: typeof(leaderboardGuiTemplate)?
--}

local leaderboardGuis = {} :: { Instance }


local LeaderboardPart = {}

function LeaderboardPart.tagAdded(part: BasePart)
    local statName = part.Name

    local leaderboardGui = leaderboardGuiTemplate:Clone()
    leaderboardGui.Adornee = part
    leaderboardGui.Parent = part
    --leaderboardGuis[statName] = leaderboardGui
	table.insert(leaderboardGuis, leaderboardGui)

    local pageCache = SyncedState.LeaderboardCache()[statName]
    if pageCache == nil then
        return
    end
    LeaderboardPart.updateLeaderboard(statName, pageCache)
    LeaderboardPart.updateTimers()
end

function LeaderboardPart.tagRemoved()
    
end

function LeaderboardPart.updateTimers()
    -- local timeRemaining = math.clamp(SyncedState.LeaderboardNextUpdateTime() - workspace:GetServerTimeNow(), 0, math.huge)
    -- timeRemaining = math.ceil(timeRemaining)

    -- for statName, leaderboardGui in pairs(leaderboardGuis) do
    --     if leaderboardGui == nil then
    --         continue
    --     end
    --     leaderboardGui.Container.Refresh.Text = string.format("Refreshing in %d seconds.", timeRemaining)
    -- end
end

function LeaderboardPart.updateLeaderboard(statName, pageCache: Types.LeaderboardPageCache)
    --local leaderboardGui = leaderboardGuis[statName]
    --if leaderboardGui == nil then
    --    return
	--end
	
	local matchingGuis = {}

	for _, leaderboardGui in ipairs(leaderboardGuis) do
		if leaderboardGui.Adornee and leaderboardGui.Adornee.Name == statName then
			table.insert(matchingGuis, leaderboardGui)
		end
	end

	for _, leaderboardGui in ipairs(matchingGuis) do
	    local scrollingFrame = leaderboardGui.ScrollingFrame
	    for _, leaderboardObj in pairs(scrollingFrame:GetChildren()) do
	        if not leaderboardObj:IsA("Frame") then 
	            continue 
	        end
	        if table.find({"Top", "Bottom"}, leaderboardObj.Name) then
	            continue
	        end
	        leaderboardObj:Destroy()
	    end

		for rank, leaderboardData in ipairs(pageCache) do
			--if statName == "Rebirths" then
			--	print(rank, leaderboardData, leaderboardData.key, leaderboardData.value)
			--end
			
	        local username = leaderboardData.key
			--if tonumber(username) then
	  --          return
	  --      end

	        local statValue = leaderboardData.value
	        local displayValue = tostring(statValue)
			if statName == "TimePlayed" or statName == "Playtime" then
	            displayValue = TimeFormat.convertToHMS(statValue)
			else
				if statName == "MostRobuxSpent" or statName == "RobuxSpent" then
					statName = "Robux Spent"
				elseif statName == "Donated" then
					statName = "Robux Donated"
				end
				
	            displayValue = formatLargeNumberThousands(statValue) .. " " .. statName
	        end


	        local leaderboardFrameTemplate = frameTemplates[math.clamp(rank, 1, 6)]

	        local leaderboardFrame = leaderboardFrameTemplate:Clone()
	        local mainFrame = leaderboardFrame.Content
	        mainFrame.Place.Text = "#" .. rank
	        mainFrame.PlayerName.Text = username
	        mainFrame.Amount.Text = displayValue
	        mainFrame.Avatar.Icon.Image = leaderboardData.icon or ""
	        leaderboardFrame.LayoutOrder = rank
	        leaderboardFrame.Parent = scrollingFrame

	        task.wait(0.05)
		end
	end
end


Charm.subscribe(SyncedState.LeaderboardCache, function()
	for statName, pageCache in pairs(SyncedState.LeaderboardCache()) do
		while Queue > 0 do
			task.wait(0.05)
		end
		
		Queue += 1
		
		local success, err = pcall(function()
			LeaderboardPart.updateLeaderboard(statName, pageCache)
		end)

		if not success then
			warn("⚠️ Failed to update leaderboard for", statName, ":", err)
		end
		
		task.wait()
		
		Queue -= 1
    end
end)

--task.spawn(function()
--    while true do
--        LeaderboardPart.updateTimers()
--        task.wait(1)
--    end
--end)

return LeaderboardPart