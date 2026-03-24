local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Types = require(ReplicatedStorage.Shared.Types)

local Notification = require(ReplicatedStorage.Client.Interface.UI.Overlays.Notification)
local stringRemoveTrailingSpaces = require(ReplicatedStorage.Shared.Utility.String.stringRemoveTrailingSpaces)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mainGui = playerGui.HUD.Buttons.TopMiddle.MyPlot.TextButton

local trove = Trove.new()

local Plot = {}

function Plot.init()
	local PlayerPlot
	
	local function UpdatePlotData()
		if not PlayerPlot then return end

		local plotData = ClientData.PlotData()
		if not plotData then return end

		PlotUtil.UpdateClientPlotData(plotData)
		PlotUtil.SetClientSpin(PlayerPlot)
	end
	
	local function UpdatePlot()
		local Plot = ClientData.Plot()
		if Plot then
			PlayerPlot = Plot
			PlotUtil.initClientPlot(PlayerPlot)
			
			UpdatePlotData()
		end
	end
	
	Charm.subscribe(ClientData.Plot, UpdatePlot)
	UpdatePlot()
	
	Charm.subscribe(ClientData.PlotData, UpdatePlotData)
	
	mainGui.Activated:Connect(function()
		local character: Model? = localPlayer.Character
		if not character then return end
		
		if not PlayerPlot then return end
		
		local SpawnArea = PlayerPlot:WaitForChild("Floor1"):WaitForChild("Spawn")
		
		local camera = workspace.CurrentCamera
		
		-- teleport player
		character:PivotTo(SpawnArea.CFrame)

		-- switch to scriptable camera
		camera.CameraType = Enum.CameraType.Scriptable

		-- position camera in front + slightly above
		local camPos =
			SpawnArea.Position
			- SpawnArea.CFrame.LookVector * 8
			+ Vector3.new(0, 3, 0)

		-- look slightly down at the area
		local lookAt =
			SpawnArea.Position + Vector3.new(0, 1.5, 0)

		camera.CFrame = CFrame.new(camPos, lookAt)
		
		camera.CameraType = Enum.CameraType.Custom

	end)
end

return Plot