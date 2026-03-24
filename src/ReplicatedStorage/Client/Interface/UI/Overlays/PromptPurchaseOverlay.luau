local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mainGui = playerGui.Overlays.PromptPurchaseOverlay
local container = mainGui.Container
local loadingicon = container:WaitForChild("ImageLabel")

local tweenInfo = TweenInfo.new(
	0.35,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

local PromptPurchaseOverlay = {}

-- active tweens so we can cancel them
local activeContainerTween
local activeLoadingTween


local function cancelTweens()
	if activeContainerTween then
		activeContainerTween:Cancel()
	end
	if activeLoadingTween then
		activeLoadingTween:Cancel()
	end
end


function PromptPurchaseOverlay.show()
	mainGui.Enabled = true

	cancelTweens()

	activeContainerTween = TweenService:Create(container, tweenInfo, {
		Transparency = 0.5
	})

	activeLoadingTween = TweenService:Create(loadingicon, tweenInfo, {
		ImageTransparency = 0
	})

	activeContainerTween:Play()
	activeLoadingTween:Play()
end


function PromptPurchaseOverlay.hide()
	cancelTweens()

	activeContainerTween = TweenService:Create(container, tweenInfo, {
		Transparency = 1
	})

	activeLoadingTween = TweenService:Create(loadingicon, tweenInfo, {
		ImageTransparency = 1
	})

	activeContainerTween:Play()
	activeLoadingTween:Play()

	-- Disable after fade-out
	activeContainerTween.Completed:Once(function()
		mainGui.Enabled = false
	end)
end


PromptUtil.promptChanged:Connect(function(prompting, active)
	if prompting then
		if active then
			container.Active = true
		end
		PromptPurchaseOverlay.show()
	else
		container.Active = false
		PromptPurchaseOverlay.hide()
	end
end)

return PromptPurchaseOverlay
