return function(instance: Instance, tag: string, condition: boolean)
    if condition then
        instance:AddTag(tag)
    else
        instance:RemoveTag(tag)
    end
end