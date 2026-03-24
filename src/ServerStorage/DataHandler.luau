local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local IgnoreDataStoreCheck = require(ReplicatedStorage.Client.ClientData.IgnoreDataStoreCheck)
local Network = require(ReplicatedStorage.Network)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)
local deepCopyAtoms = require(ReplicatedStorage.Shared.Utility.Table.deepCopyAtoms)

local BadgesInfo = require(ReplicatedStorage.Shared.Info.Badges)

local ProfileTemplate = require(ServerScriptService:WaitForChild("PlayerData"):WaitForChild("PlayerDataStore")
	:WaitForChild("DefaultData")
)

local dataComponents = ServerStorage:WaitForChild("DataComponents")

local function getSortedDataModules()
	local modules = {}
	for _, module in ipairs(dataComponents:GetChildren()) do
		if module:IsA("ModuleScript") then
			table.insert(modules, module)
		end
	end
	table.sort(modules, function(a, b)
		local aOrder = a:GetAttribute("LoadOrder") or 1
		local bOrder = b:GetAttribute("LoadOrder") or 1
		return aOrder < bOrder
	end)
	return modules
end

local CachedSortedDataModules = {}

local DataHandler = {}
local PlayerDataStoreGetDataFunc = nil

DataHandler.ClientData = {} :: { [Player]: {
	Data: typeof(ClientData),
	Trove: Trove.Trove
}}

function DataHandler.giveBadge(player: Player, badgeName: string)
	if not player:IsDescendantOf(Players) then return end
	
	local Profile = DataHandler.getProfile(player)
	if not Profile then return end
	
	local badgeId = BadgesInfo[badgeName]
	if not badgeId then return end
	
	if Profile.Badges[badgeId] then return end
	
	local result = DataHandler.giveBadgeClassic(player, badgeId)
	
	if result then
		Profile.Badges[badgeId] = true
		
		--print("Gave Player Badge:", player.Name, badgeName)
	else
		warn("Failed to give Player Badge:", player.Name, badgeName)
	end
	
	return result
end

function DataHandler.giveBadgeClassic(player: Player, badgeId: number)
	-- Fetch badge information
	local success, badgeInfo = pcall(BadgeService.GetBadgeInfoAsync, BadgeService, badgeId)
	if success then
		-- Confirm that badge can be awarded
		if badgeInfo.IsEnabled then
			-- Award badge
			local awarded, errorMessage = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badgeId)
			if not awarded then
				warn("Error while awarding badge:", errorMessage)
			else
				return true
			end
		end
	else
		warn("Error while fetching badge info!")
	end
end

function DataHandler.init(GetDataFunc)
	PlayerDataStoreGetDataFunc = GetDataFunc
	
	CachedSortedDataModules = getSortedDataModules()
	
	--for _, dataComponentModule in ipairs(dataComponents:GetChildren()) do
	for _, dataComponentModule in ipairs(CachedSortedDataModules) do
		if not dataComponentModule:IsA("ModuleScript") then continue end
		local dataComponent = (require)(dataComponentModule)
		if dataComponent.init then
			dataComponent.init()
		end
	end
end

function DataHandler.waitForPlayerData(player: Player): (typeof(ProfileTemplate)?, typeof(ClientData)?)
	while true do
		-- player left
		if not player:IsDescendantOf(Players) then
			return nil
		end

		local profile, clientData = DataHandler.getProfileData(player)
		if profile and clientData then
			return profile, clientData
		end

		task.wait(0.05)
	end
end

function DataHandler.getProfile(player: Player): typeof(ProfileTemplate)?
	if PlayerDataStoreGetDataFunc == nil then return nil end

	local profileData = PlayerDataStoreGetDataFunc(player, true)
	if profileData == nil then return end

	return profileData
end

function DataHandler.getProfileData(player: Player): (typeof(ProfileTemplate)?, typeof(ClientData)?)
	if PlayerDataStoreGetDataFunc == nil then return nil end
	
	local profileData = PlayerDataStoreGetDataFunc(player, true)
	if profileData == nil then return end
	
	local clientData = DataHandler.ClientData[player]
	if clientData == nil then
		return nil
	end
	return profileData, clientData.Data
end

