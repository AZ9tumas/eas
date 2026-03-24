local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Network)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local ClientData = require(ReplicatedStorage.Client.ClientData)

local localPlayer = Players.LocalPlayer


local ClientDataSyncer = {}

function ClientDataSyncer.init()
    local syncer = CharmSync.client({ atoms = ClientData })

    local loaded = false
	Network.ClientData.Sync.OnClientEvent:Connect(function(payload)
        syncer:sync(payload)

		if not loaded then
            loaded = true
            localPlayer:SetAttribute("ClientDataLoaded",  true)
        end
    end)
end

return ClientDataSyncer