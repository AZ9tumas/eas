local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Charm = require(ReplicatedStorage.Packages.Charm)
local formatLargeNumber = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumber)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mainGui = playerGui:WaitForChild("NewUI").CashDisplay
local amountLabel = mainGui.Main

local Currency = {}

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function FormatWithCommas(number: number): string
	local formatted = tostring(math.floor(math.abs(number)))
	while true do
		local result, k = string.gsub(formatted, "^(%d+)(%d%d%d)", "%1,%2")
		formatted = result
		if k == 0 then break end
	end
	return formatted
end

local function tween(instance, tweenInfo, properties)
	local anim = TweenService:Create(instance, tweenInfo, properties)
	anim:Play()
	return anim
end

-- ─────────────────────────────────────────────
-- Cash change pop animation (from mpp CashStatus)
-- ─────────────────────────────────────────────

local HOLD_TIME   = 0.9
local FADE_TIME   = 0.45
local RISE_AMOUNT = 38

local activeCount = 0

local function animateCashChange(amount: number, isGain: boolean)
	activeCount += 1
	local index = activeCount

	local label = amountLabel:Clone()
	label.Text = string.format("%s$%s", isGain and "+" or "-", FormatWithCommas(amount))
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.TextTransparency = 1
	label.Rotation = 0
	label.TextColor3 = isGain and Color3.fromRGB(85, 255, 127) or Color3.fromRGB(240, 30, 30)

	-- Slight vertical stagger so rapid pops don't perfectly overlap
	local staggerY = ((index % 4) - 1.5) * 14
	local base = amountLabel.Position
	local popPosition = base + UDim2.fromOffset(0, staggerY)
	local exitPosition = popPosition - UDim2.fromOffset(0, RISE_AMOUNT)

	-- UIScale for the pop punch
	local uiScale = label:FindFirstChildWhichIsA("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = label
	end
	uiScale.Scale = 0.7

	local uiStroke = label:FindFirstChildWhichIsA("UIStroke")
	if uiStroke then uiStroke.Transparency = 1 end

	label.Position = popPosition
	label.Parent = mainGui

	-- 1. Pop in
	tween(label, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextTransparency = 0, Position = popPosition })
	tween(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1.0 })
	if uiStroke then
		tween(uiStroke, TweenInfo.new(0.14, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{ Transparency = 0 })
	end

	-- 2. Hold, then float up and fade out
	task.delay(HOLD_TIME, function()
		if not label.Parent then return end

		tween(label, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1, Position = exitPosition })
		tween(uiScale, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 0.85 })
		if uiStroke then
			tween(uiStroke, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Transparency = 1 })
		end
	end)

	Debris:AddItem(label, HOLD_TIME + FADE_TIME + 0.1)
end

-- ─────────────────────────────────────────────
-- Main update
-- ─────────────────────────────────────────────

function Currency.init()
	local oldCash = nil

	local function UpdateCash(animate: boolean?)
		local Cash = ClientData.Cash()
		if not Cash then return end

		local CachedOldCash = oldCash
		oldCash = Cash

		amountLabel.Text = "$" .. formatLargeNumber(Cash)

		if animate ~= false and CachedOldCash ~= nil then
			local change = Cash - CachedOldCash
			if change > 0 then
				animateCashChange(change, true)
			elseif change < 0 then
				animateCashChange(math.abs(change), false)
			end
		end
	end

	Charm.subscribe(ClientData.Cash, function() UpdateCash() end)

	UpdateCash(false)
end

return Currency