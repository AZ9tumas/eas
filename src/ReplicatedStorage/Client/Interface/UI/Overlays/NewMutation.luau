local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MutationTextColors = require(ReplicatedStorage.Data.TextColors.Mutation)
local InterfaceHUDUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceHUDUtil)
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)
local Satchel = require(ReplicatedStorage.Satchel.SatchelLoader.Satchel)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)
local setTransparencyAndKeepOriginal = require(ReplicatedStorage.Shared.Utility.UI.setTransparencyAndKeepOriginal)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui


local mainGui = playerGui.Overlays.NewMutation
local continueLabel = mainGui.ContinueText
local container = mainGui.Container
local nameLabel = container.NameText
local newLabel = container.NewText
local mutationTierLabel = container.MutationTierLabel
local labubuIcon = container.Character
local glowLight = container.GlowLight


local function createMotionRecord(guiObject: GuiObject)
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = guiObject

    local motionRecord = {
        rotation = ripple.createMotion(0),
        size = ripple.createMotion(1),
        transparency = ripple.createMotion(0)
    }
    motionRecord.rotation:onStep(function(value)
        guiObject.Rotation = value
    end)
    motionRecord.size:onStep(function(value)
        uiScale.Scale = value
    end)
    motionRecord.transparency:onStep(function(value)
        setTransparencyAndKeepOriginal(guiObject, value)
    end)

    return motionRecord
end

type MotionRecord = typeof(createMotionRecord(...))
local motionRecords = {
    nameLabel = createMotionRecord(nameLabel),
    newLabel = createMotionRecord(newLabel),
    mutationTierLabel = createMotionRecord(mutationTierLabel),
    labubuIcon = createMotionRecord(labubuIcon),
    glowLight = createMotionRecord(glowLight),
}
local function doSomethingWithMotionRecords(callback: (MotionRecord) -> ())
    for _, motionRecord in pairs(motionRecords) do
        callback(motionRecord :: any)
    end
end


local revealQueue = {} :: {
	{ model: Model, mutationTier: number }
}

local isProcessingQueue = false


local trove = Trove.new()
local revealTrove = trove:Extend()


local NewMutation = {}

function NewMutation.init()
    
end

function NewMutation.queueMutation(model: Model, mutationTier: number)
	table.insert(revealQueue, {
		model = model, mutationTier = mutationTier,
	})

	if not isProcessingQueue then
		task.spawn(NewMutation.processQueue)
	end
end

function NewMutation.processQueue()
	if isProcessingQueue then 
		return 
	end
	isProcessingQueue = true

    doSomethingWithMotionRecords(function(motionRecord)  
        motionRecord.transparency:set(1)
        motionRecord.transparency:forceStep()
    end)
    container.Visible = false
	mainGui.Enabled = true
	InterfaceTabUtil.blurScreen()
	InterfaceHUDUtil.hideHUD()
	if Satchel:GetBackpackEnabled() then
		Satchel:SetBackpackEnabled(false)
	end

    local waveAngle = 0
    trove:Add(RunService.Heartbeat:Connect(function(deltaTime)  
		waveAngle += deltaTime*4
        waveAngle %= math.pi*2

		local sineValue = -math.cos(waveAngle)
		local amplitude = 2
        continueLabel.Rotation = sineValue * amplitude
	end))

    -- Wait for transition to end
    task.wait(0.1)

	while revealQueue[1] do
		local revealRecord = revealQueue[1]
		table.remove(revealQueue, 1)
		NewMutation.revealAsync(revealRecord.model, revealRecord.mutationTier)
	end

    revealTrove:Clean()

	mainGui.Enabled = false
    InterfaceTabUtil.unblurScreen()
	InterfaceHUDUtil.showHUD()
	if not Satchel:GetBackpackEnabled() then
		Satchel:SetBackpackEnabled(true)
	end

	task.wait(1)
	isProcessingQueue = false
    trove:Clean()
end

function NewMutation.revealAsync(model: Model, mutationTier: number)
    revealTrove:Clean()

    doSomethingWithMotionRecords(function(motionRecord)  
        motionRecord.rotation:stop()
        motionRecord.transparency:stop()
        motionRecord.size:stop()

        local transparencyConfig: ripple.SpringOptions = { frequency = 0.1, tension = 50, friction = 30, damping = 1 }
        local sizeConfig: ripple.SpringOptions = { frequency = 0.2, tension = 50, friction = 30, damping = 1 }
        motionRecord.transparency:spring(1, transparencyConfig)
        motionRecord.size:spring(0.5, sizeConfig)
    end)
    container.Visible = true

    task.wait(0.2)


    local currentDelay = 0
    local function createDelay(delayTime: number)
        currentDelay += delayTime
        return currentDelay
    end

    local transparencyConfig: ripple.SpringOptions = { frequency = 0.5, tension = 50, friction = 30, damping = 1 }
    local sizeConfig: ripple.SpringOptions = { frequency = 0.3, tension = 50, friction = 30, damping = 1 }
    local rotationConfig: ripple.SpringOptions = { frequency = 0.4, tension = 50, friction = 30, damping = 0.7 }
    revealTrove:Add(task.delay(createDelay(0), function()
        local motionRecord = motionRecords.glowLight
        motionRecord.transparency:spring(0, transparencyConfig)
    end))
    revealTrove:Add(task.delay(createDelay(0), function()
        local motionRecord = motionRecords.labubuIcon
        motionRecord.transparency:spring(0, transparencyConfig)
        motionRecord.size:set(0.9)
        motionRecord.size:spring(1, sizeConfig)
        motionRecord.rotation:set(-10)
        motionRecord.rotation:spring(0, rotationConfig)
    end))
    revealTrove:Add(task.delay(createDelay(0.1), function()
        local motionRecord = motionRecords.nameLabel
        motionRecord.transparency:spring(0, transparencyConfig)
        motionRecord.size:set(0.9)
        motionRecord.size:spring(1, sizeConfig)
    end))
    revealTrove:Add(task.delay(createDelay(0.05), function()
        local motionRecord = motionRecords.newLabel
        motionRecord.transparency:spring(0, transparencyConfig)
        motionRecord.size:set(0.9)
        motionRecord.size:spring(1, sizeConfig)
    end))
    revealTrove:Add(task.delay(createDelay(0.07), function()
        local motionRecord = motionRecords.mutationTierLabel
        motionRecord.transparency:spring(0, transparencyConfig)
        motionRecord.size:set(0.9)
        motionRecord.size:spring(1, sizeConfig)
    end))

    local name = model.Name
    nameLabel.Text = name

    local mutationName = PlotUtil.MutationTierToName(mutationTier)
    if mutationName then
        mutationTierLabel.Text = mutationName
        mutationTierLabel.TextColor3 = (MutationTextColors :: any)[mutationName]
    end

    local clickTrove = revealTrove:Extend()
    local function addClickListener(callback: () -> ())
        clickTrove:Add(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.ButtonA then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.KeyCode ~= Enum.KeyCode.ButtonA then
                return
            end
            callback()
        end))
    end

    local finished = false
    addClickListener(function()  
        finished = true
    end)

    while not finished do
		task.wait()
	end
end

-- testing
-- task.delay(1, function()
--     NewMutation.queueMutation(ReplicatedStorage.Assets.Hatchables["Artist Labubu"], 2)
--     NewMutation.queueMutation(ReplicatedStorage.Assets.Hatchables["Artist Labubu"], 3)
--     NewMutation.queueMutation(ReplicatedStorage.Assets.Hatchables["Artist Labubu"], 4)
-- end)

return NewMutation