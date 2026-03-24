local PlayerAttributes = require(script.Parent.PlayerAttributes)


local PlayerCooldowns = {}

function PlayerCooldowns.setCooldown(player: Player, attribute: string, cooldown: number)
    local now = workspace:GetServerTimeNow()
    local currentCD = PlayerAttributes.getAttribute(player, attribute) :: number?
    if currentCD and currentCD - now > cooldown then
        return
    end
    PlayerAttributes.setAttribute(player, attribute, now + cooldown)
end

function PlayerCooldowns.removeCooldown(player: Player, attribute: string)
    PlayerAttributes.setAttribute(player, attribute)
end

function PlayerCooldowns.getCooldown(player: Player, attribute: string) : number
    local value = PlayerAttributes.getAttribute(player, attribute) :: number?
    if value == nil then
        return 0
    end
    return math.max(0, value - workspace:GetServerTimeNow())
end

function PlayerCooldowns.isOnCooldown(player: Player, attribute: string) : boolean
    local value = PlayerAttributes.getAttribute(player, attribute) :: number?
    if value == nil then
        return false
    end
    return value and value - workspace:GetServerTimeNow() > 0
end

return PlayerCooldowns