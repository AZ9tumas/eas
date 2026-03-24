local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")
local Status = HUD:WaitForChild("Status")
local LoadingFrame = Status:WaitForChild("Loading")

LoadingFrame.Visible = true

function loadModule(module: Instance, method: string)
    if not module:IsA("ModuleScript") then
        return
    end
    local requiredModule = (require)(module) :: {init: () -> ()?}
    local methodFunc = requiredModule[method]
    if methodFunc then
        methodFunc()
    end
end

repeat task.wait(0.1) until LocalPlayer:GetAttribute("ProfileLoaded")

local modules = script.Parent.Controllers:GetChildren()
for _, module in ipairs(modules) do
    loadModule(module, "init")
end
for _, module in ipairs(modules) do
    loadModule(module, "onStart")
end

task.spawn(function()
	task.wait(0.1)
	
	if not LocalPlayer:GetAttribute("ClientDataLoaded") then
		repeat task.wait(0.1) until LocalPlayer:GetAttribute("ClientDataLoaded")
	end
	LoadingFrame.Visible = false
end)