local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)

local Notification = require(ReplicatedStorage.Client.Interface.UI.Overlays.Notification)
local stringRemoveTrailingSpaces = require(ReplicatedStorage.Shared.Utility.String.stringRemoveTrailingSpaces)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mainGui = playerGui.HUD.Buttons.TopMiddle.Seller.TextButton
local SellerArea = workspace:WaitForChild("Shops"):WaitForChild("Sell"):WaitForChild("SellerArea")

local trove = Trove.new()

local Seller = {}

function Seller.init()
	mainGui.Activated:Connect(function()
		local character: Model? = localPlayer.Character
		if not character then return end
		
		local camera = workspace.CurrentCamera
		
		-- teleport player
		character:PivotTo(SellerArea.CFrame)

		-- switch to scriptable camera
		camera.CameraType = Enum.CameraType.Scriptable

		-- position camera in front + slightly above
		local camPos =
			SellerArea.Position
			- SellerArea.CFrame.LookVector * 8
			+ Vector3.new(0, 3, 0)

		-- look slightly down at the area
		local lookAt =
			SellerArea.Position + Vector3.new(0, 1.5, 0)

		camera.CFrame = CFrame.new(camPos, lookAt)
		
		camera.CameraType = Enum.CameraType.Custom

	end)
end

return Seller