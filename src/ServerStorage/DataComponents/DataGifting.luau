local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local DataHandler = require(ServerStorage.DataHandler)
local Network = require(ReplicatedStorage.Network)
local PlayerAttributes = require(ServerStorage.Modules.PlayerAttributes)
local Products = require(ReplicatedStorage.Shared.Info.Products)

local DataGifting = {}

-- Client
Network.Gifting.Select.OnServerEvent:Connect(function(player: Player, targetPlayerId: number, productName: string,
	productType: string
)
	if typeof(targetPlayerId) ~= "number" then
        return
	end
	
	if typeof(productName) ~= "string" then
		return
	end
	
	if typeof(productType) ~= "string" then
		return
	end
	
	local IsPass = productType == "Pass"
	local ProductType = IsPass and "Pass" or "Product"
	
	local Product = Products["Gifting | "..ProductType.." | " .. productName]
	if not Product then return end
	
	if targetPlayerId == player.UserId then return end
	
	local TargetPlayer: Player? = Players:GetPlayerByUserId(targetPlayerId)
	
	if TargetPlayer then
		if TargetPlayer == player then
			return
		end
		
		--if productType == "Product" then
		PlayerAttributes.setAttribute(player, "GiftTarget", targetPlayerId)
		Network.Purchases.promptProduct:FireClient(player, Product, true)
		--elseif productType == "Gamepass" then
		--	PlayerAttributes.setAttribute(player, "GiftTarget", targetPlayerId)
		--	Network.Purchases.promptGamepass:FireClient(player, Product)
		--end
	end
end)

return DataGifting