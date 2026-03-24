return function(str: string): string
    return str:gsub("(%l)(%u)", "%1 %2")
end