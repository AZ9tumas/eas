--!strict

local Dictionary = require(script.Dictionary)
local List = require(script.List)
local isEmpty = require(script.isEmpty)
local None = require(script.None)
local Globals = require(script.Globals)

export type None = None.None
export type Dictionary<K, V> = Globals.Dictionary<K, V>
export type List<V> = Globals.List<V>
export type Table<V> = Globals.List<V>

return {
	Dictionary = Dictionary,
	List = List,
	isEmpty = isEmpty,
	None = None,
}
