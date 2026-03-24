local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataStoreLoc = ServerScriptService:WaitForChild("PlayerData"):WaitForChild("PlayerDataStore")

local DataHandler = require(ServerStorage.DataHandler)
local ProfileTemplate = require(PlayerDataStoreLoc.DefaultData)

local Promise = require(ReplicatedStorage.Packages.Promise)
local SyncedState = require(ReplicatedStorage.Shared.SyncedState)
local Types = require(ReplicatedStorage.Shared.Types)

local leaderboards = {} :: { [string]: OrderedDataStore }

local refreshTime = 60


local DataLeaderboards = {}

function DataLeaderboards.init()
    local alter = "1.0"
    if RunService:IsStudio() then
        alter = "Studio-1.0"
    end

    local function addLeaderboard(statName: string)
		local value = (ProfileTemplate.PlayerStats and ProfileTemplate.PlayerStats[statName])
			or ProfileTemplate[statName]
        if value == nil or type(value) ~= "number" then
            warn("[DataLeaderboards] No stat found for:", statName)
            return
        end
        leaderboards[statName] = DataStoreService:GetOrderedDataStore(`GlobalLeaderboard-{statName}-{alter}`)
    end
    addLeaderboard("Cash")
    addLeaderboard("Playtime")
    addLeaderboard("Mutations")

    task.spawn(function()
        while true do
            DataLeaderboards.updateGlobalLeaderboard()
            for _, player in pairs(Players:GetPlayers()) do
                task.spawn(function()
                    DataLeaderboards.globalSave(player)
                end)
            end
    
            SyncedState.LeaderboardNextUpdateTime(workspace:GetServerTimeNow() + refreshTime)
            task.wait(refreshTime)
        end
    end)
end

function DataLeaderboards.playerAdded(player: Player)
    local profileData = DataHandler.getProfileData(player)
    if profileData == nil then
        return
    end
end

function DataLeaderboards.globalSave(player: Player)
    if not player:GetAttribute("ProfileLoaded") then
        return
    end
    if player.UserId <= 0 then
        print("Play testing")
        return
    end

    xpcall(function()
        local profileData = DataHandler.getProfileData(player)
        if profileData == nil then
            return
        end
        for statName, orderedDataStore in pairs(leaderboards) do
			local statValue = (profileData.PlayerStats and profileData.PlayerStats[statName])
				or profileData[statName]
            if statValue == nil then
                warn("[DataLeaderboard] - Stat value doesn't exist for: " .. statName)
                continue
            end

            orderedDataStore:SetAsync(tostring(player.UserId), math.round(statValue))
        end
    end, function(errorMessage)
        warn("[DataLeaderboard] GlobalSave Error: " ..  errorMessage)
    end)
end

function DataLeaderboards.updateGlobalLeaderboard()
    local pageSize = 50

    local leaderboardCache: Types.LeaderboardCache = {}
    local getSuccess, errorMessage = pcall(function()
		for statName, orderedDataStore in pairs(leaderboards) do
			--print("Fetching leaderboard for:", statName)
			
			local sortedValues 
			local success, err = pcall(function()
				sortedValues = orderedDataStore:GetSortedAsync(false, pageSize)
			end)
			
			if not success then
				warn("Failed to fetch sorted values for", statName, ":", err)
			elseif not sortedValues then
				warn("No sorted values for", statName)
			else
				local currentPage = sortedValues:GetCurrentPage()
				
				--if statName == "Rebirths" then
				--	print(statName, "page length:", #currentPage)
				--	for index, entry in ipairs(currentPage) do
				--		print(string.format("[%s] #%d -> Key: %s | Value: %s", statName, index, entry.key, entry.value))
				--	end
				--end
				
				leaderboardCache[statName] = currentPage
			end
        end
    end)

    if not getSuccess then
        warn("Global Leaderboard Error: " .. errorMessage)
        return
    end

	local promises = {}
	
    for _, pageCache in pairs(leaderboardCache) do
		for _, leaderboardData in ipairs(pageCache) do
            table.insert(promises, Promise.new(function(resolve)
                local userId = tonumber(leaderboardData.key)
                if userId == nil then
                    resolve()
                    return
                end
                xpcall(function() 
                    local icon = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    leaderboardData.icon = icon
                end, function() 
                    warn("[DataService] UpdateGlobalLeaderboard - Failed to get user thumbnail from user id!")
                end)
                xpcall(function() 
                    local username = Players:GetNameFromUserIdAsync(userId)
                    leaderboardData.key = username
                end, function() 
                    warn("[DataService] UpdateGlobalLeaderboard - Failed to get username from user id!")
                end)
                resolve()
            end))
        end
    end
    if promises[1] == nil then
        SyncedState.LeaderboardCache(leaderboardCache)
        warn("No promises found?")
        return
    end
    Promise.allSettled(promises):timeout(30):catch(function(e)
        if Promise.Error.isKind(e, Promise.Error.Kind.TimedOut) then
            warn("Leaderboard timed out!")
        elseif type(e) == "string" then
            warn(e)
        else
            warn("Failed to load leaderboard!")
        end
    end):finally(function()
        SyncedState.LeaderboardCache(leaderboardCache)
    end)
end

return DataLeaderboards