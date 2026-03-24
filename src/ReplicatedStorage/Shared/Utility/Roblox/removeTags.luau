return function(instance: Instance)
    for _, tag in ipairs(instance:GetTags()) do
        instance:RemoveTag(tag)
    end
end