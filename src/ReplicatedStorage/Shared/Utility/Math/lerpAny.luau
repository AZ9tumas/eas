type ValidTypes = number | Vector2 | Vector3

return function<T>(a: T, b: T, t: number): T
    if type(a) == "number" then
        return math.lerp(a, b, t) :: any
    elseif typeof(a) == "Vector2" then
        return a:Lerp(b, t)
    elseif typeof(a) == "Vector3" then
        return a:Lerp(b, t)
    elseif typeof(a) == "UDim2" then
        return a:Lerp(b, t)
    end
    return a
end