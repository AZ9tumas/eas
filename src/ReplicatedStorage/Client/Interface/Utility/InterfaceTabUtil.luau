local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local UIBlur = Lighting:FindFirstChild("UIBlur")
if not UIBlur then
	UIBlur = Instance.new("BlurEffect")
	UIBlur.Name = "UIBlur"
	UIBlur.Size = 0
	UIBlur.Parent = Lighting
end

local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local BackpackUIToggle = require(ReplicatedStorage["Helper Modules"].BackpackUIToggle)

local ClickSound = ReplicatedStorage.Assets.Sounds.Interface.ButtonClick

local Signal = require(ReplicatedStorage.Packages.Signal)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local currentCamera = workspace.CurrentCamera


local fovConfig = { frequency = 0.3, tension = 1000, friction = 12, damping = 1 } :: ripple.SpringOptions

local fovMotion = ripple.createMotion(70)
fovMotion:onStep(function(value)
    currentCamera.FieldOfView = value
end)
fovMotion:start()

local blurMotion = ripple.createMotion(0)
blurMotion:onStep(function(value)
	UIBlur.Size = value
end)
blurMotion:start()

local trove = Trove.new()


local InterfaceTabUtil = {}
InterfaceTabUtil.tabOpen = false

InterfaceTabUtil.OnTabOpen = Signal.new()
InterfaceTabUtil.OnTabClose = Signal.new()

function InterfaceTabUtil.isTabOpen(name: string)
	local ScreenGui = typeof(name) == 'string' and playerGui.Tabs:FindFirstChild(name) or name
	if not ScreenGui then
		return
	end
	return ScreenGui.Enabled
end

function InterfaceTabUtil.openTab(screenGui: ScreenGui | string, triggerSound: boolean?)
	if typeof(screenGui) == 'string' then
		screenGui = playerGui.Tabs:FindFirstChild(screenGui)
	end
	
    local container = screenGui:FindFirstChild("Container") :: Frame?
    if container == nil then
        return
    end
    if screenGui.Parent ~= playerGui.Tabs then
        return
	end
	
	if triggerSound then
		ClickSound:Play()
	end
	
    if screenGui.Enabled then
        InterfaceTabUtil.closeAllTabs()
        return
    end
	InterfaceTabUtil.closeAllTabs()
    
	trove:Clean()
	
	-- Fire the signal with the opened tab
	InterfaceTabUtil.OnTabOpen:Fire(screenGui.Name)
	BackpackUIToggle.new()

    screenGui.Enabled = true
    playerGui.Overlays.TabDarken.Enabled = true
	InterfaceTabUtil.blurScreen()


    local originalPosition = container:GetAttribute("Position") :: UDim2?
    if originalPosition == nil then
        container:SetAttribute("Position", container.Position)
        originalPosition = container.Position
    end
    if originalPosition == nil then
        return
    end

    local motion = ripple.createMotion(originalPosition + UDim2.fromScale(0, 0.05))
    motion:onStep(function(value)
        container.Position = value
    end)
    trove:Add(motion.destroy)

    motion:spring(originalPosition, { frequency = 0.3, tension = 1000, friction = 12, damping = 0.6, restingVelocity = 0.0000001, restingPosition = 0.00000001 })
    motion:step(0)

    InterfaceTabUtil.tabOpen = true
end

function InterfaceTabUtil.closeAllTabs(triggerSound: boolean?)
	if triggerSound then
		ClickSound:Play()
	end
	
    trove:Clean()
	InterfaceTabUtil.tabOpen = false

    playerGui.Overlays.TabDarken.Enabled = false
	InterfaceTabUtil.unblurScreen()

	local AnyTabGotClosed: boolean = false

    for _, screenGui in pairs(playerGui.Tabs:GetChildren()) do
        if not screenGui:IsA("ScreenGui") then
            continue
		end
		
		-- Fire the OnTabClose signal only if the tab was enabled
		if screenGui.Enabled then
			AnyTabGotClosed = true
			screenGui.Enabled = false
			
			InterfaceTabUtil.OnTabClose:Fire(screenGui.Name)
		end
	end
	
	if AnyTabGotClosed then
		BackpackUIToggle.destroy()
	end
end

function InterfaceTabUtil.blurScreen()
	fovMotion:spring(77, fovConfig)
	blurMotion:spring(15, { frequency = 0.3, tension = 900, friction = 15, damping = 0.8 })
end

function InterfaceTabUtil.unblurScreen()
	fovMotion:spring(70, fovConfig)
	blurMotion:spring(0, { frequency = 0.3, tension = 900, friction = 15, damping = 0.8 })
end

-- Function to get GUI at a position
local function getGuiAtPosition(position)
	-- Get all GuiObjects under the position
	local guiObjects = playerGui:GetGuiObjectsAtPosition(position.X, position.Y)
	if #guiObjects > 0 then
		--return guiObjects[1] -- top-most GUI
		
		for _, gui in ipairs(guiObjects) do
			if gui.Name == "TouchControlFrame" then continue end
			
			if not gui:HasTag("IgnoreGui") then
				return gui -- first GUI that doesn't have the IgnoreGui tag
			end
		end
	end
end

-- Input handler
local function onInput(input, processed)
	if processed then return end -- ignore if UI already handled it
	if not InterfaceTabUtil.tabOpen then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch then
		local gui = getGuiAtPosition(input.Position)

		if gui then
			--print("Clicked GUI:", gui:GetFullName())
			
			if gui.Parent and gui.Parent.Name == "TabDarken" then
				InterfaceTabUtil.closeAllTabs()
			end
		end
	end
end

UserInputService.InputBegan:Connect(onInput)

return InterfaceTabUtil