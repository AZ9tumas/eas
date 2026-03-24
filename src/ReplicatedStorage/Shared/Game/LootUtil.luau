local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local random = Random.new()

export type ChanceList = { 
    { Name: string, Chance: number, } 
}


local LootUtil = {}

-- Chance of getting literally nothing
function LootUtil.calculateItemChancesWithLuck(chanceList: ChanceList, luck: number): ChanceList
    chanceList = TableUtil.Copy(chanceList, true)

    local originalTotal = 0
    for _, item in ipairs(chanceList) do
        originalTotal += item.Chance
    end

    -- Apply luck to chance
    for _, item in ipairs(chanceList) do
        item.Chance = item.Chance + (luck / (item.Chance + 1))
    end
    
    local chanceOfGettingNothing = 100 - originalTotal 
    if chanceOfGettingNothing > 0 then
        table.insert(chanceList, { Name = "None", Chance = chanceOfGettingNothing })
    end

    local total = 0
    for _, item in ipairs(chanceList) do
        total += item.Chance
    end

    -- Normalize chances
    for _, item in ipairs(chanceList) do
        item.Chance = (item.Chance / total) * 100
    end
    
    return chanceList
end

function LootUtil.generateRandomItem(chanceList: ChanceList): (string?, number?)
    local total = 0
    for _, item in ipairs(chanceList) do
        total = total + item.Chance
    end

    local randomValue = random:NextNumber() * total
    local cumulativeChance = 0
    for _, item in ipairs(chanceList) do
        cumulativeChance = cumulativeChance + item.Chance
        if randomValue <= cumulativeChance then
            if item.Name == "None" then
                return nil
            end
            return item.Name, item.Chance
        end
    end
    
    return nil
end

-- No chance of not getting a pet
function LootUtil.calculateEggChancesWithLuck(chanceList: ChanceList, luck: number): ChanceList
    chanceList = TableUtil.Copy(chanceList, true)

    -- Apply luck to chance
    for _, item in ipairs(chanceList) do
        item.Chance = item.Chance + (luck / (item.Chance + 1))
    end

    local total = 0
    for _, item in ipairs(chanceList) do
        total = total + item.Chance
    end

    -- Normalize chances
    for _, item in ipairs(chanceList) do
        item.Chance = (item.Chance / total) * 100
    end
    
    return chanceList
end

function LootUtil.generateRandomPet(chanceList: ChanceList): string
    local total = 0
    for _, item in ipairs(chanceList) do
        total = total + item.Chance
    end

    local randomValue = random:NextNumber() * total
    local cumulativeChance = 0
    for _, item in ipairs(chanceList) do
        cumulativeChance = cumulativeChance + item.Chance
        if randomValue <= cumulativeChance then
            return item.Name
        end
    end
    
    return chanceList[1].Name
end

return LootUtil