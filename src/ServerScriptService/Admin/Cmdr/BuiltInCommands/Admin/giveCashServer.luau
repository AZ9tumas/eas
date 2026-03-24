local DataCash = require(
	game:GetService("ServerStorage").DataComponents.DataCash)

return function (_, players, value)
	for _, player in pairs(players) do
		DataCash.giveCash(player, value, true)
	end

	return ("Gave %d cash to %d players."):format(value, #players)
end