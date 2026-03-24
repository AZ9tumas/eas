local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local NewMutation = require(script.Parent.NewMutation)
local InterfaceHUDUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceHUDUtil)
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)
local WaveTransitionGui = require(script.Parent.WaveTransitionGui)
local Network = require(ReplicatedStorage.Network)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Satchel = require(ReplicatedStorage.Satchel.SatchelLoader.Satchel)
local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)
local emitConfetti = require(ReplicatedStorage.Shared.Utility.Effects.emitConfetti)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local currentCamera = workspace.CurrentCamera

local assets = ReplicatedStorage.Assets

-- Parented to ReplicatedStorage to ensure all parts are loaded, which avoids WaitForChild
ReplicatedStorage:WaitForChild("MutationReveal").Parent = workspace
local mutationRevealFolder = workspace.MutationReveal
local labubuOriginCFrame = mutationRevealFolder.Stand.PositionPart.CFrame
local revealCameraCFrame = mutationRevealFolder.CameraPart.CFrame
local blur = Lighting:WaitForChild("Blur")

local mainGui = playerGui.Overlays.MutationReveal
local container = mainGui.Container
local clickToOpenFrame = container.ClickToOpenFrame
local continueLabel = container.ContinueLabel
local successLabel = container.SuccessLabel
local failedLabel = container.FailedLabel
local mutationFailFrame = container.MutationFail
local keepButton = mutationFailFrame.Keep
local closeButton = mutationFailFrame.Lose


type Props = {
	failID: string?,
	mutationTier: number,
	isNewMutation: boolean?,
}
local revealQueue = {} :: {
	{ model: Model, props: Props }
}
local isProcessingQueue = false


local trove = Trove.new()
local revealTrove = trove:Extend()


local REQUIRED_PRESSES = 4
local FAIL_CAMERA_OFFSET = CFrame.new(3, 2, 0) * CFrame.Angles(math.rad(-10), math.rad(10), math.rad(-20))


local MutationReveal = {}

function MutationReveal.init()
	local isConsoleScreen = GuiService:IsTenFootInterface()
    local isXbox = UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA) == "ButtonA"
    clickToOpenFrame.XBOXKeybind.Visible = isConsoleScreen and isXbox
    clickToOpenFrame.PS5Keybind.Visible = isConsoleScreen and not isXbox

	mainGui.Enabled = false
end

function MutationReveal.queueReveal(model: Model, props: Props)
	table.insert(revealQueue, {
		model = model, props = props,
	})

	if not isProcessingQueue then
		task.spawn(MutationReveal.processQueue)
	end
end

function MutationReveal.queueRevealByName(modelName: string, props: Props)
	local model = assets.Hatchables:FindFirstChild(modelName)
	if model == nil or not model:IsA("Model") then
		warn("No model found for:", modelName)
		return
	end

	if props ~= nil then
		-- TODO: create mutated model
	end
	MutationReveal.queueReveal(model, props)
end

function MutationReveal.processQueue()
	if isProcessingQueue then 
		return 
	end
	isProcessingQueue = true

	mutationFailFrame.Visible = false

	WaveTransitionGui.doWaveTransitionAsync(0.7, 0.5, true)
	mainGui.Enabled = true
	InterfaceTabUtil.closeAllTabs(false)
	InterfaceHUDUtil.hideHUD()
	if Satchel:GetBackpackEnabled() then
		Satchel:SetBackpackEnabled(false)
	end

	local lastCameraCFrame = currentCamera.CFrame

	currentCamera.CameraType = Enum.CameraType.Scriptable
    currentCamera.CFrame = revealCameraCFrame

	local newMutations = {} :: { { model: Model, mutationTier: number } }
	while revealQueue[1] do
		local revealRecord = revealQueue[1]
		table.remove(revealQueue, 1)
		MutationReveal.revealAsync(revealRecord.model, revealRecord.props)

		local props = revealRecord.props
		if props.isNewMutation then
			table.insert(newMutations, { model = revealRecord.model, mutationTier = props.mutationTier, })
		end
	end

	WaveTransitionGui.doWaveTransitionAsync(0.7, 0.5, true)

	revealTrove:Clean()
	mainGui.Enabled = false

	currentCamera.CameraType = Enum.CameraType.Custom
	currentCamera.CFrame = lastCameraCFrame
	ContextActionService:UnbindAction("FreezeInputs")

	if newMutations[1] == nil then
		InterfaceHUDUtil.showHUD()
		if not Satchel:GetBackpackEnabled() then
			Satchel:SetBackpackEnabled(true)
		end
	else
		task.wait(0.5)
		for _, newMutationRecord in ipairs(newMutations) do
			NewMutation.queueMutation(newMutationRecord.model, newMutationRecord.mutationTier)
		end
	end

	task.wait(1)
	isProcessingQueue = false
end

