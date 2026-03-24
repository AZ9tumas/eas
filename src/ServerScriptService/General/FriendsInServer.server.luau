local Players = game:GetService("Players")

local PlayersFriends = {}

local function Update(player: Player)
	PlayersFriends[player.UserId] = {}

	for i, plr in pairs(Players:GetPlayers()) do
		if plr ~= player then
			if plr:IsFriendsWithAsync(player.UserId) then
				if plr.Parent and player.Parent then
					-- Initialize both tables
					PlayersFriends[player.UserId] = PlayersFriends[player.UserId] or {}
					PlayersFriends[plr.UserId] = PlayersFriends[plr.UserId] or {}

					-- Add each other
					table.insert(PlayersFriends[player.UserId], plr.UserId)
					table.insert(PlayersFriends[plr.UserId], player.UserId)

					-- Set both as having friends in the server
					--player:SetAttribute("HasFriendsInServer", true)
					--plr:SetAttribute("HasFriendsInServer", true)
					
					player:SetAttribute("FriendsInServer", #PlayersFriends[player.UserId])
					plr:SetAttribute("FriendsInServer", #PlayersFriends[plr.UserId])
				end
			end
		end
	end

	if not player.Parent then
		PlayersFriends[player.UserId] = nil
	else
		if player:GetAttribute("FriendsInServer") == nil then
			player:SetAttribute("FriendsInServer", 0)
		end
		
		--if player:GetAttribute("HasFriendsInServer") == nil then
		--	player:SetAttribute("HasFriendsInServer", false)
		--end
	end
	
	--warn("Friend Boost - After Player Join:", PlayersFriends)
end

-- handle player join
Players.PlayerAdded:Connect(function(player: Player)
	Update(player)
end)

-- handle player leaving
Players.PlayerRemoving:Connect(function(player: Player)
	PlayersFriends[player.UserId] = nil

	-- also remove this player from other players' friend lists
	for userId, friends in pairs(PlayersFriends) do
		for i = #friends, 1, -1 do
			if friends[i] == player.UserId then
				table.remove(friends, i)

				local Plr = Players:GetPlayerByUserId(userId)
				
				if Plr then
					Plr:SetAttribute("FriendsInServer", #friends)
					
					-- ✅ check if this friend list is now empty
					--if #friends == 0 then
					--	--print("Player with UserId " .. userId .. " now has no friends in the server.")
					--	Plr:SetAttribute("HasFriendsInServer", false)
					--end
				end
			end
		end
	end
	
	--warn("Friend Boost - After Player Leave:", PlayersFriends)
end)

-- catch already-in players
for _, player in ipairs(Players:GetPlayers()) do
	Update(player)
end