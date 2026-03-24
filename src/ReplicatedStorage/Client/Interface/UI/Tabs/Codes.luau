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

local trove = Trove.new()

local mainGui = playerGui.Tabs.Settings
local container = mainGui.Container
local claim = container.CodeFrame.RedeemButton
local textbox = container.CodeFrame:WaitForChild("Input")

local textboxShop = playerGui.
	Tabs.Shop.Container.ScrollView.CodesContainer.Frame.Frame.RedeemFrame.CodeFrame.TextBox

local claimbuttonShop = playerGui.
	Tabs.Shop.Container.ScrollView.CodesContainer.Frame.Frame.RedeemFrame.RedeemButton.Frame.BuyBtn

local Codes = {

}

function Codes.init()
	-- Once initialized, this gets called
	
	claimbuttonShop.Activated:Connect(function()
		--local Code = textbox.Text

		local Code = stringRemoveTrailingSpaces(textboxShop.Text):upper()
		if Code == "" then
			return Notification.Error("Please enter a valid code.")
		end

		local RedeemCodeStatus, AlreadyRewarded = Network.Codes.RedeemCode:InvokeServer(Code)

		if typeof(RedeemCodeStatus) ~= 'string' then
			if RedeemCodeStatus == nil then
				Notification.Error("The code you've entered isn't valid.")
			elseif RedeemCodeStatus == false then
				Notification.Warning("The code you've entered has expired.")
			elseif RedeemCodeStatus == true then
				if not AlreadyRewarded then
					Notification.Success("Successfully redeemed code: " .. Code)
				else
					Notification.Info("You've already redeemed this code.")
				end
			end
		else
			Notification.Success(RedeemCodeStatus)
		end
	end)
	
	claim.Activated:Connect(function()
		--local Code = textbox.Text
		
		local Code = stringRemoveTrailingSpaces(textbox.Text):upper()
		if Code == "" then
			return Notification.Error("Please enter a valid code.")
		end
		
		local RedeemCodeStatus, AlreadyRewarded = Network.Codes.RedeemCode:InvokeServer(Code)
		
		if typeof(RedeemCodeStatus) ~= 'string' then
			if RedeemCodeStatus == nil then
				Notification.Error("The code you've entered isn't valid.")
			elseif RedeemCodeStatus == false then
				Notification.Warning("The code you've entered has expired.")
			elseif RedeemCodeStatus == true then
				if not AlreadyRewarded then
					Notification.Success("Successfully redeemed code: " .. Code)
				else
					Notification.Info("You've already redeemed this code.")
				end
			end
		else
			Notification.Success(RedeemCodeStatus)
		end
	end)
	
	-- false = expired
	-- nil = not valid / not found
	-- true = already redeemed
end

return Codes