local Gamepasses = {
	["Starter Pack"] = 1676865684,
	["VIP Status"] = 1674447450,
	["Unbreakable Button"] = 1673944119,
	["Auto-Collect"] = 1674209886,
	["Index Reader"] = 1683271610, -- Permanent Income Multiplier.
	["Triple Hatch"] = 1674161903, -- Permanent Mass Hatching.
	["Lucky Clover"] = 1674560397, -- Permanent Luck Boost.
	["Magic Shield (Perm)"] = 1674301793, -- Permanent protection from Cloning.
}


export type Gamepasses = typeof(Gamepasses)

return Gamepasses :: Gamepasses & {
	[string]: number,
}