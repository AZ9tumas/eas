return {
	Name = "triggerWeather";
	Aliases = {};
	Description = "Triggers a weather event..";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "string";
			Name = "name";
			Description = "The weather event name (trait) such as 'Hell Event'.";
		},
	};
}