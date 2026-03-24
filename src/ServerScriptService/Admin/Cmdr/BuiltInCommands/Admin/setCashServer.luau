local DataCash = require(
	game:GetService("ServerStorage").DataComponents.DataCash)

return function (_, players, value)
	for _, player in pairs(players) do
		DataCash.setCash(player, value)
	end

	return ("Updated cash for %d players to %d."):format(#players, value)
end