local thing = script.Parent

while true do
	local t = 5
	local hue = tick() % t / t
	local colorrr = Color3.fromHSV(hue, 1, 1)
	thing.Color = colorrr
	task.wait()
end