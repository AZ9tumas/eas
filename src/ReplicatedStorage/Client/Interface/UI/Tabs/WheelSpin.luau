--//Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Network = require(ReplicatedStorage.Network)
local Charm = require(ReplicatedStorage.Packages.Charm)
local ItemUtil = require(ReplicatedStorage.Shared.Game.ItemUtil)
local formatCommaValue = require(ReplicatedStorage.Shared.Utility.Format.formatCommaValue)
local Diff = require(ReplicatedStorage.Shared.Utility.Table.Diff)
local PromptUtil = require(ReplicatedStorage.Shared.Utility.PromptUtil)
local Products = require(ReplicatedStorage.Shared.Info.Products)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Notification = require(ReplicatedStorage.Client.Utility.Notification)
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local InterfaceSounds = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds")
	:WaitForChild("Interface")
local ButtonHover = InterfaceSounds:WaitForChild("ButtonHover")
local ButtonClick = InterfaceSounds:WaitForChild("ButtonClick")

--//Required
local Wheel_Data = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Wheel"))
local PromptUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utility")
	:WaitForChild("PromptUtil")
)

--//remotes
local SpinWheel = Network.Spin.SpinWheel

--//player ui
local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local WheelUI = PlayerGui:WaitForChild("Tabs"):WaitForChild("WheelSpin")
local WheelFrame = WheelUI:WaitForChild("Container")

--//sounds
local WheelSpinSound = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("WheelSpin")

--buttons
local Buttons = WheelFrame:WaitForChild("Buttons")
local Buttons_Spin = Buttons:WaitForChild("Spin"):WaitForChild("Toggle")
local Buttons_BuyOneDiscount = Buttons:WaitForChild("Buy1Discount")
local Buttons_BuyThree = Buttons:WaitForChild("Buy3")

local TEXT_Spin = Buttons:WaitForChild("Spin"):WaitForChild("Middle"):WaitForChild("SpinLabel")

--Wheel frame
local Wheel = WheelFrame:WaitForChild("Wheel")
local Wheel_List = Wheel:WaitForChild("List")

-- values

local ONE_SPIN = Products["1 Spin"]
local THREE_SPIN = Products["3 Spins"]

--vars
local WheelTween
local SpinningTween
local Connections = {}

local Can_Spin = true
local Is_Spinning = false
local Default_Wheel_Speed = 0.35
local Wheel_Spin_Speed = Default_Wheel_Speed
local Keep_Icons_Upright = false

--local Normal_Spin_FPS = 20
local Normal_Spin_FPS = 60
local Open_Spin_FPS = 60

local Current_Wheel_FPS = Normal_Spin_FPS
local Current_World_Wheel_FPS = Normal_Spin_FPS

--where the wheel should spin to
local RotationTableINDEX = {
	[1] = NumberRange.new(-30, 30), --1st slot -- 60
	--[2] = NumberRange.new(29, 90), --2nd slot
	[2] = NumberRange.new(31, 90), --2nd slot -- 59
	[3] = NumberRange.new(91, 150), --3rd slot -- 59
	[4] = NumberRange.new(151, 210), --4th slot -- 59
	[5] = NumberRange.new(211, 270), --5th slot -- 59
	[6] = NumberRange.new(271, 330), --6th slot -- 59
}

local RotationTable = {}

-- added by ranu
for Index, Info in Wheel_Data do
	local Info_Name: string = Info.Name

	RotationTable[Info_Name] = RotationTableINDEX[Index]
end

local StartClock = os.clock()

local WheelSpin = {}

function WheelSpin.FillWheelUI(WheelList)
	for Index, Info in Wheel_Data do
		local ListSlot = WheelList:FindFirstChild(Index)
		if not ListSlot then continue end

		local Info_Name: string = Info.Name
		local Info_Image: string = Info.ImageId
		local Info_Rarity: number = Info.Rarity
		local Info_Rate: string? = Info.Rate

		local Name_Label: TextLabel = ListSlot:WaitForChild("Title")
		local Chance_Label: TextLabel = ListSlot:WaitForChild("Chance")
		local Icon_Image: ImageLabel = ListSlot:WaitForChild("Icon")
		
		local Rate_Label: ImageLabel = ListSlot:FindFirstChild("Rate")
		if Rate_Label then
			if Info_Rate then
				Rate_Label.Text = Info_Rate
				Rate_Label.Visible = true
			else
				Rate_Label.Visible = false
			end
		end

		Name_Label.Text = Info_Name
		Chance_Label.Text = Info_Rarity.."%"
		Icon_Image.Image = Info_Image
	end
end

