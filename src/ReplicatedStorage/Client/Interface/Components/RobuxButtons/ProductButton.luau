local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Products = require(ReplicatedStorage.Shared.Info.Products)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local getProductInfo = require(ReplicatedStorage.Shared.Utility.Roblox.getProductInfo)

--local GiftingModule = require(ReplicatedStorage.Client.Interface.UI.Tabs.Gifting)

local ProductButton = {}

function ProductButton.tagAdded(button: TextButton)
	local productName = button:GetAttribute("ProductName") :: string?
	if productName == nil then
		warn("[ProductButton] Button has no product name:", button)
		return
	end
	local productId = Products[productName]
	if productId == nil then
		warn(`[ProductButton] Product with name '{productName}' doesn't exist:`, button)
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
	
	if textLabel then
		local prefix = if button.Parent and (button.Parent.Name == "Products" or button:HasTag("RobuxUni")) then "" else ""
		textLabel.Text = prefix .. "???"


		local nameLabel = button:FindFirstChild("NameLabel") :: TextLabel
		if nameLabel then
			nameLabel.Text = ""
		end
		getProductInfo(productId, Enum.InfoType.Product):andThen(function(productInfo)
			textLabel.Text = prefix .. `{formatCommaValue(productInfo.PriceInRobux)}`
			if nameLabel then
				nameLabel.Text = productInfo.Name
			end
		end)
	end

	button.Activated:Connect(function()
		if not button:HasTag("Gifting") then
			PromptUtil.promptProduct(productId)
		else
			--GiftingModule.Open(button)
		end
	end)
end

function ProductButton.tagRemoved(button: TextButton)

end

return ProductButton