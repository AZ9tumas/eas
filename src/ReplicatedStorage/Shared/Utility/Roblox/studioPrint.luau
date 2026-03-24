local isStudio = game:GetService("RunService"):IsStudio()

return function(...)
    if not isStudio then
        return
    end
    print(...)
end