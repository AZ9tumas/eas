return {
	Name = "giveEgg";
	Aliases = {};
	Description = "Give an egg to a player or multiple players.";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "players";
			Name = "players";
			Description = "The players to give the egg to.";
		},
		{
			Type = "string";
			Name = "eggName";
			Description = "The name of the egg (e.g. \"Mythic Block\").";
		},
		{
			Type = "number";
			Name = "amount";
			Description = "How many eggs to give.";
		},
	};
}
