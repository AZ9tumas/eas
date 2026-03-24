local TraitIcons = {}

TraitIcons.Icons = {
	ServerLuck = {
		Image = "rbxassetid://76903787992362", -- TODO: replace
		DisplayName = "Server Luck",
		Priority = 1,
	},
	
	LuckyClover = {
		Image = "rbxassetid://76903787992362", -- TODO: replace
		DisplayName = "Lucky Clover",
		Priority = 2,
	},
	
	x2Luck = {
		Image = "rbxassetid://76903787992362", -- TODO: replace
		DisplayName = "x2 Luck",
		Priority = 3,
	},
	
	x2Cash = {
		Image = "rbxassetid://76903787992362", -- TODO: replace
		DisplayName = "x2 Cash",
		Priority = 4,
	},
	
	SuperSpeed = {
		Image = "rbxassetid://76903787992362", -- TODO: replace
		DisplayName = "Super Speed",
		Priority = 5,
	},

	MagicShield = {
		Image = "rbxassetid://76903787992362", -- TODO: replace
		DisplayName = "Magic Shield",
		Priority = 6,
	},
}

function TraitIcons.Get(stateName: string)
	return TraitIcons.Icons[stateName]
end

function TraitIcons.GetImage(stateName: string): string?
	local data = TraitIcons.Icons[stateName]
	return data and data.Image
end

function TraitIcons.GetAll()
	return TraitIcons.Icons
end

return TraitIcons