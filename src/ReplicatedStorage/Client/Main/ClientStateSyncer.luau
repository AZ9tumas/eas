local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Network)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local SyncedState = require(ReplicatedStorage.Shared.SyncedState)


local ClientStateSyncer = {}

function ClientStateSyncer.init()
    local syncer = CharmSync.client({ atoms = SyncedState })

    Network.State.Sync.OnClientEvent:Connect(function(payload)
        syncer:sync(payload)
    end)
    Network.State.Request:FireServer()
end

return ClientStateSyncer