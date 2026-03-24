local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceMenuUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceMenuUtil)

local MenuExitButton = {}

function MenuExitButton.tagAdded(exitButton: GuiButton)
    if not exitButton:IsA("GuiButton") then
        warn(exitButton, "isn't a GuiButton!")
        return
    end

    exitButton.Activated:Connect(function()
		InterfaceMenuUtil.closeAllMenus()
    end)
end

return MenuExitButton