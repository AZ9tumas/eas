local NUMBER_MAP = {
    {1000, 'M'},
    {900, 'CM'},
    {500, 'D'},
    {400, 'CD'},
    {100, 'C'},
    {90, 'XC'},
    {50, 'L'},
    {40, 'XL'},
    {10, 'X'},
    {9, 'IX'},
    {5, 'V'},
    {4, 'IV'},
    {1, 'I'}
    
} :: {
    { string | number }
}

return function (number: number): string
	local roman = ""
    while number > 0 do
        for _, tbl in pairs(NUMBER_MAP)do 
            local int = tbl[1] :: number
            local romanChar = tbl[2] :: string
            while number >= int do
                roman = roman .. romanChar
                number = number - int
            end
        end
    end
    return roman
end