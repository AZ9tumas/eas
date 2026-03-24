local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = require(ReplicatedStorage.Client.ClientSettings)
local Settings = require(ReplicatedStorage.Shared.Info.Settings)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
playerGui:WaitForChild("Templates")
local toggleOnTemplate = playerGui.Templates.ToggleOn
local toggleOffTemplate = playerGui.Templates.ToggleOff


local ToggleButton = {}

function ToggleButton.tagAdded(toggleButton: TextButton)
    local setting = toggleButton:GetAttribute("Setting")
    if setting == nil or type(setting) ~= "string" then
        warn("[ToggleButton] No setting attribute:", toggleButton)
        return
    end
    local settingInfo = Settings[setting]
    if settingInfo == nil then
        warn("[ToggleButton] No setting info for setting:", setting, toggleButton)
        return
    end
    if settingInfo.Data.Type ~= "Toggle" then
        warn("[ToggleButton] Invalid type for setting:", setting, toggleButton)
    end


    local function updateButtonDisplay()
        local value = ClientSettings[setting]
        if type(value) ~= "boolean" then
            return
        end

        for _, child in ipairs(toggleButton:GetChildren()) do
            if child:IsA("UIScale") then
                continue
            end
            child:Destroy()
        end
        local sampleButton = if value == true then toggleOnTemplate else toggleOffTemplate
        for _, child in ipairs(sampleButton:GetChildren()) do
            child:Clone().Parent = toggleButton
        end
    end
    updateButtonDisplay()
    ClientSettings.settingChanged(setting):Connect(updateButtonDisplay)

    toggleButton.Activated:Connect(function()
        ClientSettings[setting] = not ClientSettings[setting]
    end)
end

function ToggleButton.tagRemoved(toggleButton: TextButton)
    
end

return ToggleButton