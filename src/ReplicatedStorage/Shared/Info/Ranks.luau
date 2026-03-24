local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)

local Ranks = {
	--{Name = "Noob", XP = 0, Color = Color3.fromRGB(255, 255, 255)},
	--{Name = "Beginner", XP = 10, Color = Color3.fromRGB(200, 255, 200)},
	--{Name = "Learner", XP = 20, Color = Color3.fromRGB(150, 255, 150)},
	--{Name = "Rookie", XP = 30, Color = Color3.fromRGB(100, 255, 100)},
	--{Name = "Novice", XP = 40, Color = Color3.fromRGB(50, 255, 100)},
	--{Name = "Intermediate", XP = 60, Color = Color3.fromRGB(255, 255, 0)},
	--{Name = "Skilled", XP = 80, Color = Color3.fromRGB(255, 220, 0)},
	--{Name = "Adept", XP = 100, Color = Color3.fromRGB(255, 190, 0)},
	--{Name = "Advanced", XP = 150, Color = Color3.fromRGB(255, 150, 0)},
	--{Name = "Pro", XP = 200, Color = Color3.fromRGB(0, 0, 255)},
	--{Name = "Veteran", XP = 300, Color = Color3.fromRGB(50, 50, 255)},
	--{Name = "Expert", XP = 500, Color = Color3.fromRGB(255, 0, 255)},
	--{Name = "Elite", XP = 800, Color = Color3.fromRGB(200, 0, 255)},
	--{Name = "Champion", XP = 1200, Color = Color3.fromRGB(150, 0, 255)},
	--{Name = "Master", XP = 1800, Color = Color3.fromRGB(100, 0, 255)},
	--{Name = "Grandmaster", XP = 2500, Color = Color3.fromRGB(0, 100, 255)},
	--{Name = "Legend", XP = 3500, Color = Color3.fromRGB(0, 200, 255)},
	--{Name = "Mythic", XP = 5000, Color = Color3.fromRGB(0, 255, 200)},
	--{Name = "Immortal", XP = 7500, Color = Color3.fromRGB(0, 255, 150)},
	--{Name = "God", XP = 10000, Color = Color3.fromRGB(219, 25, 236)},

	---- keep extending up to ~100 ranks
	--{Name = "Omega", XP = 50000, Color = Color3.fromRGB(255, 0, 0)},
	--{Name = "Cosmic", XP = 75000, Color = Color3.fromRGB(0, 255, 255)},
	--{Name = "Universal", XP = 100000, Color = Color3.fromRGB(255, 255, 0)},
	--{Name = "Eternal", XP = 150000, Color = Color3.fromRGB(255, 0, 150)},
	--{Name = "Transcendent", XP = 250000, Color = Color3.fromRGB(200, 0, 200)},
	--{Name = "Infinite", XP = 500000, Color = Color3.fromRGB(100, 0, 100)},
	--{Name = "Beyond", XP = 1000000, Color = Color3.fromRGB(0, 0, 0)},
}

-- validation
--local typeCheck = t.strictInterface({
--	Name = t.string,
--	XP = t.numberMin(0),
--	Color = t.Color3,
--})

--for i, tbl in ipairs(Ranks) do
--	local success, errorMessage = typeCheck(tbl)
--	if not success then
--		warn(i, errorMessage)
--	end
--end

type Ranks = typeof(Ranks)

export type Rank = {
	Name: string,
	XP: number,
	Color: Color3,
}

return Ranks :: Ranks & {
	[number]: Rank
}
