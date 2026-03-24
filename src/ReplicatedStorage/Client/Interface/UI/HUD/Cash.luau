local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)

local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local formatLargeNumber = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumber)
local formatLargeNumberThousands = require(ReplicatedStorage.Shared.Utility.Format.formatLargeNumberThousands)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local mainGui = playerGui.HUD.Buttons.BottomLeft.Cash
local amountLabel = mainGui.AmountLabel
local AddedCashFrame = mainGui.AddedCash
local AmountLabelTemplate = AddedCashFrame.AmountLabel

local Currency = {}

local originalColor = amountLabel.TextColor3
local redColor = Color3.fromRGB(240, 30, 30)

local tweenInfo = TweenInfo.new(
	1, -- time (seconds)
	Enum.EasingStyle.Quad, -- easing style
	Enum.EasingDirection.Out
)

local transparenttweenInfo = TweenInfo.new(
	7, -- time (seconds)
	Enum.EasingStyle.Quad, -- easing style
	Enum.EasingDirection.Out
)

local transparentStroketweenInfo = TweenInfo.new(
	6, -- time (seconds)
	Enum.EasingStyle.Quad, -- easing style
	Enum.EasingDirection.Out
)

function Currency.init()
	local oldCash = nil
	
	local function UpdateCash(animate: boolean?)
		local Cash = ClientData.Cash()
		if not Cash then return end
		
		local CachedOldCash = oldCash
		oldCash = Cash
		
		amountLabel.Text = "$" .. formatLargeNumber(Cash)
		
		if animate ~= false then
			if CachedOldCash == nil then return end
			
			local AmountLabelTemplate = AmountLabelTemplate:Clone()
			
			if Cash < CachedOldCash then
				AmountLabelTemplate.TextColor3 = redColor
				AmountLabelTemplate.Text =  "-$" .. formatLargeNumber(CachedOldCash - Cash)
				
				--if toOriginal.PlaybackState == Enum.PlaybackState.Playing then
				--	toOriginal:Stop()
				--end

				amountLabel.TextColor3 = redColor

				local toOriginal: Tween = TweenService:Create(amountLabel, tweenInfo, {TextColor3 = originalColor})
				toOriginal:Play()
			else
				AmountLabelTemplate.Text =  "+$" .. formatLargeNumber(Cash - CachedOldCash)
			end
			
			AmountLabelTemplate.Visible = true
			AmountLabelTemplate.Parent = AddedCashFrame
			
			local toTransparentText: Tween = TweenService:Create(
				AmountLabelTemplate, transparenttweenInfo, {TextTransparency = 1}
			)
			toTransparentText:Play()

			local toTransparentUIStroke: Tween = TweenService:Create(
				AmountLabelTemplate.UIStroke, transparentStroketweenInfo, {Transparency = 1}
			)
			toTransparentUIStroke:Play()
			--local toTransparentUIStroke: Tween = TweenService:Create(
			--	AmountLabelTemplate, transparentStroketweenInfo, {TextStrokeTransparency = 1}
			--)
			--toTransparentUIStroke:Play()
			
			toTransparentText.Completed:Once(function()
				AmountLabelTemplate:Destroy()
			end)
		end
	end
	
	Charm.subscribe(ClientData.Cash, function() UpdateCash() end)
	
	UpdateCash(false)
end

return Currency