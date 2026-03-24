local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)


local TabExitButton = {}

function TabExitButton.tagAdded(exitButton: GuiButton)
    if not exitButton:IsA("GuiButton") then
        warn(exitButton, "isn't a GuiButton!")
        return
    end

    exitButton.Activated:Connect(function()
        InterfaceTabUtil.closeAllTabs()
    end)
end

return TabExitButton