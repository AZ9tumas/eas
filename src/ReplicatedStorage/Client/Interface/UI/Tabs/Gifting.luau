local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PolicyService = game:GetService("PolicyService")
local CollectionService = game:GetService("CollectionService")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)

local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local trove = Trove.new()

local mainGui = playerGui.Tabs.Gifting

local container = mainGui.Container
local list = container.Frame.List
local PlayerFrame = list.PlayerFrame
PlayerFrame.Visible = false
PlayerFrame.Parent = container

local Title = container.TextLabel

local NoPlayers = container.NoPlayers

local Gifting = {}
local Connections = {}

function Gifting.init()
	
end

function Gifting.Open(button: GuiButton)
	local ProductName = button:GetAttribute("ProductName")
	local GamepassName = button:GetAttribute("GamepassName")
	local ProductOrGamepassName = ProductName or GamepassName

	if not ProductOrGamepassName then return end
	
	local IsPass = GamepassName ~= nil
	local ProductType = IsPass and "Pass" or "Product"
	
	local Product = Products["Gifting | " .. ProductType .. " | " .. ProductOrGamepassName]
	if not Product then return end
	
	for _, connection in pairs(Connections) do
		task.cancel(connection)
	end
	
	if not InterfaceTabUtil.isTabOpen("Gifting") then
		InterfaceTabUtil.openTab("Gifting", true)
	end
	
	trove:Clean()
	
	for _, Frame in pairs(list:GetChildren()) do
		if Frame:IsA("TextButton") then
			Frame:Destroy()
		end
	end
	
	Title.Text = "Gifting: " .. ProductOrGamepassName .. (IsPass and " (Pass)" or "")
	
	local GetPlayers = Players:GetPlayers()
	
	if #GetPlayers - 1 <= 0 then
		NoPlayers.Visible = true
		return
	else
		NoPlayers.Visible = false
	end
	NoPlayers.Visible = false
	
	for _, Player in ipairs(GetPlayers) do
		if Player == localPlayer then continue end
		
		local ClientSignaledLoaded = Player:GetAttribute("ClientSignaledLoaded") ~= nil
		local ProfileLoaded = Player:GetAttribute("ProfileLoaded") ~= nil
		
		if not ClientSignaledLoaded or not ProfileLoaded then
			continue
		end
		
		--if GamepassName then
		--	local Gamepasses = Player:FindFirstChild("Gamepasses")
		--	if Gamepasses then
		--		if Gamepasses:FindFirstChild(GamepassName) then 
		--			continue
		--		end
		--	else
		--		continue
		--	end
		--end
		
		local connection = task.spawn(function()
			local PlayerFrame = PlayerFrame:Clone()
			PlayerFrame.Username.Text = "@" .. Player.Name
			PlayerFrame.DisplayName.Text = Player.DisplayName
			PlayerFrame.Icon.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			
			if localPlayer:IsFriendsWith(Player.UserId) then
				PlayerFrame.LayoutOrder = -1
				PlayerFrame.FriendUIGradient.Enabled = true
				PlayerFrame.UIGradient.Enabled = false
			end
			
			local function DisableButton()
				PlayerFrame.Interactable = false

				PlayerFrame.UIGradient.Transparency = NumberSequence.new(0.5)
				PlayerFrame.FriendUIGradient.Transparency = NumberSequence.new(0.5)
				
				PlayerFrame.GiftIcon.ImageTransparency = 0.5
				PlayerFrame.GiftIcon.ImageColor3 = Color3.fromRGB(
					150,
					150,
					150
				)
			end

			trove:Add(
				PlayerFrame.Activated:Connect(function()
					if PromptUtil.prompting then return end
					
					if GamepassName then
						Network.Gifting.Select:FireServer(Player.UserId, GamepassName, "Pass")
					elseif ProductName then
						Network.Gifting.Select:FireServer(Player.UserId, ProductName, "Product")
					end
				end)
			)

			trove:Add(
				Player.AncestryChanged:Connect(function(child: Instance, parent: Instance)
					if not parent then
						DisableButton()
					end
				end)
			)
			
			if GamepassName then
				local Gamepasses = Player:FindFirstChild("Gamepasses")
				if Gamepasses then
					trove:Add(
						Gamepasses.ChildAdded:Connect(function(child: Instance)
							if child.Name == GamepassName then
								DisableButton()
							end
						end)
					)
					
					if Gamepasses:FindFirstChild(GamepassName) then 
						DisableButton()
					end
				else
					DisableButton()
				end
			end

			if not Player.Parent then
				DisableButton()
			end
			
			PlayerFrame.Visible = true
			PlayerFrame.Parent = list
			
			Connections[Player] = nil
		end)
		
		Connections[Player] = connection
	end
end

return Gifting