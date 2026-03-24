local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--//imports
local DataHandler = require(ServerStorage.DataHandler)
local DataPlots = require(ServerStorage.DataComponents.DataPlots)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)


local GamepassPurchaseHandlers = {} :: { 
    [string]: ( (player: Player) -> () )?,
}

-- automatically in place
GamepassPurchaseHandlers["Auto-Collect"] = function(player: Player, OnPurchase: boolean?)
	
end

GamepassPurchaseHandlers["Magic Shield (Perm)"] = function(player: Player, OnPurchase: boolean?)
	player:SetAttribute("MagicShield", true)
end

-- automatically in place
GamepassPurchaseHandlers["Index Reader"] = function(player: Player, OnPurchase: boolean?)

end

GamepassPurchaseHandlers["Starter Pack"] = function(player: Player, OnPurchase: boolean?)
	if OnPurchase then
		DataPlots.GiveEgg(player, "Arcane Block", "Pass")
	end
end

-- automatically in place
GamepassPurchaseHandlers["VIP Status"] = function(player: Player, OnPurchase: boolean?)

end

-- ⚠️⚠️⚠️⚠️⚠️⚠️
GamepassPurchaseHandlers["Triple Hatch"] = function(player: Player, OnPurchase: boolean?)

end

-- automatically in place
GamepassPurchaseHandlers["Unbreakable Button"] = function(player: Player, OnPurchase: boolean?)

end

-- automatically in place
GamepassPurchaseHandlers["Lucky Clover"] = function(player: Player, OnPurchase: boolean?)

end

return GamepassPurchaseHandlers