--synchronizes physical wheels rotation
function WheelSpin.UpdatePhysicalWheel(NewWheel)
	local OverlayPart: BasePart = NewWheel:WaitForChild("Overlay")
	local SurfaceGui = OverlayPart:WaitForChild("SurfaceGui")
	local TaggedWheelFrame = SurfaceGui:WaitForChild("Wheel")
	local RootPart: BasePart = NewWheel:WaitForChild("Root")

	local OpenProximity: ProximityPrompt = RootPart:WaitForChild("ProximityPrompt")

	local NewWheelList = TaggedWheelFrame:WaitForChild("List")
	WheelSpin.FillWheelUI(NewWheelList)

	OpenProximity.Triggered:Connect(function(PlayerWhoTriggered: Player)
		if PlayerWhoTriggered == Player then
			if not InterfaceTabUtil.isTabOpen("WheelSpin") then
				InterfaceTabUtil.openTab("WheelSpin", true)
			end
		end
	end)

	local elapsed = 0

	RunService.Heartbeat:Connect(function(dt: number)
		TaggedWheelFrame.Rotation = Wheel.Rotation
	end)
end

--regular spin when the wheel is not spinning to a prize
function WheelSpin.RegularSpin()
	if WheelTween then
		WheelTween:Disconnect()
	end

	WheelTween = RunService.Heartbeat:Connect(function(dt: number)
		Wheel.Rotation += Wheel_Spin_Speed
	end)
end

--spin wheel to a prize 
function WheelSpin.SpinTo(PrizeName: string)
	Is_Spinning = true
	if WheelTween then
		WheelTween:Disconnect()
	end
	
	--Current_World_Wheel_FPS = Open_Spin_FPS

	--get the rotation based on the prize name, and get a random rotation within the range
	local RotationRange: NumberRange = RotationTable[PrizeName]
	local Rotation = math.random(RotationRange.Min, RotationRange.Max)

	SpinningTween = TweenService:Create(
		Wheel,
		TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		--{Rotation = (3240 * 2) + Rotation}
		{Rotation = (3240 * 2) - Rotation}
	)

	Wheel.Rotation = 0

	-- Track rotation during tween
	local conn
	local lastClickAngle = 0
	conn = RunService.Heartbeat:Connect(function()
		local currentRot = Wheel.Rotation

		-- Check if we've crossed a 60 step
		if currentRot - lastClickAngle >= 60 then
			lastClickAngle = lastClickAngle + 60
			WheelSpinSound:Play()
		end
	end)

	SpinningTween:Play()
	SpinningTween.Completed:Once(function()
		conn:Disconnect()

		-- notify here about Prize
		--TriggerNotification(nil, nil, PrizeName)
		Notification.Success("You received " .. PrizeName)

		wait(0.2)
		task.wait(0.2)
		wait(0.2)
		task.wait(0.2)
		wait(0.2)

		--Current_World_Wheel_FPS = Normal_Spin_FPS
		Is_Spinning = false
		Can_Spin = true
		WheelSpin.RegularSpin()
	end)
end

--when wheel becomes visible/not visible
function WheelSpin.ToggleWheel(Toggle: boolean)
	if Toggle then
		if not Is_Spinning and Can_Spin then
			WheelSpin.RegularSpin()
		end

		--spin wheel connection
		Connections[Buttons_Spin] = Buttons_Spin.Activated:Connect(function()
			if Is_Spinning or not Can_Spin then return end
			
			ButtonClick:Play()

			if ClientData.Spins() <= 0 then
				-- Not enough Spins / notify them

				Notification.Error("You don't have enough Spins!")
				return
				--TriggerNotification()
			end

			--invoke server to check if player can spin
			local Result = SpinWheel:InvokeServer()
			--check if player can spin, not enough currency etc
			if Result then
				Can_Spin = false
				--spin the wheel
				WheelSpin.SpinTo(Result)
			else
				--player can't spin / notify them

				Notification.Error("You don't have enough Spins!")
				--TriggerNotification()
			end
		end)

		--buy discount connection
		Connections[Buttons_BuyOneDiscount] = Buttons_BuyOneDiscount.Activated:Connect(function()
			--MarketplaceService:PromptProductPurchase(Player, ONE_SPIN)
			ButtonClick:Play()
			PromptUtil.promptProduct(ONE_SPIN)
		end)

		--buy three connection
		Connections[Buttons_BuyThree] = Buttons_BuyThree.Activated:Connect(function()
			ButtonClick:Play()
			--MarketplaceService:PromptProductPurchase(Player, THREE_SPIN)
			PromptUtil.promptProduct(THREE_SPIN)
		end)
	else
		for _, Connection: RBXScriptConnection in Connections do
			Connection:Disconnect()
		end
	end
end

