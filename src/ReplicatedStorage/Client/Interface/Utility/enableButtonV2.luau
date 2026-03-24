local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(textButton: TextButton, enabled: boolean?)
    textButton.Interactable = if enabled == false then false else true
    local Glow: ImageLabel? = textButton:FindFirstChild("Glow")
	if Glow then
		Glow.ImageTransparency = enabled and 0.85 or 0.95
	end
	textButton.ImageTransparency = enabled and 0 or 0.5
end