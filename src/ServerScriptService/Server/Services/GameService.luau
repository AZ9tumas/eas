local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local studioPrint = require(ReplicatedStorage.Shared.Utility.Roblox.studioPrint)


local GameController = {}

function GameController.init()
    
end

function GameController.onStart()
    local function recursiveModuleSearch(parent: Instance)
        for _, componentModuleScript in ipairs(parent:GetChildren()) do
            if not componentModuleScript:IsA("ModuleScript") then
                recursiveModuleSearch(componentModuleScript)
                continue
            end

			local tag = componentModuleScript.Name

            local module = (require)(componentModuleScript) :: {
                tagAdded: (Instance) -> (),
                tagRemoved: (Instance) -> (),
			}
			
            for _, instance in ipairs(CollectionService:GetTagged(tag)) do
                module.tagAdded(instance)
			end
			if module.tagAdded then
				CollectionService:GetInstanceAddedSignal(tag):Connect(module.tagAdded)
			else
				warn("Component Module", componentModuleScript.Name, "does not have a tagAdded function")
			end
			
			if module.tagRemoved then
				CollectionService:GetInstanceRemovedSignal(tag):Connect(module.tagRemoved)
			else
				warn("Component Module", componentModuleScript.Name, "does not have a tagRemoved function")
			end
        end
    end
    recursiveModuleSearch(ServerStorage.Components)
    studioPrint("Server Finished Loading Components")

    for _, serverComponentModule in pairs(ServerStorage.Main:GetChildren()) do
        if not serverComponentModule:IsA("ModuleScript") then
            continue
        end
        local serverComponent = (require)(serverComponentModule) :: {init: () -> ()?}
        if serverComponent.init then
            studioPrint("Server Loading Main Component", serverComponentModule.Name)
            serverComponent.init()
        end
    end
    studioPrint("Server Finished Loading Main Components")
end

return GameController