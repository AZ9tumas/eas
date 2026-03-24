--!strict

type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	ConnectParallel: (self: Signal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	Wait: (self: Signal<T...>) -> T...,
}

--[=[
	@within TypedBindable
	@interface Event<T...>
	.OnClientEvent Signal<T...>,
	.OnServerEvent PlayerSignal<T...>,
	.FireClient (self: Event<T...>, player: Player, T...) -> (),
	.FireAllClients (self: Event<T...>, T...) -> (),
	.FireServer (self: Event<T...>, T...) -> (),
]=]
export type Event<T...> = Instance & {
	Event: Signal<T...>,
	Fire: (self: Event<T...>, T...) -> (),
}

--[=[
	@within TypedBindable
	@interface Function<T..., R...>
	.InvokeServer (self: Function<T..., R...>, T...) -> R...,
	.OnServerInvoke (player: Player, T...) -> R...,
]=]
export type Function<T..., R...> = Instance & {
	Invoke: (self: Function<T..., R...>, T...) -> R...,
}

--[=[
	@class TypedBindable

	Simple networking package that helps create typed RemoteEvents and RemoteFunctions.

	```lua
	-- ReplicatedStorage.Network (ModuleScript)

	local TypedBindable = require(ReplicatedStorage.Packages.TypedBindable)

	-- Get the RF and RE instance creators, which create RemoteEvents/RemoteFunctions
	-- within the given parent (the script in this case):
	local RF, RE = TypedBindable.parent(script)

	-- Redeclare the TypedBindable types for simplicity:
	type RF<T..., R...> = TypedBindable.Function<T..., R...>
	type RE<T...> = TypedBindable.Event<T...>

	-- Define network table:
	return {
		-- RemoteEvent that takes two arguments - a string and a number:
		MyEvent = RE("MyEvent") :: RE<string, number>,

		-- RemoteFunction that takes two arguments (boolean, string) and returns a number:
		MyFunc = RF("MyFunc") :: RF<(boolean, string), (number)>,
	}
	```

	```lua
	-- Example usage of the above Network module:

	local Network = require(ReplicatedStorage.Network)

	-- If you type this out, intellisense will help with what the function signature should be:
	Network.MyEvent.OnClientEvent:Connect(function(player, str, num)
		-- Foo
	end)
	```

	In most cases, the `TypedBindable.parent()` function will be used to create the memoized
	RemoteFunction and RemoteEvent builder functions. From there, call the given functions
	with the desired name per remote.

	The `TypedBindable.func` and `TypedBindable.event` functions can also be used, but the
	parent must be supplied to each call, hence the helpful `parent()` memoizer.
]=]
local TypedBindable = {}

--[=[
	@return ((name: string) -> RemoteFunction, (name: string) -> RemoteEvent)

	Creates a memoized version of the `func` and `event` functions that include the `parent`
	in each call.

	```lua
	-- Create RF and RE functions that use the current script as the instance parent:
	local RF, RE = TypedBindable.parent(script)

	local remoteFunc = RF("RemoteFunc")
	```
]=]
function TypedBindable.parent(parent: Instance)
	return 
        function(name: string)
            return TypedBindable.func(name, parent)
        end,
		function(name: string)
            return TypedBindable.event(name, parent)
        end
end

--[=[
	Creates a BindableFunction with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedBindable ModuleScript.
]=]
function TypedBindable.func(name: string, parent: Instance): BindableFunction
	if script:FindFirstChild(name) then
		warn("TypedBindable: Duplicate Bindable Function with name:", name)
	end

	local bf = Instance.new("BindableFunction")
	bf.Name = name
	bf.Parent = script
	return bf
end

--[=[
	Creates a BindableEvent with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedBindable ModuleScript.
]=]
function TypedBindable.event(name: string, parent: Instance): BindableEvent
	if script:FindFirstChild(name) then
		warn("TypedBindable: Duplicate Bindable Function with name:", name)
	end

	local be = Instance.new("BindableEvent")
	be.Name = name
	be.Parent = script
	return be
end

table.freeze(TypedBindable)

return TypedBindable
