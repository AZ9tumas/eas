--local ContextActionService = game:GetService("ContextActionService")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local UserInputService = game:GetService("UserInputService")

--local KeybindImages = require(ReplicatedStorage.Shared.General.KeybindImages)
--local Keybinds = require(ReplicatedStorage.Shared.Info.Keybinds)


--local InputUtil = {}

--function InputUtil.getPreferredInputWithConsole(): string
--    local preferredInput = UserInputService.PreferredInput
--    if preferredInput == Enum.PreferredInput.KeyboardAndMouse then
--        return "PC"
--    elseif preferredInput == Enum.PreferredInput.Touch then
--        return "Touch"
--    elseif preferredInput == Enum.PreferredInput.Gamepad then
--        local isXboxController = UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA) == "ButtonA"
--        if isXboxController then
--            return "Xbox"
--        else
--            return "PlayStation"
--        end
--    end
--    return ""
--end

--function InputUtil.getImageFromUserInput(keyCodeOrType: Enum.KeyCode | Enum.UserInputType, platform: string?): string
--    local image: string?

--    local preferredInput = UserInputService.PreferredInput
--    if preferredInput == Enum.PreferredInput.KeyboardAndMouse then
--        image = KeybindImages.PC[keyCodeOrType]
--    elseif preferredInput == Enum.PreferredInput.Touch then
--        image = KeybindImages.Touch[keyCodeOrType]
--    elseif preferredInput == Enum.PreferredInput.Gamepad then
--        local isXboxController = if platform then platform == "Xbox" else UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA) == "ButtonA"
--        if isXboxController then
--            image = KeybindImages.Xbox[keyCodeOrType]
--        else
--            image = KeybindImages.PlayStation[keyCodeOrType]
--        end
--    end

--    if image == nil then
--        warn("[InputUtil] Couldn't find image from key code:", keyCodeOrType)
--    end

--    return image or ""
--end

--function InputUtil.bindAction(actionName: string, keybinds: Keybinds.KeybindInfo, callback: () -> ())
--    local realKeybinds = {}
--    for _, keybind in pairs(keybinds) do
--        table.insert(realKeybinds, keybind)
--    end
--    ContextActionService:BindActionAtPriority(actionName, function(_, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
--        if inputState ~= Enum.UserInputState.End then
--            return
--        end

--        callback()

--        return Enum.ContextActionResult.Sink
--    end, false, 100, table.unpack(realKeybinds))
--end

--function InputUtil.unbindAction(actionName: string)
--    ContextActionService:UnbindAction(actionName)
--end

--InputUtil.isTouchingScreen = false
--UserInputService.TouchStarted:Connect(function()
--    InputUtil.isTouchingScreen = true
--end)
--UserInputService.TouchEnded:Connect(function()
--    InputUtil.isTouchingScreen = false
--end)

--return InputUtil

return {}