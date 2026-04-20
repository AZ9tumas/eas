local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui


local hudList = {} :: { ScreenGui }
if playerGui.HUD:IsA("ScreenGui") then
    table.insert(hudList, playerGui.HUD)
end
for _, hudGui in ipairs(playerGui.HUD:GetChildren()) do
    if not hudGui:IsA("ScreenGui") then
        continue
    end
    table.insert(hudList, hudGui)
end

local newUI = playerGui:WaitForChild("NewUI")
local leftSideFrame = newUI:WaitForChild("LeftSide")

local hudSavedStates = {} :: { [ScreenGui]: boolean }
for _, hudGui in ipairs(hudList) do
    hudSavedStates[hudGui] = hudGui.Enabled
end
local isHidden = false


local InterfaceHUDUtil = {}

function InterfaceHUDUtil.setHUDEnabled(hudGui: ScreenGui, enabled: boolean)
    hudSavedStates[hudGui] = enabled
    if not isHidden then
        hudGui.Enabled = enabled
    end
end

function InterfaceHUDUtil.showHUD()
    isHidden = false
    for _, screenGui in ipairs(hudList) do
        screenGui.Enabled = hudSavedStates[screenGui]
    end
    leftSideFrame.Visible = true
end

function InterfaceHUDUtil.hideHUD()
    isHidden = true
    for _, screenGui in ipairs(hudList) do
        screenGui.Enabled = false
    end
    leftSideFrame.Visible = false
end

return InterfaceHUDUtil