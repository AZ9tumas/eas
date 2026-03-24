local REQUIRED_MODULE = require(script.Parent._Index["littensy_charm-sync@0.3.0"]["charm-sync"])
export type SyncPayload = REQUIRED_MODULE.SyncPayload 
export type ServerSyncer = REQUIRED_MODULE.ServerSyncer
return REQUIRED_MODULE
