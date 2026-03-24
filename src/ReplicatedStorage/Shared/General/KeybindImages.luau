type KeybindToString = {
    [Enum.KeyCode | Enum.UserInputType]: string,
}

local KeybindImages = {
    PC = {

    } :: KeybindToString,
    
    Touch = {

    } :: KeybindToString,

    Xbox = {
        [Enum.KeyCode.ButtonA] = "",
    } :: KeybindToString,

    PlayStation = {

    } :: KeybindToString,
}

return KeybindImages