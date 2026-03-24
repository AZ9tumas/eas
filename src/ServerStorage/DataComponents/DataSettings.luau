local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataHandler = require(ServerStorage.DataHandler)
local Network = require(ReplicatedStorage.Network)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Settings = require(ReplicatedStorage.Shared.Info.Settings)
local Types = require(ReplicatedStorage.Shared.Types)
local deepCopy = require(ReplicatedStorage.Shared.Utility.Table.deepCopy)


local validSettingNames = TableUtil.Keys(Types.Settings)
local totalSettings = #validSettingNames


local DataSettings = {}
DataSettings.OnSettingUpdated = Signal.new() :: Signal.Signal<Player, string, number | boolean | string>

function DataSettings.playerAdded(player: Player)
    local profileData, clientData = DataHandler.getProfileData(player)
    assert(profileData, clientData)

    local updated = false
    for name in pairs(table.clone(profileData.Settings)) do
        if Types.Settings[name] == nil then
            updated = true
            profileData.Settings[name] = nil
        end
    end
    if updated then
        clientData.Settings(deepCopy(profileData.Settings))
    end
end

function DataSettings.getSetting(player: Player, name: string): Types.Setting?
    local profileData = DataHandler.getProfileData(player)
    if profileData == nil then
        return nil
    end
    return profileData.Settings[name]
end

function DataSettings.updateSettings(player: Player, changes: Types.Settings)
    local profileData, clientData = DataHandler.getProfileData(player)
    assert(profileData, clientData)

    local i = 1
    for name, value in pairs(changes) do
        i += 1
        if i > totalSettings then
            warn("[DataSettings] Player has too many setting changes queued!", player.Name)
            return
        end
        local settingInfo = Settings[name]
        if settingInfo == nil then
            warn(`[DataSettings] Somehow setting info doesn't exist for {name}?`)
            return
        end
        if profileData.Settings[name] == value then
            continue
        end

        local settingType = settingInfo.Data.Type
        if settingType == "Toggle" then
            if type(value) ~= "boolean" then
                return
			end
		elseif settingType == "Numbers" then
			if type(value) ~= "number" then
				return
			end
        else
            warn("[DataSettings] No setting type for:", name)
            continue
        end
        profileData.Settings[name] = value
    end
    clientData.Settings(deepCopy(profileData.Settings))
end

-- Client
Network.Settings.ClientUpdateSettings.OnServerEvent:Connect(function(player, changes)  
    if type(changes) ~= "table" then
        return
    end
    DataSettings.updateSettings(player, changes :: any)
end)

return DataSettings