local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Network)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)
local DataHandler = require(ServerStorage.DataHandler)
local Types = require(ReplicatedStorage.Shared.Types)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)
local generateGUID = require(ReplicatedStorage.Shared.Utility.String.generateGUID)
local copyAttributesFromTable = require(ReplicatedStorage.Shared.Utility.Roblox.copyAttributesFromTable)

local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)

local Eggs = ReplicatedStorage.Assets.Eggs
local EggTools = ReplicatedStorage.Assets.EggTools

local EggsDataFolder = ReplicatedStorage.Data.Eggs

local NotifyError = Network.Notifications.Error
local NotifySuccess = Network.Notifications.Success

local DataBackpack = {
	Eggs = {},
	Brainrots = {},
}


local function destroyToolById(player: Player, id: string)
	if not player:IsDescendantOf(Players) then return end

	-- Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("Id") == id then
				tool:Destroy()
			end
		end
	end

	-- Character
	local character = player.Character
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("Id") == id then
				tool:Destroy()
			end
		end
	end
end

-- General Methods

function DataBackpack.getBackpack(player: Player): Types.Backpack?
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end
	return profileData.Backpack
end

function DataBackpack.getBackpackEggs(player: Player): { Types.Egg }?
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end
	return profileData.Backpack.Eggs
end

function DataBackpack.getBackpackBrainrots(player: Player): { Types.Brainrot }?
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end
	return profileData.Backpack.Brainrots
end


-- Brainrots Methods

function DataBackpack.Brainrots.getLength(player: Player): number?
	local profileData = DataHandler.getProfileData(player)
	if not profileData then
		return nil
	end

	local brainrots = profileData.Backpack.Brainrots
	if not brainrots then
		return 0
	end

	return #brainrots
end

function DataBackpack.Brainrots.getById(player: Player, id: number): Types.Brainrot?
	local profileData = DataHandler.getProfileData(player)
	if not profileData then
		return nil
	end

	for _, brainrot in profileData.Backpack.Brainrots do
		if brainrot.Id == id then
			return brainrot
		end
	end

	return nil
end

function DataBackpack.Brainrots.getByName(player: Player, name: string): Types.Brainrot?
	local profileData = DataHandler.getProfileData(player)
	if not profileData then
		return nil
	end

	for _, brainrot in profileData.Backpack.Brainrots do
		if brainrot.Name == name then
			return brainrot
		end
	end

	return nil
end

function DataBackpack.Brainrots.add(
	player: Player,
	brainrot: Types.Brainrot,
	DONTupdateClient: boolean?
)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then
		return nil
	end

	table.insert(profileData.Backpack.Brainrots, brainrot)

	if clientData and not DONTupdateClient then
		clientData.Backpack(deepCopy(profileData.Backpack))
	end

	return true
end

function DataBackpack.Brainrots.removeById(
	player: Player,
	id: number,
	DONTupdateClient: boolean?
)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then
		return nil
	end

	for i = #profileData.Backpack.Brainrots, 1, -1 do
		if profileData.Backpack.Brainrots[i].Id == id then
			table.remove(profileData.Backpack.Brainrots, i)

			if clientData and not DONTupdateClient then
				destroyToolById(player, id)
				clientData.Backpack(deepCopy(profileData.Backpack))
			end

			return true
		end
	end

	return false
end

