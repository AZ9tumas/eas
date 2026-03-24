local Settings = {
    -- General
    Music = {
        Name = "Music",
        Data = {Type = "Toggle"}
    },
    SFX = {
        Name = "Sound Effects",
        Data = {Type = "Toggle"}
    },
	GFX = {
		Name = "High Graphics Quality",
		Data = {Type = "Toggle"}
	},
	Trading = {
		Name = "Trading",
		Data = {Type = "Toggle"}
	},
	Vibration = {
		Name = "Vibration",
		Data = {Type = "Toggle"}
	},
} 

export type Settings = typeof(Settings)

type SettingData = { Type: string }
export type Toggle = SettingData & {}

return Settings :: Settings & {
    [string]: {
        Name: string,
        Description: string?,
        Data: SettingData | Toggle,
    }
}