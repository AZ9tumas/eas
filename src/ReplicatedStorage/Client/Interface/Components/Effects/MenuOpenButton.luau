local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceMenuUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceMenuUtil)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui


local MenuOpenButton = {}

function MenuOpenButton.tagAdded(button: GuiButton)
    local screenGui = playerGui.Menus:FindFirstChild(button.Name) :: ScreenGui?
    if screenGui == nil then
        warn("[Buttons] No screen gui found for:", button.Name)
        return
    end
    button.Activated:Connect(function()
		InterfaceMenuUtil.openMenu(screenGui)
    end)
end

return MenuOpenButton