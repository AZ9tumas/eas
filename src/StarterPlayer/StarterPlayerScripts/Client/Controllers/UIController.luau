-- This has its own separate controller because interface needs to be moved before everything gets loaded

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterUI = game:GetService("StarterGui")
local isStudio = RunService:IsStudio()

local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)
local Loader = require(ReplicatedStorage.Packages.Loader)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local assets = ReplicatedStorage.Assets


local UIController = {}

function UIController.init()
    for _, folder in pairs(assets.Interface.PlayerGui:GetChildren()) do
        folder.Parent = playerGui
        for _, gui in pairs(folder:GetChildren()) do
            if not gui:IsA("ScreenGui") then
                continue
            end
            gui.ResetOnSpawn = false
        end
    end
    assets.Interface.PlayerGui:Destroy()
end

function UIController.onStart()
    -- Close tabs that shouldn't be open in the main game
    if not RunService:IsStudio() then
        InterfaceTabUtil.closeAllTabs()
    end

    local interfaceComponents = ReplicatedStorage.Client.Interface



    local function loadModules(loadBeforeUI: boolean?)
        for _, taggedComponentModule in ipairs(interfaceComponents.Components:GetDescendants()) do
            if not taggedComponentModule:IsA("ModuleScript") then
                continue
            end


            local tag = taggedComponentModule.Name

            local module = (require)(taggedComponentModule) :: {
                tagAdded: (Instance) -> (),
                tagRemoved: (Instance) -> ()?,
                loadBeforeUI: boolean?,
            }
            if module.loadBeforeUI ~= loadBeforeUI then
                continue
            end

			local function tagAdded(instance)
				if instance:IsDescendantOf(StarterUI) then return end
				
				module.tagAdded(instance)
			end
			
			local function tagRemoved(instance)
				if instance:IsDescendantOf(StarterUI) then return end

				module.tagRemoved(instance)
			end

            for _, instance in ipairs(CollectionService:GetTagged(tag)) do
                --module.tagAdded(instance)
				tagAdded(instance)
            end
            --CollectionService:GetInstanceAddedSignal(tag):Connect(module.tagAdded)
			CollectionService:GetInstanceAddedSignal(tag):Connect(tagAdded)

            if module.tagRemoved then
                CollectionService:GetInstanceRemovedSignal(tag):Connect(tagRemoved)
                --CollectionService:GetInstanceRemovedSignal(tag):Connect(module.tagRemoved)
            end
        end
    end

    -- Load all component modules that need to be loaded beforehand (ex. Padding depends on not having everything being removed beforehand)
    loadModules(true)


    -- Load all UI modules
    Loader.SpawnAll(Loader.LoadDescendants(interfaceComponents.UI, function(module: ModuleScript): boolean  
        if module.Parent == nil then
            return false
        end
        return module.Parent.Name ~= "Components"
    end), "init")


    -- Load all component modules that need to be loaded after UI loads (ex. ScaledStroke)
    loadModules()

    if isStudio then
        print("Finished Loading UI")
    end
end

return UIController