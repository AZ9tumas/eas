return function(ang: number, ref: number)
	return (ang - ref + math.pi) % (2 * math.pi) - math.pi + ref
end