-- Products
local PURCHASE_ID_CACHE_SIZE = 100
function DataHandler.purchaseIdCheckAsync(profileData, purchase_id, grant_product): Enum.ProductPurchaseDecision
	-- Waits until purchase_id is confirmed to be saved to the DataStore or the profile session has ended

	local purchase_id_cache = profileData.PurchaseIdCache :: {number}?
	if purchase_id_cache == nil then
		purchase_id_cache = {}
		profileData.PurchaseIdCache = purchase_id_cache
	end
	if purchase_id_cache == nil then
		warn(`[First] Failed to process receipt:`, purchase_id)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end



	-- Compatibility with ProfileService
	--local metaData = profile.MetaData
	--if metaData ~= nil then
	--	local localPurchaseIds = metaData.MetaTags.ProfilePurchaseIds :: {number}?
	--	if localPurchaseIds then
	--		for _, purchaseId in pairs(localPurchaseIds) do
	--			if table.find(purchase_id_cache, purchaseId) == nil then
	--				table.insert(purchase_id_cache, purchaseId)
	--			end
	--		end
	--	end
	--end

	-- Granting product if not received:

	if table.find(purchase_id_cache, purchase_id) == nil then

		local success, result = pcall(grant_product)
		if success ~= true then
			--warn(`Failed to process receipt:`, profile.Key, purchase_id, result)
			warn(`Failed to process receipt:`, purchase_id, result)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		while #purchase_id_cache >= PURCHASE_ID_CACHE_SIZE do
			table.remove(purchase_id_cache, 1)
		end

		table.insert(purchase_id_cache, purchase_id)

	end

	-- Waiting until the purchase is confirmed to be saved to the DataStore:

	local function is_purchase_saved()
		--local saved_cache = profile.LastSavedData.PurchaseIdCache :: {number}?
		local saved_cache = profileData.PurchaseIdCache :: {number}?
		return if saved_cache ~= nil then table.find(saved_cache, purchase_id) ~= nil else false
	end

	if is_purchase_saved() == true then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	--while profile:IsActive() == true do

	--	local last_saved_data = profile.LastSavedData

	--	profile:Save()

	--	if profile.LastSavedData == last_saved_data then
	--		profile.OnAfterSave:Wait()
	--	end

	--	if is_purchase_saved() == true then
	--		return Enum.ProductPurchaseDecision.PurchaseGranted
	--	end

	--	if profile:IsActive() == true then
	--		task.wait(10)
	--	end

	--end

	warn(`[Last] Failed to process receipt:`, purchase_id)
	return Enum.ProductPurchaseDecision.NotProcessedYet

end

DataHandler.playerAdded = function<T>(player: Player, profileData: T)
	if PlayerDataStoreGetDataFunc then
		profileData = PlayerDataStoreGetDataFunc(player, true) or profileData
	end
	
	-- 1. Copy atoms for this player
	local clientData = deepCopyAtoms(ClientData)

	-- 2. Load profile data into atoms
	for key in pairs(clientData) do
		local value = (profileData :: any)[key]
		if value == nil and not IgnoreDataStoreCheck[key] then
			warn("[ClientDataComponent] Missing value for key:", key)
			continue
		end
		clientData[key](deepCopy(value))
	end

	-- 3. Set up Charm syncer
	local syncer = CharmSync.server({
		atoms = clientData,
	})

	local trove = Trove.new()

	-- 4. Connect sync events
	trove:Add(syncer:connect(function(_player, payload)
		if _player ~= player then
			return
		end
		Network.ClientData.Sync:FireClient(player, payload)
	end))

	-- 5. Hydrate player
	syncer:hydrate(player)

	DataHandler.ClientData[player] = {
		Data = clientData,
		Trove = trove,
	}
	
	--for _, dataComponentModule in ipairs(dataComponents:GetChildren()) do
	for _, dataComponentModule in ipairs(CachedSortedDataModules) do
		if not dataComponentModule:IsA("ModuleScript") then
			continue
		end

		local success, dataComponent = pcall(require, dataComponentModule)
		if not success then
			warn(("[PlayerDataStore - DataHandler] Failed to require %s: %s"):format(dataComponentModule.Name, tostring(dataComponent)))
			continue
		end

		if typeof(dataComponent) ~= "table" then
			warn(("[PlayerDataStore - DataHandler] Module %s did not return a table."):format(dataComponentModule.Name))
			continue
		end

		local func = dataComponent.playerAdded
		if typeof(func) == "function" then
			local ok, err = pcall(func, player)
			if not ok then
				warn(("[PlayerDataStore - DataHandler] Error in %s.playerAdded: %s"):format(dataComponentModule.Name, tostring(err)))
			end
		end
	end
end

