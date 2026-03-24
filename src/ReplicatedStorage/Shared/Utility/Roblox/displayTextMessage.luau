local TextChatService = game:GetService("TextChatService")


return function (text: string)
    local textChannels = TextChatService:FindFirstChild("TextChannels") :: Folder?
    local rbxSystem = textChannels and textChannels:FindFirstChild("RBXSystem") :: TextChannel?
    if rbxSystem == nil then
        return
    end
    rbxSystem:DisplaySystemMessage(text)
end