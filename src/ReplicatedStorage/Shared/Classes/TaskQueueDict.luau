--!nocheck

-- TaskQueueDict
-- Stephen Leitnick
-- November 20, 2021

--[=[
	@class TaskQueueDict
	A queue that flushes all objects at the end of the current
	execution step. This works by scheduling all tasks with
	`task.defer`.

	A possible use-case is to batch all requests being sent through
	a RemoteEvent to help prevent calling it too many times on
	the same frame.

	```lua
	local bulletQueue = TaskQueueDict.new(function(bullets)
		bulletRemoteEvent:FireAllClients(bullets)
	end)

	-- Add 3 bullets. Because they're all added on the same
	-- execution step, they will all be grouped together on
	-- the next queue flush, which the above function will
	-- handle.
	bulletQueue:Add(someBullet)
	bulletQueue:Add(someBullet)
	bulletQueue:Add(someBullet)
	```
]=]


export type TaskQueueDict<T> = {
	__index: TaskQueueDict<T>,

	_queue: {},
	_flushing: boolean,
	_scheduled: thread?,
	_onFlush: ({ [string]: T }) -> (),

	new: (T) -> (TaskQueueDict<T>),
	Add: (self: TaskQueueDict<T>, key: string, value: T) -> (),
	Clear: (self: TaskQueueDict<T>) -> (),
	Destroy: (self: TaskQueueDict<T>) -> (),
}


local TaskQueueDict = {}
TaskQueueDict.__index = TaskQueueDict

--[=[
	@param onFlush ({T}) -> ()
	@return TaskQueueDict<T>
	Constructs a new TaskQueueDict.
]=]
function TaskQueueDict.new<T>(onFlush: ({ [string]: T }) -> ()): TaskQueueDict<T>
	local self = setmetatable({}, TaskQueueDict)

	self._queue = {}
	self._flushing = false
	self._scheduled = nil :: thread?
	self._onFlush = onFlush

	return self
end

--[=[
	@param object T
	Add an object to the queue.
]=]
function TaskQueueDict.Add<T>(self: TaskQueueDict, key: string, value: T)
	self._queue[key] = value

	if self._scheduled == nil then
		self._scheduled = task.defer(function()
			self._flushing = true
			self._onFlush(self._queue)
			table.clear(self._queue)
			self._flushing = false
			self._scheduled = nil
		end)
	end
end

--[=[
	Clears the TaskQueueDict. This will clear any tasks
	that were scheduled to be flushed on the current
	execution frame.

	```lua
	queue:Add(something1)
	queue:Add(something2)
	queue:Clear()
	```
]=]
function TaskQueueDict.Clear(self: TaskQueueDict)
	if self._flushing then
		return
	end

	if self._scheduled ~= nil then
		task.cancel(self._scheduled)
		self._scheduled = nil
	end

	table.clear(self._queue)
end

--[=[
	Destroys the TaskQueueDict. Just an alias for `Clear()`.
]=]
function TaskQueueDict.Destroy(self: TaskQueueDict)
	self:Clear()
end

return TaskQueueDict