DataHandler.playerRemoving = function(player: Player)
	--for _, dataComponentModule in ipairs(dataComponents:GetChildren()) do
	for _, dataComponentModule in ipairs(CachedSortedDataModules) do
		if not dataComponentModule:IsA("ModuleScript") then
			continue
		end

		local success, dataComponent = pcall(require, dataComponentModule)
		if not success then
			warn(("[PlayerDataStore - DataHandler] Failed to require %s: %s"):format(dataComponentModule.Name, tostring(dataComponent)))
			continue
		end

		if typeof(dataComponent) ~= "table" then
			warn(("[PlayerDataStore - DataHandler] Module %s did not return a table."):format(dataComponentModule.Name))
			continue
		end

		local func = dataComponent.playerRemoving
		if typeof(func) == "function" then
			local ok, err = pcall(func, player)
			if not ok then
				warn(("[PlayerDataStore - DataHandler] Error in %s.playerRemoving: %s"):format(dataComponentModule.Name, tostring(err)))
			end
		end
	end
	
	local clientDataHolder = DataHandler.ClientData[player]
	if clientDataHolder then
		clientDataHolder.Trove:Destroy()
		DataHandler.ClientData[player] = nil
	end
end

DataHandler.characterAdded = function<T>(player: Player)
	local function Update(character: Model)
		for _, dataComponentModule in ipairs(CachedSortedDataModules) do
			if not dataComponentModule:IsA("ModuleScript") then
				continue
			end

			local success, dataComponent = pcall(require, dataComponentModule)
			if not success then
				warn(("[PlayerDataStore - DataHandler] Failed to require %s: %s"):format(dataComponentModule.Name, tostring(dataComponent)))
				continue
			end

			if typeof(dataComponent) ~= "table" then
				warn(("[PlayerDataStore - DataHandler] Module %s did not return a table."):format(dataComponentModule.Name))
				continue
			end

			local func = dataComponent.characterAdded
			if typeof(func) == "function" then
				local ok, err = pcall(func, player, character)
				if not ok then
					warn(("[PlayerDataStore - DataHandler] Error in %s.characterAdded: %s"):format(dataComponentModule.Name, tostring(err)))
				end
			end
		end
	end
	
	if player.Character then
		Update(player.Character)
	end
	
	player.CharacterAdded:Connect(Update)
end

DataHandler.earlyPlayerAdded = function<T>(player: Player)
	for _, dataComponentModule in ipairs(CachedSortedDataModules) do
		if not dataComponentModule:IsA("ModuleScript") then
			continue
		end

		local success, dataComponent = pcall(require, dataComponentModule)
		if not success then
			warn(("[PlayerDataStore - DataHandler] Failed to require %s: %s"):format(dataComponentModule.Name, tostring(dataComponent)))
			continue
		end

		if typeof(dataComponent) ~= "table" then
			warn(("[PlayerDataStore - DataHandler] Module %s did not return a table."):format(dataComponentModule.Name))
			continue
		end

		local func = dataComponent.earlyPlayerAdded
		if typeof(func) == "function" then
			local ok, err = pcall(func, player)
			if not ok then
				warn(("[PlayerDataStore - DataHandler] Error in %s.earlyPlayerAdded: %s"):format(dataComponentModule.Name, tostring(err)))
			end
		end
	end
end

DataHandler.latePlayerRemoving = function(player: Player)
	for _, dataComponentModule in ipairs(CachedSortedDataModules) do
		if not dataComponentModule:IsA("ModuleScript") then
			continue
		end

		local success, dataComponent = pcall(require, dataComponentModule)
		if not success then
			warn(("[PlayerDataStore - DataHandler] Failed to require %s: %s"):format(dataComponentModule.Name, tostring(dataComponent)))
			continue
		end

		if typeof(dataComponent) ~= "table" then
			warn(("[PlayerDataStore - DataHandler] Module %s did not return a table."):format(dataComponentModule.Name))
			continue
		end

		local func = dataComponent.latePlayerRemoving
		if typeof(func) == "function" then
			local ok, err = pcall(func, player)
			if not ok then
				warn(("[PlayerDataStore - DataHandler] Error in %s.latePlayerRemoving: %s"):format(dataComponentModule.Name, tostring(err)))
			end
		end
	end
end

Network.ClientData.ClientSignaledLoaded.OnServerEvent:Connect(function(player: Player)
	player:SetAttribute("ClientSignaledLoaded", true)
end)

return DataHandler
