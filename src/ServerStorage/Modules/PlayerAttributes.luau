local Players = game:GetService("Players")

local _Attributes = {} :: {
	[Player]: { [string]: any }
}

local function addPlayer(player: Player)
	_Attributes[player] = {}
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player: Player)
	_Attributes[player] = nil
end)

for _, player in pairs(Players:GetPlayers()) do
	addPlayer(player)
end

local PlayerAttributes = {}

function PlayerAttributes.getAttribute(player: Player, name: string)
	if _Attributes[player] == nil then
		return
	end
	return _Attributes[player][name]
end

function PlayerAttributes.setAttribute(player: Player, name: string, value: any)
	if _Attributes[player] == nil then
		return
	end
	_Attributes[player][name] = value
end

function PlayerAttributes.incrementAttribute(player: Player, name: string, value: number?)
	if _Attributes[player] == nil then
		return
	end
	if type(_Attributes[player][name]) ~= "number" then
		_Attributes[player][name] = 0
	end
	value = value or 1
	_Attributes[player][name] += value
end

return PlayerAttributes