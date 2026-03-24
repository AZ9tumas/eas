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

local modules = script.Parent.Services:GetChildren()
for _, module in ipairs(modules) do
    loadModule(module, "init")
end
for _, module in ipairs(modules) do
    loadModule(module, "onStart")
end