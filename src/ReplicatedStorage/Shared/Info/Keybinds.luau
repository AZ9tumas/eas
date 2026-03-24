export type KeybindInfo = { PC: Enum.KeyCode | Enum.UserInputType, Touch: Enum.UserInputType, Gamepad: Enum.KeyCode }

local Keybinds = {
    --HatchEgg = { PC = Enum.KeyCode.E, Gamepad = Enum.KeyCode.ButtonA, } :: KeybindInfo,
}

type Keybinds = typeof(Keybinds)

return Keybinds :: Keybinds & {
    [string]: KeybindInfo
}