function WheelSpin.init()
	if InterfaceTabUtil.isTabOpen("WheelSpin") then
		WheelSpin.RegularSpin()
	else
		WheelSpin.RegularSpin()
	end

	WheelUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		local WheelVisible = InterfaceTabUtil.isTabOpen("WheelSpin")

		if WheelVisible then
			--Current_Wheel_FPS = Open_Spin_FPS
			--Wheel_Spin_Speed = Default_Wheel_Speed * (Normal_Spin_FPS / Open_Spin_FPS)
			
			WheelSpin.ToggleWheel(true)
		else
			--Current_Wheel_FPS = Normal_Spin_FPS
			--Wheel_Spin_Speed = Default_Wheel_Speed
			
			WheelSpin.ToggleWheel(false)
		end
	end)

	for _, TaggedWheel in CollectionService:GetTagged("SpinWheel") do
		WheelSpin.UpdatePhysicalWheel(TaggedWheel)
	end

	CollectionService:GetInstanceAddedSignal("SpinWheel"):Connect(function(NewWheel)
		WheelSpin.UpdatePhysicalWheel(NewWheel)
	end)

	WheelSpin.FillWheelUI(Wheel_List)

	WheelUI:GetPropertyChangedSignal("Enabled"):Connect(function()
		if InterfaceTabUtil.isTabOpen("WheelSpin") then
			for _, TaggedWheel in CollectionService:GetTagged("SpinWheel") do
				local RootPart: BasePart = TaggedWheel:WaitForChild("Root")

				local OpenProximity: ProximityPrompt = RootPart:WaitForChild("ProximityPrompt")
				OpenProximity.Enabled = false
			end
		else
			for _, TaggedWheel in CollectionService:GetTagged("SpinWheel") do
				local RootPart: BasePart = TaggedWheel:WaitForChild("Root")

				local OpenProximity: ProximityPrompt = RootPart:WaitForChild("ProximityPrompt")
				OpenProximity.Enabled = true
			end
		end
	end)

	Charm.subscribe(ClientData.Spins, function()
		TEXT_Spin.Text = `Spin ({ClientData.Spins()})`
	end)
	TEXT_Spin.Text = `Spin ({ClientData.Spins()})`

	local function formatTime(seconds: number): string
		if seconds >= 3600 then
			local hours = math.floor(seconds / 3600)
			return tostring(hours) .. " hour" .. (hours > 1 and "s" or "")
		elseif seconds >= 60 then
			local minutes = math.floor(seconds / 60)
			return tostring(minutes) .. " minute" .. (minutes > 1 and "s" or "")
		else
			return tostring(seconds) .. " second" .. (seconds ~= 1 and "s" or "")
		end
	end

	local lastRemaining = ""
	local lastSpins = 0

	local function UpdateSpinTime()
		local NextSpinAt = ClientData.NextSpinAt()
		local remaining = NextSpinAt - os.time()
		local remainingFormatted = formatTime(remaining)

		local Spins = ClientData.Spins() or 0
		if remainingFormatted == lastRemaining and Spins == lastSpins then return end
		lastSpins = Spins

		lastRemaining = remainingFormatted

		for _, TaggedWheel in CollectionService:GetTagged("SpinWheel") do
			local Overhead: BasePart = TaggedWheel:WaitForChild("Overhead")

			local BillboardGui: BillboardGui = Overhead:WaitForChild("BillboardGui")
			local Countdown: TextLabel = BillboardGui:WaitForChild("Countdown")

			if os.time() <= NextSpinAt and Spins <= 0 then
				Countdown.Text = `Free Spin in {remainingFormatted}`
			else
				Countdown.Text = "Spin Available!"
			end
		end
	end

	Charm.subscribe(ClientData.NextSpinAt, function()
		UpdateSpinTime()
	end)

	UpdateSpinTime()

	task.spawn(function()
		while task.wait(1) do
			UpdateSpinTime()
		end
	end)
end

task.spawn(function()
	task.wait(1)
	wait(1)

	-- Collect all ImageLabels and ImageButtons inside the frame
	local imagesToPreload = {}

	for _, obj in pairs(WheelUI:GetDescendants()) do
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			--if obj.Image ~= "" and obj.Image ~= "rbxassetid://0" then
			--	table.insert(imagesToPreload, obj.Image)
			--end

			--if obj:IsA("ImageButton") then
			--	if obj.HoverImage ~= "" and obj.HoverImage ~= "rbxassetid://0" then
			--		table.insert(imagesToPreload, obj.HoverImage)
			--	end
			--end

			table.insert(imagesToPreload, obj)
		end
	end

	-- Preload all images
	local success, err = pcall(function()
		ContentProvider:PreloadAsync(imagesToPreload)
	end)

	if not success then
		warn("Failed to preload images: ", err)
	end


	wait(2)

	imagesToPreload = nil
end)

local CloseButton = WheelFrame:WaitForChild("CloseButton")

CloseButton.Activated:Connect(function()
	ButtonClick:Play()
end)

for _, button in pairs(WheelUI:GetDescendants()) do
	if button:IsA("TextButton") or button:IsA("ImageButton") then
		button.MouseEnter:Connect(function()
			ButtonHover:Play()
		end)
	end
end

return WheelSpin
