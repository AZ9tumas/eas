return {
	Name = "setCash";
	Aliases = {};
	Description = "Set cash of a player or multiple players..";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "players";
			Name = "players";
			Description = "The players to set cash for.";
		},
		
		{
			Type = "number";
			Name = "value";
			Description = "Cash Amount.";
		},
	};
}