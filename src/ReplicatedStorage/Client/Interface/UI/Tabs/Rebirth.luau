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
local TimeFormat = require(ReplicatedStorage.Shared.Utility.Format.TimeFormat)

local RebirthsModule = require(ReplicatedStorage.Data.Rebirths)

local Notification = require(ReplicatedStorage.Client.Interface.UI.Overlays.Notification)
local stringRemoveTrailingSpaces = require(ReplicatedStorage.Shared.Utility.String.stringRemoveTrailingSpaces)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mainGui = playerGui.Tabs.Rebirth
local container = mainGui.Container
local frame = container.Frame
local RequirementsFrame = frame.Requirements
local RewardsFrame = frame.Rewards

local RewardLabel = RewardsFrame.RewardLabel
local CashRequirementLabel = RequirementsFrame.CashRequirement
local ItemRequirementLabel = RequirementsFrame.ItemRequirement

local Rebirthbutton = frame.RebirthButton

local trove = Trove.new()

local Rebirth = {}

function Rebirth.init()
	local function UpdateRebirthsUI()
		local Rebirths = ClientData.Rebirths()
		if not Rebirth then return end
		
		local NextRebirth = Rebirths + 1
		local NextRebirthData = RebirthsModule[NextRebirth] :: RebirthsModule.RebirthData
		if not NextRebirthData then 
			RewardLabel.Text = "Max Rebirths"
			CashRequirementLabel.Text = "Max Rebirths"
			ItemRequirementLabel.Text = "Max Rebirths"
			
			RewardLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			CashRequirementLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			ItemRequirementLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			
			Rebirthbutton.Visible = false
			
			return
		end
		
		local RewardLabelCache = ""
		local RequirementsLabelCache = ""
		local ItemRequirementLabelCache = ""
		
		if NextRebirthData.Rewards.Slots then
			RewardLabelCache ..=
				`+{NextRebirthData.Rewards.Slots} Slot{NextRebirthData.Rewards.Slots > 1 and "s" or ""}`
		end
		
		if NextRebirthData.Rewards.EggLuck then
			RewardLabelCache ..=
				`<br></br>+{math.floor(NextRebirthData.Rewards.EggLuck * 100)}% Egg Luck`
		end
		
		if NextRebirthData.Rewards.CashMulti then
			RewardLabelCache ..=
				`<br></br>+{math.floor(NextRebirthData.Rewards.CashMulti * 100)}% Cash Multi`
		end
		
		if NextRebirthData.Rewards.OfflineEarningExtension then
			local ExtensionTime = NextRebirthData.Rewards.OfflineEarningExtension
			
			RewardLabelCache ..=
				`<br></br>{TimeFormat.formatDuration(ExtensionTime)} Offline Earning Extension`
		end
		
		if NextRebirthData.Rewards.UnlockFloorNum then
			RewardLabelCache ..=
				`<br></br>Unlocks Floor #{NextRebirthData.Rewards.UnlockFloorNum}`
		end
		
		RewardLabel.Text = RewardLabelCache
		
		if NextRebirthData.Requirements.Cash then
			RequirementsLabelCache ..= `${formatCommaValue(NextRebirthData.Requirements.Cash)} Cash`
		end
		
		CashRequirementLabel.Text = RequirementsLabelCache
		
		if NextRebirthData.Requirements.Hatchables then
			for _, hatchable in NextRebirthData.Requirements.Hatchables do
				ItemRequirementLabelCache ..= 
					`{hatchable.RequiredAmount or 1}x {hatchable.Rarity} {hatchable.Mutation}<br></br>`
			end
		end
		
		ItemRequirementLabel.Text = ItemRequirementLabelCache
	end
	
	Rebirthbutton.Activated:Connect(function()
		local Rebirths = ClientData.Rebirths()
		if not Rebirth then return end
		
		local NextRebirth = Rebirths + 1
		Network.Plots.Rebirth:FireServer(NextRebirth)
	end)
	
	Charm.subscribe(ClientData.Rebirths, UpdateRebirthsUI)
	UpdateRebirthsUI()
end

return Rebirth