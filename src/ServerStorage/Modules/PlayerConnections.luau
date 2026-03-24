-- PlayerConnections.lua
-- Player-scoped cleanup container (simple & safe)

local Players = game:GetService("Players")

local PlayerConnections = {}

export type PlayerContainer = {
	items: { any },

	Add: (self: PlayerContainer, item: any) -> any,
	Remove: (self: PlayerContainer, item: any) -> boolean,
	Clean: (self: PlayerContainer) -> (),
}

-- [Player] = container
local containers: { [Player]: PlayerContainer } = {}

-- remove item from array
local function removeItem(container, item)
	for i, v in container.items do
		if v == item then
			table.remove(container.items, i)
			return true
		end
	end
	return false
end

-- cleanup single item
local function cleanupItem(item)
	local t = typeof(item)

	if t == "RBXScriptConnection" then
		item:Disconnect()

	elseif t == "Instance" then
		item:Destroy()

	elseif t == "thread" then
		pcall(task.cancel, item)

	elseif t == "function" then
		pcall(item)

	elseif type(item) == "table" then
		-- Preferred explicit cleanup methods
		if typeof(item.Destroy) == "function" then
			item:Destroy()

		elseif typeof(item.Disconnect) == "function" then
			item:Disconnect()

		elseif typeof(item.Clean) == "function" then
			item:Clean()

		elseif typeof(item.Cleanup) == "function" then
			item:Cleanup()

		elseif typeof(item.Cancel) == "function" then
			item:Cancel()

		elseif typeof(item.Stop) == "function" then
			item:Stop()
		end
	end
end

-- cleanup player
local function cleanupPlayer(player)
	local container = containers[player]
	if not container then
		return
	end

	for _, item in container.items do
		cleanupItem(item)
	end

	container.items = nil
	containers[player] = nil
end

Players.PlayerRemoving:Connect(cleanupPlayer)

function PlayerConnections:Get(player: Player): PlayerContainer
	assert(player and player:IsA("Player"), "Player required")
	if not player:IsDescendantOf(Players) then
		return nil
	end

	if containers[player] then
		return containers[player]
	end

	local container: PlayerContainer = {
		items = {},
		Add = nil,
		Remove = nil,
		Clean = nil,
	}

	function container:Add(item: any): any
		table.insert(self.items, item)
		return item
	end

	function container:Remove(item: any): boolean
		return removeItem(self, item)
	end

	function container:Clean()
		cleanupPlayer(player)
	end

	containers[player] = container
	return container
end

return PlayerConnections
