local ProximityPromptService = game:GetService("ProximityPromptService")

type PromptModule = {
    promptShown: (ProximityPrompt) -> ()?,
    promptHidden: (ProximityPrompt) -> ()?,
    promptTriggered: (ProximityPrompt, Player) -> ()?,
}


local ProximityPrompts = {}

function ProximityPrompts.init()
    local function getPromptModule(prompt: ProximityPrompt): PromptModule?
        local promptModuleScript = script:FindFirstChild(prompt.Name)
        if promptModuleScript == nil or not promptModuleScript:IsA("ModuleScript") then
            return
        end

        local module = (require)(promptModuleScript) :: PromptModule
        return module
    end

    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        local module = getPromptModule(prompt)
        if module == nil or module.promptTriggered == nil then
            return
        end
        module.promptTriggered(prompt, player)
    end)
end

return ProximityPrompts