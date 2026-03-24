local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local WaveTransition = require(ReplicatedStorage.Shared.Modules.WaveTransition)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local currentCamera = workspace.CurrentCamera


local mainGui = playerGui.Overlays.WaveTransitionGui
local container = mainGui.Container


local trove = Trove.new()
local teleporting = false


local WaveTransitionGui = {}

function WaveTransitionGui.init()

end

-- Events
function WaveTransitionGui.doWaveTransition(duration: number, lingerTime: number, noSFX: boolean?)
    trove:Clean()

    local waveTransitionModule = WaveTransition.new(container)
    trove:Add(function()
        waveTransitionModule:Destroy()
    end)

    local timeElapsed = 0
    local playedSFX1 = false
    local playedSFX2 = false
    trove:Add(RunService.Heartbeat:Connect(function(deltaTime)
        if duration == 0 then
            return
        end

        timeElapsed += deltaTime
        if timeElapsed < duration then
            local alpha = math.min(1, timeElapsed / duration)
            waveTransitionModule:Update(alpha)

            if not playedSFX1 then
                playedSFX1 = true
                -- mainGui.UI_Open:Play()
            end
            return
        end

        if teleporting then
            timeElapsed = duration
        end

        local adjustedTimeElapsed = timeElapsed - lingerTime
        local alpha = 1 - math.min(1, adjustedTimeElapsed / duration - 1)
        waveTransitionModule.inverse = true
        waveTransitionModule:Update(alpha)
        if alpha < 1 and not playedSFX2 then
            playedSFX2 = true
        end

        if alpha == 0 then
            trove:Clean()
        end
    end))
end

function WaveTransitionGui.doWaveTransitionAsync(duration: number, lingerTime: number, noSFX: boolean?)
    WaveTransitionGui.doWaveTransition(duration, lingerTime, noSFX)
    task.wait(duration)
end

function WaveTransitionGui.updateCameraCFrame(cameraCFrame: CFrame)
    local _, yRot, _ = cameraCFrame:ToEulerAnglesYXZ()
    local x, _, z = currentCamera.CFrame:ToEulerAnglesYXZ()
    currentCamera.CFrame = CFrame.new(currentCamera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(x, yRot, z) 

    localPlayer:SetAttribute("DisableFollowCamera", true)
    task.delay(0.5, function()
        localPlayer:SetAttribute("DisableFollowCamera", nil)
    end)
end

return WaveTransitionGui