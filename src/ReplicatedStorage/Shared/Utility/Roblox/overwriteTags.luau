local removeTags = require(script.Parent.removeTags)


return function(instance: Instance, tag: string)
    removeTags(instance)
    instance:AddTag(tag)
end