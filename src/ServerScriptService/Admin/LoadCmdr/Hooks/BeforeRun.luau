local GroupID = game:GetService("ReplicatedStorage"):WaitForChild("GroupID").Value

local StaffRanks = {
	255, 254, 253, 252, 251, 250
	-- anything 250 or above i guess admin lol
}

return function (registry)
	registry:RegisterHook("BeforeRun", function(context)
		local player = context.Executor
		local userId = player.UserId

		-- Block non-creator DefaultAdmin users
		--if context.Group == "DefaultAdmin" and userId ~= game.CreatorId then
		-- Check if player is in the group
		
		local rank = player:GetRankInGroup(GroupID)
		-- Allow if rank is in StaffRanks OR rank >= 250
		if not StaffRanks[rank] and rank < 250 then
			return "You don't have permission to run this command"
		end
		
		--end
	end)
end
