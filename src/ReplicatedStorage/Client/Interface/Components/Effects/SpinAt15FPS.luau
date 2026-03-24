local SpinAt15FPS = {}
local spinningObjects = {}
local loopRunning = false

local FRAME_DELAY = 1/15
local DEFAULT_SPIN_SPEED = 30 -- degrees per second

local function runLoop()
	if loopRunning then return end
	loopRunning = true

	task.spawn(function()
		local dt = FRAME_DELAY
		
		while loopRunning do
			-- dt returned from task.wait

			for gui, data in pairs(spinningObjects) do
				if gui.Parent then
					local speed = gui:GetAttribute("SpinSpeed") or DEFAULT_SPIN_SPEED
					data.Rotation = data.Rotation + (speed * dt)
					gui.Rotation = data.Rotation % 360
				else
					-- Parent removed; clean it up
					spinningObjects[gui] = nil
				end
			end
			
			dt = task.wait(FRAME_DELAY)
		end
	end)
end

function SpinAt15FPS.tagAdded(GuiObject: GuiObject)
	if not GuiObject:IsA("GuiObject") then
		warn(GuiObject, "isn't a GuiObject!")
		return
	end

	spinningObjects[GuiObject] = {
		Rotation = GuiObject.Rotation
	}

	-- Start the loop if this is the first object
	if not loopRunning then
		runLoop()
	end
end

function SpinAt15FPS.tagRemoved(GuiObject: GuiObject)
	spinningObjects[GuiObject] = nil

	-- If empty, fully stop the loop
	if next(spinningObjects) == nil and loopRunning then
		loopRunning = false
	end
end

return SpinAt15FPS
