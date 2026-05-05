while true do
	local thing = script.Parent

	while task.wait() do
		local t = 5; 
		local hue = tick() % t / t
		local colorrr = Color3.fromHSV(hue, 1, 1)
		thing.Color = ColorSequence.new(colorrr)
	end
	task.wait()
end