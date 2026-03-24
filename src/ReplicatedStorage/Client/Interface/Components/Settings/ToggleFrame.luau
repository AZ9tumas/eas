local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = require(ReplicatedStorage.Client.ClientSettings)
local Settings = require(ReplicatedStorage.Shared.Info.Settings)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
playerGui:WaitForChild("Templates")

local ToggleFrame = {}

local LastTrigger = os.clock()

function ToggleFrame.tagAdded(toggleFrame: Frame)
	local setting = toggleFrame:GetAttribute("Setting")
    if setting == nil or type(setting) ~= "string" then
		warn("[ToggleFrame] No setting attribute:", toggleFrame)
        return
    end
    local settingInfo = Settings[setting]
    if settingInfo == nil then
		warn("[ToggleFrame] No setting info for setting:", setting, toggleFrame)
        return
    end
    if settingInfo.Data.Type ~= "Toggle" then
		warn("[ToggleFrame] Invalid type for setting:", setting, toggleFrame)
    end

	local toggleButton = toggleFrame:FindFirstChild("ToggleButton") :: TextButton
	if not toggleButton then
		warn("[ToggleFrame] No toggle button:", toggleFrame)
		return
	end
	
	local on = toggleFrame:FindFirstChild("on") :: UIGradient
	local off = toggleFrame:FindFirstChild("off") :: UIGradient

	if not on or not off then
		warn("[ToggleFrame] No on/off:", toggleFrame)
		return
	end
	
	local Title = (toggleButton:FindFirstChild("Title") or toggleButton:FindFirstChildOfClass("TextLabel")) :: TextLabel
	if not Title then
		warn("[ToggleFrame] No Title:", toggleFrame)
		return
	end

    local function updateButtonDisplay()
        local value = ClientSettings[setting]
        if type(value) ~= "boolean" then
            return
		end

		if value then
			on.Enabled = true
			off.Enabled = false
		else
			on.Enabled = false
			off.Enabled = true
		end
		
		Title.Text = value and "On" or "Off"
	end
	
    updateButtonDisplay()
    ClientSettings.settingChanged(setting):Connect(updateButtonDisplay)

	toggleButton.Activated:Connect(function()
		if os.clock() - LastTrigger < 0.1 then return end
		LastTrigger = os.clock()
		
        ClientSettings[setting] = not ClientSettings[setting]
    end)
end

function ToggleFrame.tagRemoved(toggleFrame: Frame)
    
end

return ToggleFrame