function DataBackpack.Brainrots.EquipAll(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	for _, brainrot in profileData.Backpack.Brainrots do
		local BrainrotTool: Tool = PlotUtil.getHatchableTool(brainrot.Name)
		if BrainrotTool == nil then continue end

		local MutationName = PlotUtil.MutationTierToName(brainrot.MutationTier)
		if MutationName == nil then continue end

		local BrainrotToolClone = BrainrotTool:Clone()
		PlotUtil.setHatchableInfoUI(BrainrotToolClone, MutationName,
			brainrot.IsMutating, brainrot
		)

		for name, value in brainrot do
			BrainrotToolClone:SetAttribute(name, value)
		end
		BrainrotToolClone:SetAttribute("Placeable", true)

		BrainrotToolClone.Parent = player.Backpack
	end
end

function DataBackpack.Brainrots.addToBackpackByInstance(
	player: Player, Brainrot: Model | Tool, equipToolToCharacter: boolean?, DONTupdateClient: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	local BrainrotInfo = Brainrot:GetAttributes()
	if BrainrotInfo == nil then return end

	BrainrotInfo.ParentIndex = nil

	table.insert(profileData.Backpack.Brainrots, BrainrotInfo)

	if clientData then
		if not DONTupdateClient then
			Brainrot:SetAttribute("Placeable", true)

			PlotUtil.addMutationEffect(Brainrot, BrainrotInfo.MutationTier)

			local MutationName = PlotUtil.MutationTierToName(BrainrotInfo.MutationTier)
			PlotUtil.setHatchableInfoUI(Brainrot, MutationName, BrainrotInfo.IsMutating, BrainrotInfo)

			local PlayerBackpack = player:FindFirstChild("Backpack")
			if PlayerBackpack then
				if not equipToolToCharacter then
					Brainrot.Parent = PlayerBackpack
				else
					local character = player.Character
					local Humanoid: Humanoid = character and character:FindFirstChild("Humanoid")

					if Humanoid then
						Humanoid:UnequipTools()
						Brainrot.Parent = character 
					else
						Brainrot.Parent = PlayerBackpack
					end
				end
			end

			clientData.Backpack(deepCopy(profileData.Backpack))
		end
	end
	return true
end

function DataBackpack.Brainrots.ResetAll(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if not profileData then
		return
	end

	profileData.Backpack.Brainrots = {}

	local playerBack = player:FindFirstChild("Backpack")
	if playerBack then
		local character = player.Character
		if character then
			for _, tool in character:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("Type") == "Brainrot" then
					tool:Destroy()
				end
			end
		end

		for _, tool in playerBack:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute("Type") == "Brainrot" then
				tool:Destroy()
			end
		end
	end

	if clientData then
		clientData.Backpack(deepCopy(profileData.Backpack))
	end
end

-- Eggs Methods

function DataBackpack.Eggs.getLength(player: Player): number?
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	local count = 0
	for _, egg in profileData.Backpack.Eggs do
		count += 1
	end

	return count
end

function DataBackpack.Eggs.getAllBackpackEggs(player: Player): { Types.Egg }?
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	return profileData.Backpack.Eggs
end

function DataBackpack.Eggs.getBackpackEgg(player: Player, eggName: string): Types.Egg?
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	for _, egg in profileData.Backpack.Eggs do
		if egg.Name == eggName then
			return egg
		end
	end
end

function DataBackpack.Eggs.getBackpackEggByID(player: Player, id: string): Types.Egg?
	local profileData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	for _, egg in profileData.Backpack.Eggs do
		if egg.Id == id then
			return egg
		end
	end
end

function DataBackpack.Eggs.removeBackpackEgg(
	player: Player,
	eggName: string,
	removeAll: boolean?,
	DONTupdateClient: boolean?
)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	local eggs = profileData.Backpack.Eggs
	local removed = false

	if removeAll then
		-- go backwards so indexes don't break
		for i = #eggs, 1, -1 do
			local egg = eggs[i]
			if egg.Name == eggName then
				destroyToolById(player, egg.Id)
				table.remove(eggs, i)
				removed = true
			end
		end
	else
		for index, egg in ipairs(eggs) do
			if egg.Name == eggName then
				destroyToolById(player, egg.Id)
				table.remove(eggs, index)
				removed = true
				break
			end
		end
	end

	if removed then
		if clientData and not DONTupdateClient then
			clientData.Backpack(deepCopy(profileData.Backpack))
		end
	end

	return removed
end

function DataBackpack.Eggs.removeBackpackEggByID(player: Player, id: string, DONTupdateClient: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	for index, egg in ipairs(profileData.Backpack.Eggs) do
		if egg.Id == id then
			destroyToolById(player, id)
			table.remove(profileData.Backpack.Eggs, index)

			if clientData and not DONTupdateClient then
				clientData.Backpack(deepCopy(profileData.Backpack))
			end

			return true
		end
	end

	return false
end

function DataBackpack.Eggs.addBackpackEgg(player: Player, egg: Types.Egg, DONTupdateClient: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	table.insert(profileData.Backpack.Eggs, egg)
	if clientData and not DONTupdateClient then
		clientData.Backpack(deepCopy(profileData.Backpack))
	end
	return true
end

function DataBackpack.Eggs.GetEggInfo(egg: Model)
	local eggInfo = {
		Name = egg:GetAttribute("Name") or egg.Name,
		Id = egg:GetAttribute("Id") or generateGUID(),
		Type = "Block",
		EggMutationTier = egg:GetAttribute("EggMutationTier") or 1,

		IsExclusive = egg:GetAttribute("IsExclusive") or false,
		ObtainedFrom = egg:GetAttribute("ObtainedFrom"),

		PriceOnly = egg:GetAttribute("PriceOnly") or false,

		CanBeStolen = egg:GetAttribute("CanBeStolen") or true,
		CanBeTraded = egg:GetAttribute("CanBeTraded") or true,

		-- Event metadata
		EventName = egg:GetAttribute("EventName"),
		EventCurrencyCost = egg:GetAttribute("EventCurrencyCost"),
	} :: Types.Egg

	return eggInfo
end

function DataBackpack.Eggs.addBackpackEggByInstance(
	player: Player, egg: Model | Tool, equipToolToCharacter: boolean?, DONTupdateClient: boolean?)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil then
		return nil
	end

	local eggInfo = DataBackpack.Eggs.GetEggInfo(egg)
	if eggInfo == nil then return end

	table.insert(profileData.Backpack.Eggs, eggInfo)

	PlotUtil.addMutationEffect(egg, eggInfo.EggMutationTier)
	egg:SetAttribute("Placeable", true)

	if clientData then
		if not DONTupdateClient then
			local PlayerBackpack = player:FindFirstChild("Backpack")
			if PlayerBackpack then
				if not equipToolToCharacter then
					egg.Parent = PlayerBackpack
				else
					local character = player.Character
					local Humanoid: Humanoid = character and character:FindFirstChild("Humanoid")

					if Humanoid then
						Humanoid:UnequipTools()
						egg.Parent = character 
					else
						egg.Parent = PlayerBackpack
					end
				end
			end

			clientData.Backpack(deepCopy(profileData.Backpack))
		end
	end
	return true
end

function DataBackpack.Eggs.EquipAll(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	for _, egg in profileData.Backpack.Eggs do
		local EggTool: Tool = PlotUtil.getEggTool(egg.Name)
		if EggTool == nil then continue end

		local EggToolClone = EggTool:Clone()
		PlotUtil.setEggPriceInfoUI(EggToolClone, egg.PriceOnly)

		for name, value in egg do
			EggToolClone:SetAttribute(name, value)
		end

		EggToolClone:SetAttribute("Placeable", true)
		EggToolClone.Parent = player.Backpack
	end
end

function DataBackpack.Eggs.ResetAll(player: Player)
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	profileData.Backpack.Eggs = {}

	local playerBack = player:FindFirstChild("Backpack")
	if playerBack then
		local character = player.Character
		if character then
			for _, tool in character:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("Type") == "Block" then
					tool:Destroy()
				end
			end
		end

		for _, tool in playerBack:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute("Type") == "Block" then
				tool:Destroy()
			end
		end
	end

	clientData.Backpack(deepCopy(profileData.Backpack))
end

function DataBackpack.characterAdded(player: Player, character: Model) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	--print(profileData, clientData)
end

function DataBackpack.earlyPlayerAdded(player: Player) -- automatic

end

function DataBackpack.playerAdded(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	--warn(player.Name, "data loaded")
	--print(profileData, clientData)
end

function DataBackpack.playerRemoving(player: Player) -- automatic
	local profileData, clientData = DataHandler.getProfileData(player)
	if profileData == nil or clientData == nil then return end

	--warn(player.Name, "data unloading")
end

function DataBackpack.latePlayerRemoving(player: Player) -- automatic

end

return DataBackpack