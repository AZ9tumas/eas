local cooldowns = {} :: {
    [string]: number
}


local SimpleCooldowns = {}

function SimpleCooldowns.isOnCooldown(str: string): boolean
    local lastCooldown = cooldowns[str]
    if lastCooldown == nil then
        return false
    else
        return time() - lastCooldown < 0
    end
end

function SimpleCooldowns.setCooldown(str: string, cooldown: number)
    cooldowns[str] = time() + cooldown
end

function SimpleCooldowns.removeCooldown(str: string)
    cooldowns[str] = nil
end

return SimpleCooldowns