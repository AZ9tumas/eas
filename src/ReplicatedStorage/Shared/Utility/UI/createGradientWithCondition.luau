local createGradient = require(script.Parent.createGradient)
local removeGradient = require(script.Parent.removeGradient)

return function(name: string, parent: Instance, condition: boolean): UIGradient?
    if condition then
        return createGradient(name, parent)
    else
        return removeGradient(name, parent)
    end
end