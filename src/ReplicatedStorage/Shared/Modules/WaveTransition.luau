--!strict

local WaveTransition = {}
WaveTransition.__index = WaveTransition

-- Options for creating a transition object
type WaveTransitionParams = {
	color: Color3?; -- color of squares (default white)
	width: number?; -- number of squares widthwise (default 10)
	waveDirection: Vector2?; -- direction vector of the wave (default (1,1))
	waveFunction: ((x: number, t: number) -> (number))? -- shape of the wave (default below)
}

-- this function: https://www.desmos.com/calculator/linp7zw3sa
local function DefaultWaveFunction(x: number, t: number): number
	local l = 0.5 -- length of wave
	local edge = t * (1 + l)
	if x < edge - l then
        return 1
	elseif x > edge then
        return 0
	else
        return 0.5 + 0.5 * math.cos(math.pi / l * (x - edge + l))
	end
end

-- Creates a new transition object with the given (optional) parameters
-- Container should probably be a ScreenGui with IgnoreGuiInsets turned on
function WaveTransition.new(container: GuiBase2d, params: WaveTransitionParams?)
	local width = params and params.width and params.width or 20
	
	-- compute number of rows needed to cover screen
	local size = container.AbsoluteSize.X / width
	local height = math.ceil(container.AbsoluteSize.Y / size)
	
	local self = {}
    self.squares = table.create(width*height) :: {GuiObject}
    self.percents = table.create(width*height) :: {number}
    self.color = params and params.color and params.color or Color3.new(0, 0, 0)
    self.width = width
    self.height = height
    self.size = size
    self.waveDirection = params and params.waveDirection and params.waveDirection or Vector2.new(1, 1)
    self.waveFunction = params and params.waveFunction and params.waveFunction or DefaultWaveFunction
    self.inverse = false
	

    local shortest = math.huge
    local longest = -math.huge
    
    for r = 1, self.height do
        for c = 1, self.width do
            local pos = Vector2.new((c-1) * self.size, (r-1) * self.size)
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            -- we add 1 so there's overlap between frames (borders wouldn't let us make a 0,0 size)
            f.Size = UDim2.fromOffset(0, 0)
            f.Position = UDim2.fromOffset(pos.X + self.size/2, pos.Y + self.size/2)
            f.BackgroundColor3 = self.color
            f.BorderSizePixel = 0
            f.Parent = container
            
            -- project 2d position along direction line
            local percent = self.waveDirection:Dot(pos)
            if percent < shortest then shortest = percent end
            if percent > longest then longest = percent end
            
            local idx = (r - 1) * self.width + c
            
            self.squares[idx] = f
            self.percents[idx] = percent
        end
    end
    
    -- remap projected positions on a scale from 0 to 1
    for i, s in ipairs(self.squares) do
        self.percents[i] = (self.percents[i] - shortest) / (longest - shortest)
    end


	setmetatable(self, WaveTransition)

	return self
end

export type WaveTransition = typeof(WaveTransition.new(...))

-- (private) updates a single square based on its position along the direction vector using the wave function
function WaveTransition._UpdateOne(self: WaveTransition, square: GuiObject, percent: number, alpha: number)
    if self.inverse then
        percent = 1 - percent
    end
	local t = self.waveFunction(percent, alpha)
	square.Size = UDim2.fromOffset(t * (self.size + 1), t * (self.size + 1))
end

-- Sets the wave's progress
function WaveTransition.Update(self: WaveTransition, alpha)
	for i, square in ipairs(self.squares) do
		self:_UpdateOne(square, self.percents[i], alpha)
	end
end

-- Destroys all GUI objects and frees their memory; the object is invalid and unusable after
function WaveTransition.Destroy(self: WaveTransition)
	for _, s in ipairs(self.squares) do
		s:Destroy()
	end
	self.squares = nil :: any
	self.percents = nil :: any
end

return WaveTransition