local module = {}

-- Wrap text in a color
function module.ColorWrap(Text: string, color3: Color3): string
	if typeof(color3) ~= "Color3" then return Text end
	local R = math.floor(color3.R * 255)
	local G = math.floor(color3.G * 255)
	local B = math.floor(color3.B * 255)
	return string.format('<font color="rgb(%d,%d,%d)">%s</font>', R, G, B, Text)
end

-- Bold text
function module.Bold(Text: string): string
	return string.format('<b>%s</b>', Text)
end

-- Italic text
function module.Italic(Text: string): string
	return string.format('<i>%s</i>', Text)
end

-- Underline text
function module.Underline(Text: string): string
	return string.format('<u>%s</u>', Text)
end

-- Strikethrough text
function module.Strike(Text: string): string
	return string.format('<s>%s</s>', Text)
end

-- Outline / stroke
function module.Stroke(Text: string, thickness: number?, color3: Color3?): string
	local strokeColor = ""
	if color3 then
		local R = math.floor(color3.R * 255)
		local G = math.floor(color3.G * 255)
		local B = math.floor(color3.B * 255)
		strokeColor = string.format(' color="rgb(%d,%d,%d)"', R, G, B)
	end
	local strokeThickness = thickness or 1
	return string.format('<stroke thickness="%d"%s>%s</stroke>', strokeThickness, strokeColor, Text)
end

-- Change font size
function module.Size(Text: string, size: number): string
	return string.format('<font size="%d">%s</font>', size, Text)
end

-- Change font face (e.g., "GothamBold", "SourceSansPro", etc.)
function module.Font(Text: string, face: string): string
	return string.format('<font face="%s">%s</font>', face, Text)
end

return module