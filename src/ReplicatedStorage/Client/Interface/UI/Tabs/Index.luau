local Index = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Types = require(ReplicatedStorage.Shared.Types)

export type IndexType = Types.IndexType

local CachedIndexData = {} :: IndexType

-- Example of IndexData:

--[[
	["Index"] =  ▼  {
		[1] =  ▼  { -- the [1] = MutationTier, 1 here means Mutation Tier: 1
			["Blue Diamond Labubu"] = true, -- this = Hatchable = Labubu Name
			["Normal Labubu"] = true,
			["Shark Labubu"] = true,
			["Time To Chill Labubu"] = true
		},
		[2] =  and so on... ▶ {...}
	},
--]]

local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)

local MutationTextColors = require(ReplicatedStorage.Data.TextColors.Mutation)
local RarityTextColors = require(ReplicatedStorage.Data.TextColors.Rarity)
local LabubuData = require(ReplicatedStorage.Data.Labubus)
local Rarity = require(ReplicatedStorage.Data.Rarity)

local gui = playerGui.Tabs.Index
local sidebar = gui.Container.FilterList
local gridContainer = gui.Container.PetGrid

local SELECTED_COLOR = Color3.fromRGB(0, 170, 240)
local DEFAULT_COLOR  = Color3.fromRGB(45, 50, 65)

local function clearGrid()
	for _, child in pairs(gridContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function createCard(name : string, unlocked: boolean, mutationName : string, rarity : string)
	local card = Instance.new("Frame")
	card.Parent = gridContainer
	card.BackgroundColor3 = DEFAULT_COLOR
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	--print(rarity)

	card.LayoutOrder = Rarity[rarity]

	local stroke = Instance.new("UIStroke")
	stroke.Parent = card
	stroke.Thickness = 2
	stroke.Color = RarityTextColors[rarity] or Color3.new(1,1,1)
	stroke.Transparency = 0.5

	local rTag = Instance.new("TextLabel")
	rTag.Parent = card
	rTag.Size = UDim2.new(1, 0, 0.15, 0)
	rTag.Position = UDim2.new(0, 0, 0.65, 0)
	rTag.BackgroundTransparency = 1
	rTag.Text = string.upper(rarity)
	rTag.TextColor3 = RarityTextColors[rarity] or Color3.new(1,1,1)
	rTag.Font = Enum.Font.FredokaOne
	rTag.TextSize = 12

	local n = Instance.new("TextLabel")
	n.Parent = card
	n.Size = UDim2.new(1, 0, 0.2, 0)
	n.Position = UDim2.new(0, 0, 0.8, 0)
	n.BackgroundTransparency = 1
	n.Text = name
	n.TextColor3 = Color3.new(1,1,1)
	n.Font = Enum.Font.FredokaOne
	n.TextSize = 14
	n.Visible = unlocked
	--n.TextScaled = true

	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Parent = card
	viewportFrame.Size = UDim2.new(0.8, 0, 0.55, 0)
	viewportFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
	viewportFrame.BackgroundTransparency = 1

	local model = ReplicatedStorage.Assets.Hatchables:FindFirstChild(name)
	if not model then return end

	local clone = model:Clone()
	clone.Parent = viewportFrame

	local camera = Instance.new("Camera", viewportFrame)
	viewportFrame.CurrentCamera = camera

	local cf, size = clone:GetBoundingBox()
	local center = cf.Position

	-- Find the distance needed to fit the model in view
	local maxSize = math.max(size.X, size.Y, size.Z)
	local fov = camera.FieldOfView
	-- Convert FieldOfView to radians
	local fovRad = math.rad(fov)
	local distance = (maxSize / 2) / math.tan(fovRad / 2)

	-- Set camera position (along Z axis pointing at model center)
	camera.CFrame = CFrame.new(center + Vector3.new(0, 0, distance), center)
	clone:PivotTo(clone:GetPivot() * CFrame.Angles(0, math.rad(90), 0) + Vector3.new(0.9, 0, 0))

	if not unlocked then
		for _, basepart in clone:GetDescendants() do
			if basepart:IsA("BasePart") then
				basepart.Color = Color3.new(0,0,0)
				basepart.Material = Enum.Material.SmoothPlastic
				basepart.Transparency = 0.5
			end
		end
	end
end

local function updateGrid(filter)
	clearGrid()

	local numUnlocked = 0

	for mutationTier = 1, 11 do
		local mutationName = PlotUtil.MutationTierToName(mutationTier)
		if filter == "ALL" or mutationName == filter then
			for _, hatchable in ReplicatedStorage.Assets.Hatchables:GetChildren()  do

				local unlocked = CachedIndexData[mutationTier] and 
					CachedIndexData[mutationTier][hatchable.Name]
				local rarity = LabubuData[hatchable.Name] and 
					LabubuData[hatchable.Name].Rarity or "Common" -- Common to Basic

				createCard(hatchable.Name, unlocked, mutationName, rarity)

				if unlocked then
					numUnlocked += 1
				end
			end
		end
	end

	local scale = numUnlocked / ( #ReplicatedStorage.Assets.Hatchables:GetChildren() * 11)
	game:GetService("TweenService"):Create(gui.Container.Header.Frame.Progress, TweenInfo.new(0.2), 
		{Size = UDim2.fromScale(scale,1)}):Play()
end

local currentBtn = nil

for _, btn in pairs(sidebar:GetChildren()) do
	if btn:IsA("TextButton") then

		if btn.Name == "Default" then
			currentBtn = btn
			btn.BackgroundColor3 = SELECTED_COLOR
			updateGrid("Default")
		end

		btn.MouseButton1Click:Connect(function()
			if currentBtn then
				game:GetService("TweenService"):Create(currentBtn, TweenInfo.new(0.2), 
					{BackgroundColor3 = DEFAULT_COLOR}):Play()
			end
			currentBtn = btn
			game:GetService("TweenService"):Create(currentBtn, TweenInfo.new(0.2), 
				{BackgroundColor3 = SELECTED_COLOR}):Play()

			updateGrid(btn.Name)
		end)
	end
end

-- This method will be called many times, and on it, there'll be the whole player Index table data
function Index.Update()
	CachedIndexData = ClientData.Index()
	if not CachedIndexData then return end
	
	updateGrid(currentBtn.Name)
end

function Index.init()
	Charm.subscribe(ClientData.Index, Index.Update)
	Index.Update()
end

return Index