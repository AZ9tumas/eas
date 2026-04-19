local DataPlots = require(
	game:GetService("ServerStorage").DataComponents.DataPlots)

return function(_, players, eggName, amount)
	local given = 0
	for _, player in pairs(players) do
		for _ = 1, amount do
			DataPlots.GiveEgg(player, eggName, "Admin")
		end
		given += 1
	end

	return ("Gave %d x \"%s\" to %d player(s)."):format(amount, eggName, given)
end
