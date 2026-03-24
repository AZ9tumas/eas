-- DeferTask
-- Stephen Leitnick
-- November 20, 2021

--[=[
	@class DeferTask
	A queue that flushes all objects at the end of the current
	execution step. This works by scheduling all tasks with
	`task.defer`.

	A possible use-case is to batch all requests being sent through
	a RemoteEvent to help prevent calling it too many times on
	the same frame.

	```lua
	local bulletQueue = DeferTask.new(function()
		bulletRemoteEvent:FireAllClients()
	end)

	```
]=]


local DeferTask = {}
DeferTask.__index = DeferTask

--[=[
	@param onFlush ({T}) -> ()
	@return DeferTask<T>
	Constructs a new DeferTask.
]=]
function DeferTask.new(onFlush: () -> ()): DeferTask
	local self = setmetatable({}, DeferTask)

	self._flushing = false
	self._scheduled = nil :: thread?
	self._onFlush = onFlush

	return self
end

export type DeferTask = typeof(DeferTask.new(...))

--[=[
	@param object T
	Add an object to the queue.
]=]
function DeferTask.Defer<T>(self: DeferTask)
	if self._scheduled ~= nil then
		return
	end
	self._scheduled = task.defer(function()
		self._flushing = true
		self._onFlush()
		self._flushing = false
		self._scheduled = nil
	end)
end

--[=[
	Clears the DeferTask. This will clear any tasks
	that were scheduled to be flushed on the current
	execution frame.

	```lua
	queue:Defer(something1)
	queue:Clear()
	```
]=]
function DeferTask.Clear(self: DeferTask)
	if self._flushing then
		return
	end

	if self._scheduled ~= nil then
		task.cancel(self._scheduled)
		self._scheduled = nil
	end
end

--[=[
	Destroys the DeferTask. Just an alias for `Clear()`.
]=]
function DeferTask.Destroy(self: DeferTask)
	self:Clear()
end

return DeferTask
