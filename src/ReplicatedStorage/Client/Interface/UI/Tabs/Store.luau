local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Gamepasses = require(ReplicatedStorage.Shared.Info.Gamepasses)
local Products = require(ReplicatedStorage.Shared.Info.Products)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

-- New UI references: NewUI.Frames.Store
local storeGui = playerGui:WaitForChild("NewUI").Frames.Store
local topFrame = storeGui.Top
local closeButton = topFrame.Close
local mainFrame = storeGui.Main
local scrollingFrame = mainFrame.ScrollingFrame

-- Animation helpers (matching Rebirth.luau patterns)
local tHover = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tClick = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tRelease = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

local function bindButtonAnimations(btn: GuiButton)
	local scaleObj = btn:FindFirstChild("UIScale")
	if not scaleObj then
		scaleObj = Instance.new("UIScale")
		scaleObj.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(scaleObj, tHover, { Scale = 1.05 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(scaleObj, tHover, { Scale = 1.0 }):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(scaleObj, tClick, { Scale = 0.85 }):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scaleObj, tRelease, { Scale = 1.05 }):Play()
	end)
end

-- Visual effects from old ShopClient_EAS (rays, shine glows, sparkle emitters)
for _, obj in storeGui:GetDescendants() do
	if obj:IsA("ImageLabel") and obj:GetAttribute("IsRay") then
		TweenService:Create(obj, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
	elseif obj:IsA("UIGradient") and obj.Name == "ShineGlow" then
		task.spawn(function()
			while task.wait(1.5) do
				if not obj.Parent then break end
				obj.Offset = Vector2.new(-1, 0)
				local t = TweenService:Create(obj, TweenInfo.new(1.2, Enum.EasingStyle.Linear), { Offset = Vector2.new(1, 0) })
				t:Play()
				t.Completed:Wait()
			end
		end)
	elseif obj:IsA("Frame") and obj:GetAttribute("SparkleEmitter") then
		task.spawn(function()
			local rng = Random.new()
			while task.wait(0.5) do
				if not obj.Parent then break end
				local sp = Instance.new("ImageLabel")
				sp.Size = UDim2.new(0, 20, 0, 20)
				sp.Position = UDim2.new(rng:NextNumber(0, 1), 0, rng:NextNumber(0, 1), 0)
				sp.BackgroundTransparency = 1
				sp.Image = "rbxassetid://6031302836"
				sp.ImageTransparency = 1
				sp.Parent = obj

				TweenService:Create(sp, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
					ImageTransparency = 0,
					Rotation = 180,
					Size = UDim2.new(0, 40, 0, 40),
				}):Play()
				Debris:AddItem(sp, 2)
			end
		end)
	end
end

-- Close button
bindButtonAnimations(closeButton)
closeButton.MouseButton1Click:Connect(function()
	InterfaceTabUtil.closeAllTabs()
end)

-- Purchase mapping: "SectionName" for top-level, "SectionName/SubItemName" for Passes sub-items
-- Adjust values to match your gamepass/product names in Gamepasses and Products modules
local PURCHASE_MAP: { [string]: { type: string, name: string } } = {
	StarterPack = { type = "gamepass", name = "Starter Pack" },
	ExclusiveEgg = { type = "product", name = "Exclusive Block" },
	DoubleLuck = { type = "product", name = "x2 Luck (15m)" },
	EnchantSpeed = { type = "product", name = "Super Speed" },
	["Passes1/AutoCollect"] = { type = "gamepass", name = "Auto-Collect" },
	["Passes1/BlockSpeed"] = { type = "product", name = "x2 Cash (15m)" },
	["Passes2/AutoCollect"] = { type = "gamepass", name = "Lucky Clover" },
	["Passes2/BlockSpeed"] = { type = "product", name = "x2 Luck (15m)" },
}

local function promptPurchase(purchaseType: string, purchaseName: string)
	if purchaseType == "gamepass" then
		local id = Gamepasses[purchaseName]
		if id then
			PromptUtil.promptGamepass(id)
		else
			warn("[Store] Unknown gamepass:", purchaseName)
		end
	elseif purchaseType == "product" then
		local id = Products[purchaseName]
		if id then
			PromptUtil.promptProduct(id)
		else
			warn("[Store] Unknown product:", purchaseName)
		end
	end
end

-- Walk up from a Buy button to find its section (direct child of ScrollingFrame)
-- and optional sub-item (e.g. AutoCollect, BlockSpeed inside Passes1/Passes2)
local function findSection(descendant: Instance): (Frame?, Frame?)
	local current = descendant.Parent
	local subItem: Frame? = nil

	while current and current ~= scrollingFrame do
		if current.Parent == scrollingFrame then
			return current :: Frame, subItem
		end
		-- Track the closest meaningful Frame ancestor (skip "Main" and "Buttons" containers)
		if current:IsA("Frame") and current.Name ~= "Main" and current.Name ~= "Buttons" and subItem == nil then
			subItem = current :: Frame
		end
		current = current.Parent
	end

	return nil, nil
end

-- Wire all Buy TextButtons found anywhere inside the ScrollingFrame
for _, desc in scrollingFrame:GetDescendants() do
	if not (desc:IsA("TextButton") and desc.Name == "Buy") then continue end

	local section, subItem = findSection(desc)
	if not section then continue end

	local key = section.Name
	if subItem and subItem ~= section then
		key = section.Name .. "/" .. subItem.Name
	end

	local mapping = PURCHASE_MAP[key] or PURCHASE_MAP[section.Name]

	bindButtonAnimations(desc)

	if mapping then
		desc.Activated:Connect(function()
			promptPurchase(mapping.type, mapping.name)
		end)
	else
		warn("[Store] No purchase mapping for:", key)
	end
end

local Store = {}

function Store.init()
	-- No dynamic data subscriptions needed for Store — purchases are static
	-- If future items need dynamic visibility, subscribe to ClientData here
end

return Store
