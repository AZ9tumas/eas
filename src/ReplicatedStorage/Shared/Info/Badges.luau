local Badges = {
	--["Halloween"] = 2414817832665863, --1
}
export type Badges = typeof(Badges)

return Badges :: Badges & {
    [string]: number,
}