local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local Network = require(ReplicatedStorage.Network)
local ConfettiModule = require(ReplicatedStorage.Shared.Utility.UI.ConfettiHandler)
local confetti = ConfettiModule.new()

local CheersSound = ReplicatedStorage.Assets.Sounds.CheersSound

local SocialService = game:GetService("SocialService")

local Signal = require(ReplicatedStorage.Packages.Signal)

local localPlayer = Players.LocalPlayer

local function ConfettiEffect()
	local spawnPos = UDim2.new(0.5, 0, 1.2, 0)
	confetti:Emit(200, spawnPos)

	CheersSound:Play()
end


local PromptUtil = {}
PromptUtil.canSendInvite = nil
PromptUtil.prompting = false
PromptUtil.promptChanged = Signal.new() :: Signal.Signal<boolean>

function PromptUtil.promptGamepass(gamepassId: number, active: boolean?)
    if PromptUtil.prompting then
        return
    end
    PromptUtil.prompting = true
    PromptUtil.promptChanged:Fire(PromptUtil.prompting, active)

    local connection
	connection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(
		player: Instance, gamePassId: number, wasPurchased: boolean
	)
        if connection ~= nil then
            connection:Disconnect()
		end
		
		if wasPurchased then
			ConfettiEffect()
		end

        PromptUtil.prompting = false
        PromptUtil.promptChanged:Fire(PromptUtil.prompting)
    end)

    MarketplaceService:PromptGamePassPurchase(localPlayer, gamepassId)
end

function PromptUtil.promptProduct(productId: number, active: boolean?)
    if PromptUtil.prompting then
        return
    end
    PromptUtil.prompting = true
	PromptUtil.promptChanged:Fire(PromptUtil.prompting, active)

    local connection
    connection = MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number, productId: number, isPurchased: boolean)
        if connection ~= nil then
            connection:Disconnect()
		end
		
		if isPurchased then
			ConfettiEffect()
		end

        PromptUtil.prompting = false
        PromptUtil.promptChanged:Fire(PromptUtil.prompting)
    end)

    MarketplaceService:PromptProductPurchase(localPlayer, productId)
end

function PromptUtil.promptBundle(bundleId: number, active: boolean?)
	if PromptUtil.prompting then
		return
	end

	PromptUtil.prompting = true
	PromptUtil.promptChanged:Fire(PromptUtil.prompting, active)

	local connection
	connection = MarketplaceService.PromptBundlePurchaseFinished:Connect(function(player: Player, purchasedBundleId: number, wasPurchased: boolean)
		if connection ~= nil then
			connection:Disconnect()
		end

		if wasPurchased and purchasedBundleId == bundleId then
			ConfettiEffect()
		end

		PromptUtil.prompting = false
		PromptUtil.promptChanged:Fire(PromptUtil.prompting)
	end)

	MarketplaceService:PromptBundlePurchase(localPlayer, bundleId)
end

function PromptUtil.promptPremium()
    if PromptUtil.prompting then
        return
    end
    PromptUtil.prompting = true
    PromptUtil.promptChanged:Fire(PromptUtil.prompting)

    local connection
    connection = MarketplaceService.PromptPremiumPurchaseFinished:Connect(function()
        if connection ~= nil then
            connection:Disconnect()
        end

        PromptUtil.prompting = false
        PromptUtil.promptChanged:Fire(PromptUtil.prompting)
    end)

    MarketplaceService:PromptPremiumPurchase(localPlayer)
end

function PromptUtil.promptFriend(checkIfCan: boolean?)
	if checkIfCan == nil then
		checkIfCan = true
	end
	
	if checkIfCan then
	    local success, canSend = pcall(function()
	        return SocialService:CanSendGameInviteAsync(localPlayer)
		end)
		
		if not success or not canSend then return end
	end
	
    pcall(function()
        SocialService:PromptGameInvite(localPlayer)
    end)
end

function PromptUtil.promptFriendInvite(friendUserId: number)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(localPlayer)
	end)
	if not success or not canSend then return end
	
	local options = Instance.new('ExperienceInviteOptions')
	options.InviteUser = friendUserId
	
	pcall(function()
		SocialService:PromptGameInvite(localPlayer, options)
	end)
	
	options:Destroy()
end


function PromptUtil.canSendInviteFunc()
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(localPlayer)
	end)
	if not success or not canSend then return false end
	
	return true
end

if IsClient then
	Network.Purchases.ConfettiEffect.OnClientEvent:Connect(function()
		ConfettiEffect()
	end)
	
	Network.Purchases.promptProduct.OnClientEvent:Connect(function(id: number, active: boolean?)
		PromptUtil.promptProduct(id, active)
	end)

	Network.Purchases.promptGamepass.OnClientEvent:Connect(function(id: number, active: boolean?)
		PromptUtil.promptGamepass(id, active)
	end)

	Network.Purchases.promptBundle.OnClientEvent:Connect(function(id: number, active: boolean?)
		PromptUtil.promptBundle(id, active)
	end)
	
	task.spawn(function()
		local success, canSend = pcall(function()
			return SocialService:CanSendGameInviteAsync(localPlayer)
		end)
		if not success or not canSend then
			PromptUtil.canSendInvite = false
			return	
		end
		PromptUtil.canSendInvite = true
	end)
end

return PromptUtil