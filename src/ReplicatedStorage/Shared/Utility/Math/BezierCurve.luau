local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local lerpAny = require(script.Parent.lerpAny)


type BezierCurve<T> = {
    __index: BezierCurve<T>,

    p0: T,
    p1: T,
    p2: T,

    new: (T, T, T) -> (BezierCurve<T>),
    Get: (self: BezierCurve<T>, number) -> (T),
}


local BezierCurve = {}
BezierCurve.__index = BezierCurve

function BezierCurve.new<T>(p0: T, p1: T, p2: T): BezierCurve<T>
    local isValidType = t.union(t.number, t.Vector2, t.Vector3, t.UDim2)
    assert(isValidType(p0), "Invalid type!")
    assert(isValidType(p1), "Invalid type!")
    assert(isValidType(p2), "Invalid type!")

    local self = {}
    self.p0 = p0
    self.p1 = p1
    self.p2 = p2

    return setmetatable(self, BezierCurve) :: any
end

function BezierCurve.Get<T>(self: BezierCurve<T>, t: number): T
    local p0, p1, p2 = self.p0, self.p1, self.p2
    
    local lerp1 = lerpAny(p0, p1, t)
    local lerp2 = lerpAny(p1, p2, t)
    return lerpAny(lerp1, lerp2, t)
end

return BezierCurve