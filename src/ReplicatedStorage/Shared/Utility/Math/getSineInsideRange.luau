return function(angle: number, min: number, max: number): number
    local alpha = (math.sin(angle) + 1) * 0.5 -- returns 0-1
    return math.lerp(min, max, alpha)
end