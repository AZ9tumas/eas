local ProximityPrompt = script.Parent
local ServerStorage = game:GetService("ServerStorage")

local uiName = "SellerBillboard"
local uiAsset = ServerStorage:FindFirstChild(uiName)

if not uiAsset then
	warn("SellerBillboard not found in ServerStorage")
end

ProximityPrompt.Triggered:Connect(function(player)
	local playerGui = player:WaitForChild("PlayerGui")

	local oldUI = playerGui:FindFirstChild(uiName)
	if oldUI then
		oldUI:Destroy()
	end

	if uiAsset then
		local newUI = uiAsset:Clone()
		newUI.Parent = playerGui

		local npcRoot = ProximityPrompt.Parent
		if npcRoot:IsA("Model") then
			npcRoot = npcRoot.PrimaryPart or npcRoot:FindFirstChild("HumanoidRootPart")
		end

		if newUI:FindFirstChild("OriginPart") then
			newUI.OriginPart.Value = npcRoot
		end

		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")
		newUI.Adornee = hrp
	end
end)