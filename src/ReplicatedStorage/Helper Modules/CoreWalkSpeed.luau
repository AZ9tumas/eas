local module = {}
local TweenService = game:GetService("TweenService")
local LocalPlayer = game.Players.LocalPlayer

local DefaultWalkSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed

module.DefaultWalkSpeed = DefaultWalkSpeed
module.LastWalkSpeed = DefaultWalkSpeed

-- Initialize the player's core WalkSpeed attribute
function module.Setup()
	LocalPlayer:SetAttribute("Core_WalkSpeed", DefaultWalkSpeed)
	
	module.LastWalkSpeed = DefaultWalkSpeed
end

-- Change the core WalkSpeed attribute value
function module.Change_WalkSpeed_CORE(newWalkSpeed)
	if LocalPlayer and newWalkSpeed then
		LocalPlayer:SetAttribute("Core_WalkSpeed", newWalkSpeed)
	end
end

-- Return the current core WalkSpeed attribute value
function module.Return_Core_WalkSpeed()
	return LocalPlayer:GetAttribute("Core_WalkSpeed")
end

-- Smoothly tween the camera's FieldOfView to a target value over duration seconds
function module.Change_WalkSpeed(targetWalkSpeed)
	if not targetWalkSpeed then return end
	
	if module.LastWalkSpeed == targetWalkSpeed then return end
	
	module.LastWalkSpeed = targetWalkSpeed
	local Character: Model? = LocalPlayer.Character
	if not Character then return end
	
	local Humanoid: Humanoid? = Character:FindFirstChild("Humanoid")
	if not Humanoid then return end
	
	Humanoid.WalkSpeed = targetWalkSpeed
end

return module
