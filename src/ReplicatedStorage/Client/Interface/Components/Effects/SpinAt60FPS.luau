local RunService = game:GetService("RunService")

local SpinAt60FPS = {}
local spinningObjects = {}
local heartbeatConnection = nil

local DEFAULT_SPIN_SPEED = 30 -- degrees per second

local function startHeartbeat()
	if heartbeatConnection then return end

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		for gui, data in pairs(spinningObjects) do
			if gui.Parent then

				-- Read SpinSpeed attribute (or fallback)
				local speed = gui:GetAttribute("SpinSpeed") or DEFAULT_SPIN_SPEED

				-- Apply rotation
				data.Rotation = data.Rotation + (speed * dt)
				gui.Rotation = data.Rotation % 360

			else
				-- Parent removed, stop tracking
				spinningObjects[gui] = nil
			end
		end
	end)
end

function SpinAt60FPS.tagAdded(GuiObject: GuiObject)
	if not GuiObject:IsA("GuiObject") then
		warn(GuiObject, "isn't a GuiObject!")
		return
	end

	-- Start from its current rotation
	spinningObjects[GuiObject] = {
		Rotation = GuiObject.Rotation
	}

	-- Start Heartbeat if this is the first object
	if not heartbeatConnection then
		startHeartbeat()
	end
end

function SpinAt60FPS.tagRemoved(GuiObject: GuiObject)
	spinningObjects[GuiObject] = nil

	-- If no objects left, disconnect heartbeat
	if next(spinningObjects) == nil and heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

return SpinAt60FPS
