type Code = {
    Expired: boolean?,
	--Cash: number,
	Message: string?
}
type Codes = { [string]: Code }

-- THE CODES GOTTA BE IN CAPS

local Codes: Codes = {
    ["RELEASE"] = {
		Cash = 10000,
		Message = "You got rewarded 10,000 Cash!"
    }
}

return Codes