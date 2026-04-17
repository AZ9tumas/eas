local ServerStorage = game:GetService("ServerStorage")

local DataGroupRewards = require(ServerStorage.DataComponents.DataGroupRewards)

local groupId = 784444031


local GroupChestPrompt = {}

function GroupChestPrompt.promptTriggered(prompt: ProximityPrompt, player: Player)
	if not player:IsInGroupAsync(groupId) then
		return
	end
	DataGroupRewards.claimGroupReward(player)
end

return GroupChestPrompt