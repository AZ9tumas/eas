local FriendsAPI = {}

-- by .ranu.

-- List of PlaceIds in your experience
local currentGamePlaces = {}
table.insert(currentGamePlaces, game.PlaceId)


local Replicated = game:GetService("ReplicatedStorage")

local Social = game:GetService("SocialService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

-- Helper to iterate over FriendPages
local function iterPageItems(pages)
	return coroutine.wrap(function()
		local pagenum = 1
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(item, pagenum)
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
			pagenum = pagenum + 1
		end
	end)
end

-- Get all friends from pages
local function getFriends()
	local success, friendPages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if not success then
		warn("Failed to get friends list")
		return {}
	end

	local friends = {}
	for friendInfo, _ in iterPageItems(friendPages) do
		table.insert(friends, friendInfo)
	end
	return friends
end

-- Helper function to check if a value exists in a table
local function tableContains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

-- Define a type for a friend/connection
export type ConnectionInfo = {
	VisitorId: number,       -- The UserId of the connection
	UserName: string,        -- The username of the connection
	DisplayName: string,     -- The DisplayName of the connection
	LastOnline: string,      -- When the connection was last online
	IsOnline: boolean,       -- If the connection is currently online
	LastLocation: string,    -- The name of the connection's current location
	PlaceId: number,         -- The place ID of the connection's last location
	GameId: string,          -- The DataModel.JobId of the connection's last location
	LocationType: number,    -- The location type of the connection's last location
}

local LocationType = {
	MobileWebsite = 0,
	MobileInGame = 1,
	Website = 2,
	Studio = 3,
	InGame = 4,
	XBoxApp = 5,
	TeamCreate = 6,
}

-- Map LocationType values to priority numbers
-- Normally we'd prioritize Website over Game, but knowing how bad roblox status system is.
-- We will priortize Game over Website.

--local LocationPriority = {
--	[LocationType.XBoxApp] = 1,
--	[LocationType.MobileWebsite] = 1,
--	[LocationType.Website] = 1,
--	[LocationType.MobileInGame] = 2,
--	[LocationType.InGame] = 2,
--	[LocationType.TeamCreate] = 3,
--	[LocationType.Studio] = 3,
--}

local LocationPriority = {
	[LocationType.XBoxApp] = 1,
	[LocationType.MobileInGame] = 1,
	[LocationType.InGame] = 1,
	[LocationType.MobileWebsite] = 2,
	[LocationType.Website] = 2,
	[LocationType.TeamCreate] = 3,
	[LocationType.Studio] = 3,
}

local function getOnlineFriends() : {ConnectionInfo}?
	local friends: {ConnectionInfo}? = {}
	local success, result = pcall(player.GetFriendsOnline, player)

	if success then
		for _, friend in pairs(result) do
			if friend.IsOnline then
				local PlaceId = friend.PlaceId or 0

				local PlayerNameFromId = Players:GetNameFromUserIdAsync(friend.VisitorId)
				if PlayerNameFromId and Players:FindFirstChild(PlayerNameFromId) then continue end

				if not tableContains(currentGamePlaces, PlaceId) then
					table.insert(friends, friend)
				end
			end
		end

		-- Sort friends by LocationPriority
		table.sort(friends, function(a, b)
			local priorityA = LocationPriority[a.LocationType] or 999
			local priorityB = LocationPriority[b.LocationType] or 999
			return priorityA < priorityB
		end)
	else
		warn("Failed to get online players: " .. result)
	end

	return friends
end

local connection = nil

-- Send a random friend notification
local function sendRandomFriendInvite() : ConnectionInfo?
	--local friends = getFriends()
	local friends: {ConnectionInfo}? = getOnlineFriends()
	if not friends then return end

	local count = #friends
	if count == 0 then return end

	-- Group friends by priority
	local priorityGroups: {[number]: {ConnectionInfo}} = {}
	for _, friend in pairs(friends) do
		local priority = LocationPriority[friend.LocationType] or 999
		priorityGroups[priority] = priorityGroups[priority] or {}
		table.insert(priorityGroups[priority], friend)
	end

	-- Collect friends starting from highest priority until we have at least 4
	local collectedFriends: {ConnectionInfo} = {}
	for priority = 1, 3 do  -- assuming only 3 priority levels
		local group = priorityGroups[priority]
		if group then
			for _, friend in pairs(group) do
				table.insert(collectedFriends, friend)
			end
		end
		if #collectedFriends >= 4 then
			break
		end
	end

	if #collectedFriends == 0 then return end

	-- Pick a random friend from collectedFriends
	local randomIndex = Random.new():NextInteger(1, #collectedFriends)
	local randomFriend: ConnectionInfo? = collectedFriends[randomIndex]

	if not randomFriend then return end

	return randomFriend :: {
		VisitorId: number,       -- The UserId of the connection
		UserName: string,        -- The username of the connection
		DisplayName: string,     -- The DisplayName of the connection
		LastOnline: string,      -- When the connection was last online
		IsOnline: boolean,       -- If the connection is currently online
		LastLocation: string,    -- The name of the connection's current location
		PlaceId: number,         -- The place ID of the connection's last location
		GameId: string,          -- The DataModel.JobId of the connection's last location
		LocationType: number,    -- The location type of the connection's last location
	}
end

FriendsAPI.GetOnlineFriend = sendRandomFriendInvite

return FriendsAPI
