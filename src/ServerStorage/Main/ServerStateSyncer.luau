local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Network)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local SyncedState = require(ReplicatedStorage.Shared.SyncedState)


local ServerStateSyncer = {}

function ServerStateSyncer.init()
    local syncer = CharmSync.server({ atoms = SyncedState })

    syncer:connect(function(player, payload)
        Network.State.Sync:FireClient(player, payload)
    end)

    Network.State.Request.OnServerEvent:Connect(function(player)
        syncer:hydrate(player)
    end)
end

return ServerStateSyncer