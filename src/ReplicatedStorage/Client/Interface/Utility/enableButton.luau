local ReplicatedStorage = game:GetService("ReplicatedStorage")

local setTransparencyIncludingDescendants = require(ReplicatedStorage.Shared.Utility.UI.setTransparencyIncludingDescendants)


return function(textButton: TextButton, enabled: boolean?)
    textButton.Interactable = if enabled == false then false else true
    setTransparencyIncludingDescendants(textButton, if enabled == false then 0.5 else 0)
end