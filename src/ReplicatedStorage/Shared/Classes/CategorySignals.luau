local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)


local CategorySignals = {}
CategorySignals.__index = CategorySignals

function CategorySignals.new()
    local self = setmetatable({}, CategorySignals)
    self._categories = {} :: {
        [string]: Signal.Signal<string?>
    }

    return self
end

export type CategorySignals = typeof(CategorySignals.new())

function CategorySignals.GetSignal(self: CategorySignals, category: string)
    -- Create new signal if key doesn't exist
    if not self._categories[category] then
        self._categories[category] = Signal.new()
    end

    return self._categories[category]
end

function CategorySignals.Connect(self: CategorySignals, category: string, fn: (index: string?) -> ())
    -- Create new signal if key doesn't exist
    if not self._categories[category] then
        self._categories[category] = Signal.new()
    end

    return self._categories[category]:Connect(fn)
end

function CategorySignals.Fire(self: CategorySignals, category: string, index: string?)
    -- Create new signal if key doesn't exist
    local signal = self._categories[category]
    if signal == nil then
        -- warn(`[CategorySignals] No signal found in category: {category}`)
        return
    end
    signal:Fire(index)
end

return CategorySignals