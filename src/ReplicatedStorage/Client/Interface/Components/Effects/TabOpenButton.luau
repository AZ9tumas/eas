local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui


local TabOpenButton = {}

function TabOpenButton.tagAdded(button: GuiButton)
    local tab = playerGui.Tabs:FindFirstChild(button.Name)
    if not tab then
        local newUI = playerGui:FindFirstChild("NewUI")
        if newUI then
            local frames = newUI:FindFirstChild("Frames")
            if frames then
                tab = frames:FindFirstChild(button.Name)
            end
        end
    end
    if tab == nil then
        warn("[Buttons] No screen gui found for:", button.Name)
        return
    end
    button.Activated:Connect(function()
        InterfaceTabUtil.openTab(tab)
    end)
end

return TabOpenButton