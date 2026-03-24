local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Network = require(ReplicatedStorage.Network)

local Types = require(ReplicatedStorage.Shared.Types)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local mainGui = playerGui.Overlays
local TransitionFrame = mainGui.Transition.Frame

local TransitionEvent = Network.Overlay.Transition

local Transition = {}

function Transition.Transition(Timer: number?)
	local duration = Timer or 3

	TweenService:Create(TransitionFrame, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, true, 0), {BackgroundTransparency = 0}):Play()
end

TransitionEvent.OnClientEvent:Connect(Transition.Transition)
return Transition
