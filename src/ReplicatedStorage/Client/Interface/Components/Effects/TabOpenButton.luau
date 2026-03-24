local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui


local TabOpenButton = {}

function TabOpenButton.tagAdded(button: GuiButton)
    local screenGui = playerGui.Tabs:FindFirstChild(button.Name) :: ScreenGui?
    if screenGui == nil then
        warn("[Buttons] No screen gui found for:", button.Name)
        return
    end
    button.Activated:Connect(function()
        InterfaceTabUtil.openTab(screenGui)
    end)
end

return TabOpenButton