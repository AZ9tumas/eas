local Players = game:GetService("Players")

return function(team: Team) : { Player }
    local players: { Player } = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team ~= team then
            continue
        end
        table.insert(players, player)
    end
    return players
end