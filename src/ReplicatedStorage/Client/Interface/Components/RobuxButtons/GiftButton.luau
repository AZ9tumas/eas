local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Products = require(ReplicatedStorage.Shared.Info.Products)
local Gamepasses = require(ReplicatedStorage.Shared.Info.Gamepasses)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)

local GiftingModule = require(ReplicatedStorage.Client.Interface.UI.Tabs.Gifting)

local GiftButton = {}

function GiftButton.tagAdded(button: TextButton)
	local productName = (button:GetAttribute("ProductName") or button:GetAttribute("GamepassName")) :: string?
	if productName == nil then
		warn("[GiftButton] Button has no product name:", button)
		return
	end
	
	local IsPass = button:GetAttribute("GamepassName") ~= nil
	local productType = IsPass and "Pass" or "Product"
	
	local productId = Products["Gifting | " .. productType .. " | " .. productName]
	if productId == nil then
		warn(`[GiftButton] Product with name '{productName}' doesn't exist:`, button)
		return
	end

	button.Activated:Connect(function()
		GiftingModule.Open(button)
	end)
end

function GiftButton.tagRemoved(button: TextButton)

end

return GiftButton