-- Improved MouseLeave by heartbeating gui objects on enter, seeing if it leaves or not
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local mouse = localPlayer:GetMouse()


return function(guiObject: GuiObject, mouseEnterFn: () -> (), mouseLeaveFn: () -> ()): Trove.Trove
    local trove = Trove.new()
    local mouseLeaveTrove = trove:Extend()
    trove:Connect(guiObject.MouseLeave, function()
        mouseLeaveTrove:Clean()
    end) 
    trove:Connect(guiObject.MouseEnter, function()
        if not guiObject.Interactable then
            return
        end
        
        mouseLeaveTrove:Add(function()
            if mouseLeaveFn then
                mouseLeaveFn()
            end
        end)
        mouseLeaveTrove:Connect(RunService.Heartbeat, function()
            local mouseOverrideExists = false
            local buttonIsStillHovered = false
            for _, otherObject: GuiObject in pairs(playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)) do
                if otherObject == guiObject then
                    buttonIsStillHovered = true
                -- elseif otherObject.Active and otherObject.Interactable then
                --     mouseOverrideExists = true
                --     break
                end
            end
            if mouseOverrideExists or not buttonIsStillHovered then
                mouseLeaveTrove:Clean()
            end
        end)

        if mouseEnterFn then
            mouseEnterFn()
        end
    end)

    return trove
end