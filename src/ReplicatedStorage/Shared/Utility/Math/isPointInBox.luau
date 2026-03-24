return function(point: Vector3, boxPosition: Vector3, boxSize: Vector3)
    local halfSize = boxSize / 2
    
    local boxMin = boxPosition - halfSize
    local boxMax = boxPosition + halfSize
    
    local withinX = point.X >= boxMin.X and point.X <= boxMax.X
    local withinY = point.Y >= boxMin.Y and point.Y <= boxMax.Y
    local withinZ = point.Z >= boxMin.Z and point.Z <= boxMax.Z
    
    return withinX and withinY and withinZ
end