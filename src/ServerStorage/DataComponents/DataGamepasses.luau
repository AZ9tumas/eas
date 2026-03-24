local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Network)
local GamepassPurchaseHandlers = require(ServerStorage.PurchaseHandlers.GamepassPurchaseHandlers)
local DataHandler = require(ServerStorage.DataHandler)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Gamepasses = require(ReplicatedStorage.Shared.Info.Gamepasses)
local Types = require(ReplicatedStorage.Shared.Types)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)


local DataGamepasses = {}
DataGamepasses.OnGamepassUpdated = Signal.new() :: Signal.Signal<Player, string>

function DataGamepasses.init()
	local existingIds = {}
	for name, id in pairs(Gamepasses) do
		if table.find(existingIds, id) then
			warn("[DataGamepasses] Duplicate id for gamepass:", name)
		end
		table.insert(existingIds, id)

		if Types.Gamepasses[name] == nil then
			warn("[DataGamepasses] No profile data found for gamepass ownership:", name)
		end
		if GamepassPurchaseHandlers[name] == nil then
			warn("[DataGamepasses] No gamepass purchase handler found for:", name)
		end
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if not wasPurchased then 
			return 
		end

		local name: string?
		for _name, id in pairs(Gamepasses) do
			if gamepassId == id then
				name = _name
				break
			end
		end
		if name == nil then
			return
		end
		DataGamepasses.grantGamepass(player, name)
	end)
end

function DataGamepasses.playerAdded(player: Player)
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return
	end
	
	local GamepassesFolder = player:FindFirstChild("Gamepasses")
	if not GamepassesFolder then
		GamepassesFolder = Instance.new("Folder")
		GamepassesFolder.Name = "Gamepasses"
		GamepassesFolder.Parent = player
	end

	task.spawn(function()
		DataGamepasses.checkForOwnedGamepasses(player)
	end)
end

function DataGamepasses.checkForOwnedGamepasses(player: Player)
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return
	end
	
	while true do
		if not player:IsDescendantOf(Players) then return end

		local ClientSignaledLoaded = player:GetAttribute("ClientSignaledLoaded") ~= nil
		local ProfileLoaded = player:GetAttribute("ProfileLoaded") ~= nil

		if ClientSignaledLoaded and ProfileLoaded then
			break
		end

		task.wait(0.1)
	end
	
	for name, owned in pairs(profileData.Gamepasses) do
		if not owned then
			continue
		end
		task.spawn(function()
			DataGamepasses.doGamepassStuff(player, name) 
		end)
	end
	for name, gamepassId in pairs(Gamepasses) do
		local success, ownsGamepass = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, gamepassId)
		if not success or not ownsGamepass then 
			continue 
		end
		DataGamepasses.grantGamepass(player, name)
	end
end

function DataGamepasses.grantGamepass(player: Player, name: string, doNotIncreaseRobuxSpent: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then
		return
	end
	
	if Types.Gamepasses[name] == nil then
		warn("[DataGamepasses] Gamepass data doesn't exist for:", name)
		return
	end
	
	--if profileData.Gamepasses[name] == false then
	if not profileData.Gamepasses[name] then
		profileData.Gamepasses[name] = true
		clientData.Gamepasses(deepCopy(profileData.Gamepasses))

		local gamepassId = Gamepasses[name]
		if gamepassId ~= nil then
			local trove = Trove.new()
			trove:AttachToInstance(player)
			trove:AddPromise(getProductInfo(gamepassId, Enum.InfoType.GamePass):andThen(function(productInfo)
				if productInfo.PriceInRobux and productInfo.PriceInRobux > 0 then
					local cost = productInfo.PriceInRobux

					if not doNotIncreaseRobuxSpent then
						Network.Notifications.ProductBought:FireClient(player, productInfo.Name)
						
						-- Update player's RobuxSpent
						profileData.RobuxSpent += cost
						clientData.RobuxSpent(profileData.RobuxSpent)
					end
				else
					warn("Failed to get price for product ID:", gamepassId)
				end
			end))
		end
		
		-- Only apply effects the first time the player gets the gamepass
		DataGamepasses.doGamepassStuff(player, name, true)
		
		return true
	else
		return false
	end

	--DataGamepasses.doGamepassStuff(player, name)
end

function DataGamepasses.doGamepassStuff(player: Player, name: string, OnPurchase: boolean?)
	local gamepassHandler = GamepassPurchaseHandlers[name]
	--print(GamepassPurchaseHandlers, name)
	if gamepassHandler == nil then
		warn("[DataGamepasses] No gamepass handler found for:", name)
		return
	end
	
	local GamepassesFolder = player:FindFirstChild("Gamepasses")
	if not GamepassesFolder then
		GamepassesFolder = Instance.new("Folder")
		GamepassesFolder.Name = "Gamepasses"
		GamepassesFolder.Parent = player
	end
	
	local GamepassFound = GamepassesFolder:FindFirstChild(name)
	if not GamepassFound then
		local GamepassValue = Instance.new("BoolValue")
		GamepassValue.Name = name
		GamepassValue.Value = true
		GamepassValue.Parent = GamepassesFolder
	end
	
	gamepassHandler(player, OnPurchase)
end

return DataGamepasses