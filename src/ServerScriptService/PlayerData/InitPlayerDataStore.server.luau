-- It's ideal to init the PlayerDataStore Module as soon as the server starts.
-- Recommended not to remove/disable this script.

-- This script initializes the module and checks for latest version

local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local UpdateURL = "https://raw.githubusercontent.com/Ranw1/PlayerDataStoreModule/main/version.json"
local Version = PlayerDataStore.Version

function CheckForUpdates()
	local success, result = pcall(function()
		local response = HttpService:GetAsync(UpdateURL, true)
		return HttpService:JSONDecode(response)
	end)

	if success and result and result.version then
		if result.version ~= Version then
			warn("[PlayerDataStore] Outdated! Current: " .. Version .. " | Latest: " .. result.version)
			return false, result.version
		else
			print("[PlayerDataStore] Up to date: " .. Version)
			return true, result.version
		end
	else
		warn("[PlayerDataStore] Failed to check for updates:", result)
		return nil
	end
end

if RunService:IsStudio() then
	-- Check for latest Version
	--CheckForUpdates()
end

--PlayerDataStore:EraseUserData(3267747943)
--PlayerDataStore:EraseUserData(1559361473)
--PlayerDataStore:EraseUserData(131605217)
--PlayerDataStore:EraseUserData(-1)
--PlayerDataStore:EraseUserData(-2)

-- PlayerDataStore Basic Tutorial

--PlayerDataStore:SetValue(game.Players.baconddddddd1, "Test", true)
--PlayerDataStore:SetValue(3267747943, "Test", true)
--PlayerDataStore:SetValue("3267747943", "Test", true)
--PlayerDataStore:GetValue(game.Players.baconddddddd1, "Test")

--print(PlayerDataStore:GetData(player))
--PlayerDataStore:GetData(player).Test = {}
--PlayerDataStore:GetValue(player, "Test").TestInisde = true
--print(PlayerDataStore:GetData(player))


-- Advanced Functions For Working with offline Players

--IMPORTANT: Do NOT use the advanced offline functions if the player is in the server.
--	Also do NOT require the module from another state/level, such as if you have pressed Play in Studio, and then
--			later you go to the Server, and from command line you require it again.
				
--local OfflineLoadedData = PlayerDataStore:LoadOfflineData(3267747943)
--print(OfflineLoadedData)
--OfflineLoadedData.Hi = {}
--OfflineLoadedData.Hi2 = {}
--OfflineLoadedData.Hi3 = false
--OfflineLoadedData.Hi4 = 6
--PlayerDataStore:SaveOfflineData(3267747943, OfflineLoadedData)

-- or just :SetValue if you will only make a single modification (because :SetValue by itself do all the following:

-- LoadOfflineData, Modifies, SaveOfflineData, and publish the changes to the other servers.

-- Note: Without :SetValue, it wont publish the changes to other servers.

-- All of that above was mostly for learning, from v0.4 just use UpdateData method and it does everything for you.

-- )