--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)


export type ChangedEventUnion = {
    Changed: Signal.Signal<string>
}

return function(tbl)
    type tbl = typeof(tbl)

    local tbl2 = tbl

    local signal = Signal.new() :: Signal.Signal<string>
    tbl.Changed = signal
    tbl = setmetatable({}, { 
        __index = tbl,
        __newindex = function(self, index, value)
            if rawget(tbl2, index) == nil and typeof(value) ~= typeof(signal) then
                -- Realistically i am only gonna use this function for ClientData so let's error using that
                warn(`[ClientData] Cannot create new index '{index}!'`)
                return
            end

            signal:Fire(index)

            rawset(tbl2, index, value)
        end
    })
    print(tbl2)

    return tbl :: tbl & ChangedEventUnion
end
