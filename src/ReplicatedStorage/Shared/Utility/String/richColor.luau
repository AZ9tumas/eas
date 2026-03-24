local function convertToRGB(value: number)
    return math.floor(value * 255)
end

return function(color: Color3, string: string)
    local r, g, b = convertToRGB(color.R), convertToRGB(color.G), convertToRGB(color.B)
    return `<font color="rgb({r},{g},{b})">{string}</font>`
end