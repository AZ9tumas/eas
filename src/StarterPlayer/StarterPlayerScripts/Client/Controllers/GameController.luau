local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local isStudio = RunService:IsStudio()

local LocalPlayer = Players.LocalPlayer

local GameController = {}
local CharacterComponents = {}

function GameController.onStart()
	require(ReplicatedStorage.Client.ClientData)

    for _, clientComponentModule in pairs(ReplicatedStorage.Client.Main:GetChildren()) do
        if not clientComponentModule:IsA("ModuleScript") then
            continue
        end
        local clientComponent = (require)(clientComponentModule) :: {init: () -> ()?}
        if clientComponent.init then
            if isStudio then
                print("Initializing Component: " ..  clientComponentModule.Name)
            end
            clientComponent.init()
        end
    end
    if isStudio then
        print("Finished Loading Main Components")
    end

    for _, componentModuleScript in ipairs(ReplicatedStorage.Client.Components:GetDescendants()) do
        if not componentModuleScript:IsA("ModuleScript") then
            continue
        end

        local tag = componentModuleScript.Name

        local module = (require)(componentModuleScript) :: {
            tagAdded: (Instance) -> ()?,
            tagRemoved: (Instance) -> ()?,
        }
		for _, instance in ipairs(CollectionService:GetTagged(tag)) do
			if module.tagAdded then
				module.tagAdded(instance)
			end
		end
		if module.tagAdded then
			CollectionService:GetInstanceAddedSignal(tag):Connect(module.tagAdded)
		end
		if module.tagRemoved then
			CollectionService:GetInstanceRemovedSignal(tag):Connect(module.tagRemoved)
		end
    end
    if isStudio then
        print("Finished Loading Components")
	end
	
	-- Misc Components
	for _, clientComponentModule in pairs(ReplicatedStorage.Client.Misc:GetChildren()) do
		if not clientComponentModule:IsA("ModuleScript") then
			continue
		end
		local clientComponent = (require)(clientComponentModule) :: {init: () -> ()?}
		if clientComponent.init then
			if isStudio then
				--print("Initializing Misc Component: " ..  clientComponentModule.Name)
			end
			clientComponent.init()
		end
	end
	if isStudio then
		print("Finished Loading Misc Components")
	end
	
	-- Character Components
	for _, clientComponentModule in pairs(ReplicatedStorage.Client.Character:GetChildren()) do
		if not clientComponentModule:IsA("ModuleScript") then
			continue
		end
		local clientComponent = (require)(clientComponentModule) :: {init: () -> ()?}
		if clientComponent.init then
			if isStudio then
				--print("Initializing Misc Component: " ..  clientComponentModule.Name)
			end
			clientComponent.init()
		end
		table.insert(CharacterComponents, clientComponent)
	end
	
	-- dispatcher
	local function onCharacterAdded(character)
		for _, component in ipairs(CharacterComponents) do
			if component.characterAdded then
				task.spawn(component.characterAdded, character)
			end
		end
	end

	local function onCharacterRemoving(character)
		for _, component in ipairs(CharacterComponents) do
			if component.characterRemoving then
				task.spawn(component.characterRemoving, character)
			end
		end
	end

	-- handle current character
	if LocalPlayer.Character then
		onCharacterAdded(LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving)
	
	if isStudio then
		print("Finished Loading Character Components")
	end
	
	task.spawn(function()
		task.wait(0.1)
		
		if not LocalPlayer:GetAttribute("ClientDataLoaded") then
			repeat task.wait(0.1) until LocalPlayer:GetAttribute("ClientDataLoaded")
		end
		
		local Network = require(ReplicatedStorage.Network)
		Network.ClientData.ClientSignaledLoaded:FireServer()
	end)
end

return GameController