return function(str: string): string
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end