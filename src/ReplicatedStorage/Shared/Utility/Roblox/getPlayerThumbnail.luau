local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TypedPromise = require(ReplicatedStorage.Shared.Classes.TypedPromise)


return function(userId: number, thumbnailType: Enum.ThumbnailType, thumbnailSize: Enum.ThumbnailSize)
    if userId < 0 then
        userId = -userId
    end

    return TypedPromise.new(function(resolve: (string) -> (), reject, onCancel)

        local thread: thread?
        thread = task.spawn(function()
            local success, content
            repeat
                success, content = pcall(Players.GetUserThumbnailAsync, Players, userId, thumbnailType, thumbnailSize)
                if not success then
                    task.wait(1) 
                end
            until success
            
            thread = nil
            resolve(content)
        end)

        onCancel(function()
            if thread == nil then
                return
            end
            task.cancel(thread)
        end)

    end)
end