local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui
local camera = workspace.CurrentCamera

local BASE_SIZE = 1920

-- Table to track UI elements that need scaling
local ScaledElements = {}

-- Function to register elements
local function registerUI(element)
	-- Only UIStroke elements
	if not element:IsA("UIStroke") then return end
	if ScaledElements[element] then return end

	if element:GetAttribute("NoAutoScaleStroke") then return end

	-- Store original thickness and optional min/max
	local original = element.Thickness
	if not element:GetAttribute("OriginalThickness") then
		element:SetAttribute("OriginalThickness", original)
	end

	if ScaledElements[element] then return end

	ScaledElements[element] = {
		element = element,
		original = original,
		min = element:GetAttribute("MinimumThickness"),
		max = element:GetAttribute("MaximumThickness")
	}

	-- Initial update
	local data = ScaledElements[element]
	local scaled = data.original * camera.ViewportSize.X / BASE_SIZE
	if data.min then scaled = math.max(scaled, data.min) end
	if data.max then scaled = math.min(scaled, data.max) end
	element.Thickness = scaled
end

local TASK = nil
local DEBOUNCE_TIME = 0.15 -- seconds to wait after last viewport change
local HasStarted: boolean = false

local lastChangeTime = 0

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	lastChangeTime = os.clock() -- record the latest change

	if TASK then
		if not HasStarted then
			return -- existing task will handle it
		else
			task.cancel(TASK)
		end
	end

	TASK = task.spawn(function()
		while true do
			local elapsed = os.clock() - lastChangeTime
			if elapsed >= DEBOUNCE_TIME then
				HasStarted = true

				-- run the update
				local c = 0
				for element, data in pairs(ScaledElements) do
					if element.Parent then
						local scaled = data.original * camera.ViewportSize.X / BASE_SIZE
						if data.min then scaled = math.max(scaled, data.min) end
						if data.max then scaled = math.min(scaled, data.max) end
						element.Thickness = scaled
					end

					c += 1
					if c % 50 == 0 then
						task.wait()
					end
				end
				break -- exit loop after running
			else
				task.wait(0.05) -- small delay before checking again
			end
		end

		HasStarted = false
		TASK = nil
	end)
end)

task.wait(1)

-- Catch newly added UI elements
PlayerGui.DescendantAdded:Connect(registerUI)

-- Initial scan
for _, descendant in ipairs(PlayerGui:GetDescendants()) do
	registerUI(descendant)
end

while true do
	task.wait(3)
	for element in pairs(ScaledElements) do
		if not element.Parent then
			ScaledElements[element] = nil
		end
		task.wait(0.05) -- small delay to avoid lag
	end
end