local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local enableButton = require(ReplicatedStorage.Client.Interface.Utility.enableButton)
--local enableButton = require(ReplicatedStorage.Client.Interface.Utility.enableButtonV2)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Gamepasses = require(ReplicatedStorage.Shared.Info.Gamepasses)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)

--local GiftingModule = require(ReplicatedStorage.Client.Interface.UI.Tabs.Gifting)

local GamepassButton = {}

function GamepassButton.tagAdded(button: TextButton)
	local gamepassName = button:GetAttribute("GamepassName") :: string?
	if gamepassName == nil then
		warn("[GamepassButton] Button has no gamepass name:", button)
		return
	end
	local gamepassId = Gamepasses[gamepassName]
	if gamepassId == nil then
		warn(`[GamepassButton] Gamepass with name '{gamepassName}' doesn't exist:`, button)
		return
	end
	
	local textLabel
	
	if button:GetAttribute("PriceIsTextButton") then
		textLabel = button
	else
		textLabel = button:FindFirstChild("Price") :: TextLabel? or button:FindFirstChild("TextLabel") :: TextLabel?
			or button.Parent:FindFirstChild("Price") :: TextLabel? or button.Parent:FindFirstChild("TextLabel") :: TextLabel?
	end
	
	if not textLabel then
		textLabel = button:FindFirstChild("Frame")
		textLabel = textLabel and textLabel:FindFirstChild("Frame")
		textLabel = textLabel and textLabel:FindFirstChild("Price")
	end
	
	if textLabel == nil then
		warn("[GamepassButton] Button has no text label:", button)
		return
	end

	local PriceText = nil
	local OwnsItem = nil

	local trove = Trove.new()
	trove:AttachToInstance(button)

	textLabel.Text = "???"

	local nameLabel = button:FindFirstChild("NameLabel") :: TextLabel
	if nameLabel then
		nameLabel.Text = ""
	end

	trove:AddPromise(getProductInfo(gamepassId, Enum.InfoType.GamePass):andThen(function(productInfo)
		if productInfo.PriceInRobux then
			PriceText = `{formatCommaValue(productInfo.PriceInRobux)}`
			if not OwnsItem then
				textLabel.Text = PriceText
			end
		end
		if nameLabel then
			nameLabel.Text = productInfo.Name
		end
	end))

	button.Activated:Connect(function()
		if not button:HasTag("Gifting") then
			PromptUtil.promptGamepass(gamepassId)
		else
			--GiftingModule.Open(button)
		end
	end)


	local function checkIfOwned()
		local owned = ClientData.Gamepasses()[gamepassName] == true
		if not owned then
			return
		end
		--trove:Clean(
		OwnsItem = owned

		if not button:HasTag("Gifting") then
			textLabel.Text = "Owned"
			enableButton(button, false)
		end
	end
	
	CollectionService:GetInstanceAddedSignal("Gifting"):Connect(function(instance)
		if instance == button then
			if PriceText then
				textLabel.Text = PriceText
				enableButton(button, true)
			end
		end
	end)
	
	CollectionService:GetInstanceRemovedSignal("Gifting"):Connect(function(instance)
		if instance == button then
			if PriceText and OwnsItem then
				textLabel.Text = "Owned"
				enableButton(button, false)
			end
		end
	end)
	
	trove:Add(Charm.subscribe(ClientData.Gamepasses, checkIfOwned))
	checkIfOwned()
end

function GamepassButton.tagRemoved(button: TextButton)

end

return GamepassButton