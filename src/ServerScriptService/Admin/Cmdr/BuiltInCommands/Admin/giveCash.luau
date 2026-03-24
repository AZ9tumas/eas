return {
	Name = "giveCash";
	Aliases = {};
	Description = "Give cash to a player or multiple players..";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "players";
			Name = "players";
			Description = "The players to give cash to.";
		},

		{
			Type = "number";
			Name = "value";
			Description = "Cash Amount.";
		},
	};
}