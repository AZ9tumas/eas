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


local InterfaceMenuUtil = {}
InterfaceMenuUtil.menuOpen = false

InterfaceMenuUtil.OnMenuOpen = Signal.new()
InterfaceMenuUtil.OnMenuClose = Signal.new()

function InterfaceMenuUtil.isMenuOpen(name: string)
	local ScreenGui = typeof(name) == 'string' and playerGui.Menus:FindFirstChild(name) or name
	if not ScreenGui then
		return
	end
	return ScreenGui.Enabled
end

function InterfaceMenuUtil.openMenu(screenGui: ScreenGui | string, triggerSound: boolean?)
	if typeof(screenGui) == 'string' then
		screenGui = playerGui.Menus:FindFirstChild(screenGui)
	end
	
    local container = screenGui:FindFirstChild("Container") :: Frame?
    if container == nil then
        return
    end
    if screenGui.Parent ~= playerGui.Menus then
        return
	end
	
	if triggerSound then
		ClickSound:Play()
	end
	
    if screenGui.Enabled then
        InterfaceMenuUtil.closeAllMenus()
        return
    end
	InterfaceMenuUtil.closeAllMenus()
    
	trove:Clean()
	
	-- Fire the signal with the opened menu
	InterfaceMenuUtil.OnMenuOpen:Fire(screenGui.Name)

    screenGui.Enabled = true

    InterfaceMenuUtil.menuOpen = true
end

function InterfaceMenuUtil.closeAllMenus(triggerSound: boolean?)
	if triggerSound then
		ClickSound:Play()
	end
	
    trove:Clean()
	InterfaceMenuUtil.menuOpen = false

	local AnyMenuGotClosed: boolean = false

    for _, screenGui in pairs(playerGui.Menus:GetChildren()) do
        if not screenGui:IsA("ScreenGui") then
            continue
		end
		
		-- Fire the OnMenuClose signal only if the menu was enabled
		if screenGui.Enabled then
			AnyMenuGotClosed = true
			screenGui.Enabled = false
			
			InterfaceMenuUtil.OnMenuClose:Fire(screenGui.Name)
		end
	end
end

return InterfaceMenuUtil