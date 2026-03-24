--local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local Bases = workspace:WaitForChild("Bases")

--local ClientData = require(ReplicatedStorage.Client.ClientData)
--local Network = require(ReplicatedStorage.Network)
--local Charm = require(ReplicatedStorage.Packages.Charm)
--local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
--local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
--local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
--local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
--local PlotUtil = require(ReplicatedStorage.Shared.Game.PlotUtil)
--local Products = require(ReplicatedStorage.Shared.Info.Products)
--local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
--local Types = require(ReplicatedStorage.Shared.Types)

--local Notification = require(ReplicatedStorage.Client.Interface.UI.Overlays.Notification)
--local stringRemoveTrailingSpaces = require(ReplicatedStorage.Shared.Utility.String.stringRemoveTrailingSpaces)

--local InterfaceSounds = ReplicatedStorage.Assets.Sounds.Interface
--local ClickSound = InterfaceSounds.ButtonClick
--local HoverSound = InterfaceSounds.ButtonHover

--local localPlayer = Players.LocalPlayer
--local playerGui = localPlayer.PlayerGui

--local trove = Trove.new()
--local Satchel = require(ReplicatedStorage.Satchel.SatchelLoader.Satchel)

local HideBackpackIfStealing = {}

--function HideBackpackIfStealing.init()
	
--end

--function HideBackpackIfStealing.characterAdded(character: Model)
--	local trove = Trove.new()
--	trove:AttachToInstance(character)

--	local function UpdateState()
--		local IsStealing = character:GetAttribute("IsStealing")
		
--		if not IsStealing then
--			if not Satchel:GetBackpackEnabled() then
--				Satchel.SetBackpackEnabled(true)
--			end
--		else
--			if Satchel:GetBackpackEnabled() then
--				Satchel.SetBackpackEnabled(false)
--			end
--		end
--	end
	
--	UpdateState()
	
--	trove:Add(
--		character:GetAttributeChangedSignal("IsStealing"):Connect(function()
--			UpdateState()
--		end)
--	)

--	--if not Satchel:GetBackpackEnabled() then
--	--	Satchel.SetBackpackEnabled(true)
--	--end
	
--	--trove:Add(
--	--	character.ChildAdded:Connect(function(child: Instance)
--	--		if child:IsA("Tool") then
--	--			local Tool: Tool = child
				
--	--			if Tool:GetAttribute("IsBeingStolen") then
--	--				Satchel.SetBackpackEnabled(false)
--	--			end
--	--		end
--	--	end)
--	--)
	
--	--trove:Add(
--	--	character.ChildRemoved:Connect(function(child: Instance)
--	--		if child:IsA("Tool") then
--	--			for _, tool in character:GetChildren() do
--	--				if tool:IsA("Tool") and tool:GetAttribute("IsBeingStolen") then
--	--					return
--	--				end
--	--			end

--	--			if not Satchel:GetBackpackEnabled() then
--	--				Satchel.SetBackpackEnabled(true)
--	--			end
--	--		end
--	--	end)
--	--)
--end

--function HideBackpackIfStealing.characterRemoving(character: Model)
	
--end

return HideBackpackIfStealing