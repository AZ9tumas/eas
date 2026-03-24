local function trimTrailingZeroes(str: string): string
    if str:find("%.") then
        str = str:gsub("0+$", "") -- remove trailing zeros
        str = str:gsub("%.$", "") -- remove trailing dot if left alone
    end
    return str
end

return function (num: number): string
    if num == 0 then 
        return "0" 
    end

    -- Find order of magnitude (how many digits before the decimal)
    local log10 = math.log10 or function(x)
        return math.log(x) / math.log(10)
    end

    local absNum = math.abs(num)
    local order = math.floor(log10(absNum))
    local decimalPlaces = 2 - order

    -- Clamp to avoid crazy rounding
    decimalPlaces = math.clamp(decimalPlaces, 0, 10)

    -- Round to 3 significant digits
    local rounded = tonumber(string.format("%." .. decimalPlaces .. "f", num))

    -- Clean trailing zeroes
    return trimTrailingZeroes(tostring(rounded))
end