function MutationReveal.revealAsync(modelTemplate: Model, props: Props)
	revealTrove:Clean()

    continueLabel.Visible = false
	failedLabel.Visible = false
	successLabel.Visible = false
	mutationFailFrame.Visible = false


	ReplicatedStorage.Assets.Sounds.Ground:Play()
    clickToOpenFrame.Visible = true
	currentCamera.CFrame = revealCameraCFrame


	ContextActionService:BindAction("FreezeInputs", function()
        return Enum.ContextActionResult.Sink 
    end, false, unpack(Enum.PlayerActions:GetEnumItems()))


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


	local originalScale = modelTemplate:GetScale()

	local model = modelTemplate:Clone()
	model:PivotTo(labubuOriginCFrame)
	model.Parent = mutationRevealFolder
	revealTrove:Add(model)

	local highlight = Instance.new("Highlight")
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(0, 0, 0)
    highlight.FillTransparency = 0
	highlight.Parent = model
    trove:Add(highlight)

	local effectTrove = revealTrove:Extend()
    local waveAngle = 0
    effectTrove:Add(RunService.Heartbeat:Connect(function(deltaTime)  
		waveAngle += deltaTime*2.5
        waveAngle %= math.pi*2

		local sineValue = -math.cos(waveAngle)
		local alpha = (sineValue + 1) * 0.5 -- from 0 to 1
        alpha = math.pow(alpha, 0.7)
        
		local adjustedValue = math.lerp(0, 0.3, alpha)
		highlight.FillColor = Color3.new(adjustedValue, adjustedValue, adjustedValue)
	end))


	local motion = ripple.createMotion(originalScale)
	motion:onStep(function(value)
		model:ScaleTo(value)
	end)
	revealTrove:Add(motion.stop)


	local finished = false
	local function reveal()
		clickToOpenFrame.Visible = false
		clickTrove:Clean()
		effectTrove:Clean()

		TweenService:Create(highlight, TweenInfo.new(0.5), {
			FillColor = Color3.new(1, 1, 1)
		}):Play()
		
		motion:spring(originalScale*1.5, { frequency = 0.3, tension = 50, friction = 30, damping = 2 })

		task.wait(1)

		TweenService:Create(highlight, TweenInfo.new(0.2), {
			FillTransparency = 1
		}):Play()

		motion:spring(originalScale*1, { frequency = 0.3, tension = 50, friction = 30, damping = 1 })

		-- task.wait(0.2)
		PlotUtil.addMutationEffect(model, props.mutationTier)

		local failID = props.failID
		if failID then
			mainGui.FailedSFX:Play()
			failedLabel.Visible = true


			revealTrove:Add(function()
				blur.Size = 3
			end)

			local cameraMotion = ripple.createMotion(0)
			cameraMotion:onStep(function(value)
				currentCamera.CFrame = revealCameraCFrame:lerp(revealCameraCFrame * FAIL_CAMERA_OFFSET, value)
			end)
			revealTrove:Add(cameraMotion.stop)
			cameraMotion:spring(1, { frequency = 0.4, tension = 50, friction = 30, damping = 0.6 })

			local blurMotion = ripple.createMotion(0)
			blurMotion:onStep(function(value)
				blur.Size = math.lerp(3, 20, value)
			end)
			revealTrove:Add(blurMotion.stop)
			blurMotion:spring(1, { frequency = 0.3, tension = 50, friction = 30, damping = 1 })

			mutationFailFrame.Visible = true

			revealTrove:Add(Network.Plots.KeepLostMutationSuccess.OnClientEvent:Connect(function(id)  
				if id ~= failID then
					return
				end
				finished = true
			end))
			revealTrove:Add(keepButton.Activated:Connect(function()
				Network.Plots.ClientMutateFail:FireServer(failID)
			end))
			
			revealTrove:Add(closeButton.Activated:Connect(function()
				finished = true
			end))
		else
			assets.Sounds.Reveal:Play()
			successLabel.Visible = true

			emitConfetti(50, { size = 0.3, speed = 0.5 })

			continueLabel.Visible = true
			addClickListener(function()  
				finished = true
			end)
		end
	end

	local scaleTrove = revealTrove:Extend()
	local clicks = 0
    addClickListener(function()
		scaleTrove:Clean()

		mainGui.ClickSFX:Play()

        clicks += 1
        if clicks == REQUIRED_PRESSES then
            reveal()
			return
        end

		motion:spring(originalScale*1.2, { frequency = 0.1, tension = 50, friction = 30, damping = 1 })
		scaleTrove:Add(task.delay(0.1, function()
			motion:spring(originalScale, { frequency = 0.3, tension = 50, friction = 30, damping = 0.7 })
		end))
    end)

	while not finished do
		task.wait()
	end
end

-- Queue test reveals
-- MutationReveal.queueReveal(ReplicatedStorage.Assets.Hatchables["Artist Labubu"], { mutationTier = 4, isNewMutation = true })
-- MutationReveal.queueReveal(ReplicatedStorage.Assets.Hatchables["JOB Labubu"], { mutationTier = 4, isNewMutation = true })

Network.Overlay.MutationReveal.OnClientEvent:Connect(function(hatchableName, mutationTier, isNewMutation)
	-- isNewMutation = true
	MutationReveal.queueRevealByName(hatchableName, { mutationTier = mutationTier, isNewMutation = isNewMutation })
end)

Network.Plots.MutateFail.OnClientEvent:Connect(function(hatchableName, failID, mutationTier)
	MutationReveal.queueRevealByName(hatchableName, { failID = failID, mutationTier = mutationTier })
end)

return MutationReveal