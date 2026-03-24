local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local IsServer = RunService:IsServer()

local GiveSpin

if IsServer then
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerStorage = game:GetService("ServerStorage")
	
	GiveSpin = ServerStorage:WaitForChild("BindableEvents"):WaitForChild("GiveSpin")
end

type WheelData = {
	Name: string,
	ImageId: string,
	Rarity: number, --10 = 10%
	Reward: (Player) -> (),
}


local Module: {[number]: WheelData} = {
	[1] = {
		Name = "30,000 Cash", 
		ImageId = "rbxassetid://109157531183362",
		Rarity = 55,
		Reward = function(Player: Player)
			if IsServer then
				
			else
				-- client doesnt get called here, its not being used atm. (only server works)
			end
		end,
	},
	[2] = {
		Name = "+1,000 Candies", 
		ImageId = "rbxassetid://109157531183362",
		Rarity = 34,
		Reward = function(Player: Player)
			if IsServer then

			else
				-- client doesnt get called here, its not being used atm. (only server works)
			end
		end,
	},
	[3] = {
		Name = "Ancient Egg", 
		ImageId = "rbxassetid://109157531183362",
		Rarity = 7.5,
		Reward = function(Player: Player)
			if IsServer then

			else
				-- client doesnt get called here, its not being used atm. (only server works)
			end
		end,
	},
	[4] = {
		Name = "Hell Egg", 
		ImageId = "rbxassetid://109157531183362",
		Rarity = 2,
		Reward = function(Player: Player)
			if IsServer then

			else
				-- client doesnt get called here, its not being used atm. (only server works)
			end
		end,
	},
	[5] = {
		Name = "Halloween Egg", 
		ImageId = "rbxassetid://109157531183362",
		Rarity = 1,
		Reward = function(Player: Player)
			if IsServer then

			else
				-- client doesnt get called here, its not being used atm. (only server works)
			end
		end,
	},
	[6] = {
		Name = "SIX SIX SIX", 
		ImageId = "rbxassetid://109157531183362",
		Rarity = 0.5,
		Reward = function(Player: Player)
			if IsServer then

			else
				-- client doesnt get called here, its not being used atm. (only server works)
			end
		end,
	},
}


return Module