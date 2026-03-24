
local rarityColorScheme = {
    Common    = { TextColor = Color3.fromRGB(255, 255, 255), BorderColor = Color3.fromRGB(142, 197, 255) },
    Uncommon  = { TextColor = Color3.fromRGB(100, 255, 100), BorderColor = Color3.fromRGB(100, 255, 100) },
    Rare      = { TextColor = Color3.fromRGB(255, 100, 100), BorderColor = Color3.fromRGB(255, 100, 100) },
    Epic      = { TextColor = Color3.fromRGB(200, 100, 255), BorderColor = Color3.fromRGB(200, 100, 255) },
    Legendary = { TextColor = "Rainbow", BorderColor = "Rainbow" },
    Secret    = { TextColor = Color3.fromRGB(200, 100, 200), BorderColor = "Rainbow" },
}

local Palette = {
    Rarity = rarityColorScheme :: typeof(rarityColorScheme) & {
        [string]: { TextColor: Color3 | string, BorderColor: Color3 | string }
    },

    Main = {
        InnerColor = Color3.fromRGB(74, 146, 255), 
        InnerColorSelected = Color3.fromRGB(152, 255, 152),
        BorderColorSelected = Color3.fromRGB(0, 255, 0),
        
        LightBlue = Color3.fromRGB(240, 240, 255),
    },
    Shiny = { 
        TextColor = "Shiny", 
        BorderColor = Color3.fromRGB(231, 127, 0), 
        InnerColor = Color3.fromRGB(255, 170, 0), 
        LightOrange = Color3.fromRGB(255, 248, 235),
    },
}

return Palette