local PlayerDataStore = require(game.ServerScriptService.PlayerDataStore)
local Players = game:GetService("Players")

--[[ You can use this along with Reconcile, if you don't wanna put it into DefaultData Template Module.
local PROFILE_TEMPLATE = {
	Cash = 0,
	Items = {},
}
--]]

local function PlayerAdded(player)
	-- EXAMPLE: Grant the player 100 coins for joining:

	-- PlayerDataStore:Reconcile(player, PROFILE_TEMPLATE) -- yields

	-- METHOD #1:
	PlayerDataStore:Increment(player, "Cash", 100) -- yields

	--[[
		METHOD #2 of doing it:
		
		local PlayerData = PlayerDataStore:GetData(player) -- yields
		
		if PlayerData then
			PlayerData.Cash += 100
		end
	]]
end

-- In case Players have joined the server earlier than this script ran:
for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)