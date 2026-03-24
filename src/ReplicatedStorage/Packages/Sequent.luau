local REQUIRED_MODULE = require(script.Parent._Index["sleitnick_sequent@0.1.0"]["sequent"])
export type Sequent<T> = REQUIRED_MODULE.Sequent<T>
export type SequentConnection = REQUIRED_MODULE.SequentConnection 
export type SequentEvent<T> = REQUIRED_MODULE.SequentEvent<T>
return REQUIRED_MODULE
