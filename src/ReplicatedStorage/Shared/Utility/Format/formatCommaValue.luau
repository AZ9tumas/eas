return function(amount: number)
    
    amount = math.round(amount)
    local formatted = tostring(amount)
    local k = nil
    repeat
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    until k == 0
    
    return formatted
end