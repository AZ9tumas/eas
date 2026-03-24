local function getPlayerFullBackpack<T>(player: Player): {T}
	local result = {}

	for _, obj in player.Backpack:GetChildren() do
		table.insert(result, obj :: any)
	end

	if player.Character then
		for _, obj in player.Character:GetChildren() do
			table.insert(result, obj :: any)
		end
	end

	return result
end

return getPlayerFullBackpack
