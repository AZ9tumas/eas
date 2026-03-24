local module = {}

local TopBarPlus = require(game:GetService("ReplicatedStorage"):WaitForChild("TopbarPlus"):WaitForChild("Icon"))
local interfaceUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("Client")
	:WaitForChild("Interface"):WaitForChild("Utility"):WaitForChild("InterfaceTabUtil"))

local SettingsButton = TopBarPlus.new()

SettingsButton:setImage(script.Icon.Image)
SettingsButton:setCaption("Settings")
SettingsButton:autoDeselect(true)

-- Mute
SettingsButton.selected:Connect(function()
	interfaceUtil.openTab("Settings", true)
end)

-- Unmute
SettingsButton.deselected:Connect(function()
	if interfaceUtil.isTabOpen("Settings") then
		interfaceUtil.closeAllTabs(true)
	end
end)

interfaceUtil.OnTabClose:Connect(function(tabName: string)
	if tabName == "Settings" then
		SettingsButton:deselect()
	end
end)

return module