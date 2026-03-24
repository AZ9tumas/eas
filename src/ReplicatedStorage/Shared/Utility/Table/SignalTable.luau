--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local CategorySignals = require(ReplicatedStorage.Shared.Classes.CategorySignals)


return function(tbl, signals: {
    categorySignals: CategorySignals.CategorySignals?, 
    changedSignal: Signal.Signal<string>?
})
    local tbl2 = tbl
    tbl = setmetatable({}, { 
        __index = tbl,
        __newindex = function(self, index, value)
            if rawget(tbl2, index) == nil then
                -- Realistically i am only gonna use this function for ClientData so let's error using that
                warn(`[ClientData] Cannot create new index '{index}!'`)
                return
            end
            rawset(tbl2, index, value)

            local categorySignals, changedSignal = signals.categorySignals, signals.changedSignal
            if categorySignals then
                categorySignals:Fire(index)
            end
            if changedSignal then
                changedSignal:Fire(index)
            end
        end
    })
    return tbl
end
