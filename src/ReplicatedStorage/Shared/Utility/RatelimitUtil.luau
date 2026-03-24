-- Ratelimit.lua
-- Simple, fast cooldown / ratelimit module

local Ratelimit = {}
Ratelimit.__index = Ratelimit

-- Create new cooldown
function Ratelimit.new(seconds)
	assert(typeof(seconds) == "number", "Cooldown must be a number")

	local self = setmetatable({}, Ratelimit)

	self.Cooldown = seconds
	self.LastUsed = 0

	return self
end

-- Check if cooldown finished
function Ratelimit:Check()
	return (os.clock() - self.LastUsed) >= self.Cooldown
end

-- Alias
function Ratelimit:IsReady()
	return self:Check()
end

-- Mark usage
function Ratelimit:Complete(newCooldown: number?)
	self.LastUsed = os.clock()
	
	if newCooldown then
		self.Cooldown = newCooldown
	end
end

-- Reset cooldown
function Ratelimit:Reset()
	self.LastUsed = 0
end

-- Time remaining
function Ratelimit:Remaining()
	local elapsed = os.clock() - self.LastUsed
	local remaining = self.Cooldown - elapsed
	return math.max(0, remaining)
end

-- One-call check + consume
function Ratelimit:Try(newCooldown: number?)
	if self:Check() then
		self:Complete(newCooldown)
		return true
	end
	return false
end

return Ratelimit