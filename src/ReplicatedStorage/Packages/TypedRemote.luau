local REQUIRED_MODULE = require(script.Parent._Index["sleitnick_typed-remote@0.2.0"]["typed-remote"])
export type Event<T...> = REQUIRED_MODULE.Event<T...>
export type Function<T..., R...> = REQUIRED_MODULE.Function<T..., R...>
return REQUIRED_MODULE
