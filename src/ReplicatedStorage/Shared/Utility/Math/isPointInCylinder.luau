return function (point: Vector3, cylinderPos: Vector3, size: Vector3)
    local radius = size.Y * 0.5
    
    local radialDistanceSquared = (point.X - cylinderPos.X)^2 + (point.Z - cylinderPos.Z)^2
    local withinRadius = radialDistanceSquared <= radius^2
    
    local halfHeight = size.X * 0.5
    local withinHeight = point.Y >= cylinderPos.Y - halfHeight and point.Y <= cylinderPos.Y + halfHeight
    
    return withinRadius and withinHeight
end