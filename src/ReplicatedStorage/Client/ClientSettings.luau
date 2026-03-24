local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Signal = require(ReplicatedStorage.Packages.Signal)
local CategorySignals = require(ReplicatedStorage.Shared.Classes.CategorySignals)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local ClientData = require(script.Parent.ClientData)
local Types = require(ReplicatedStorage.Shared.Types)
local SignalTable = require(ReplicatedStorage.Shared.Utility.Table.SignalTable)


local trove = Trove.new()
local categorySignals = CategorySignals.new()
local changedSignal = Signal.new()


type ClientSettings = Types.Settings & {
    settingChanged: (name: string) -> (Signal.Signal<string?>),
}

local ClientSettings = table.clone(Types.Settings) :: ClientSettings

function ClientSettings.settingChanged(name: string)
    return categorySignals:GetSignal(name)
end

ClientSettings = SignalTable(ClientSettings, {
    categorySignals = categorySignals,
    changedSignal = changedSignal,
})


local lastSent: Types.Settings
local disconnect: () -> ()
--warn(ClientData.Settings)
disconnect = Charm.subscribe(ClientData.Settings, function(settings)
    -- Only get the initial state because we want changes to be instant on the client; it should be our one source of truth.
    disconnect()

    for key, value in pairs(settings) do
        ClientSettings[key] = value
    end
    lastSent = table.clone(settings)
end)


-- Network
local function queueChanges()
    if lastSent == nil then
        return
    end

    -- Delay 0.1s before sending changes to the server (sliders go crazy)
    trove:Clean()
    trove:Add(task.delay(0.1, function()
        local changes = {} :: Types.Settings
        for key, lastValue: Types.Setting in pairs(table.clone(lastSent)) do
            local newValue = ClientSettings[key]
            if lastValue ~= newValue then
                changes[key] = newValue
                lastSent[key] = newValue
            end
        end
        if next(changes) == nil then
            return
        end
        Network.Settings.ClientUpdateSettings:FireServer(changes)
    end))
end
changedSignal:Connect(queueChanges)

return ClientSettings