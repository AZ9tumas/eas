local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local DataHandler = require(ServerStorage.DataHandler)
local Network = require(ReplicatedStorage.Network)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Settings = require(ReplicatedStorage.Shared.Info.Settings)
local Types = require(ReplicatedStorage.Shared.Types)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)

local Tools = ServerStorage.Tools

local DataItems = {}

function DataItems.giveItem(player: Player, toolName: string)
    local profileData, clientData = DataHandler.getProfileData(player)
	assert(profileData, clientData)

	local tool: Tool = Tools:FindFirstChild(toolName)
	if not tool then return end
	
	local character = player.Character
	if character and character:FindFirstChild(toolName) then return end
	
	local Backpack = player:FindFirstChild("Backpack")
	if not Backpack then return end
	
	if not Backpack:FindFirstChild(toolName) then
		tool:Clone().Parent = Backpack
	end
end

return DataItems