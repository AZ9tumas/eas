-- DISABLED: Trading UI has been migrated to NewUI.Frames (Trade, TradeList, TradeRequest)
-- See ReplicatedStorage.Client.Interface.UI.Tabs.Trade for the new implementation
do return end

local TweenService = game:GetService("TweenService")
local UI = script.Parent.Parent
local Main = script.Parent

local LeftPanel = Main:FindFirstChild("Inventory")
local RightPanel = Main:FindFirstChild("TradeFrame")
--for _, child in pairs(Main:GetChildren()) do
--	if child.Name == "TradeFrame" and child.Position.X.Scale < 0.5 then
--        LeftPanel = child
--	elseif child.Name == "Inventory" and child.Position.X.Scale >= 0.5 then
--        RightPanel = child
--    end
--end

local AddToOfferBtn = LeftPanel:FindFirstChild("AddToOfferBtn")
local AddToOfferText = AddToOfferBtn:FindFirstChild("MainFrame"):FindFirstChildOfClass("TextLabel")
local YoursScroll = RightPanel:FindFirstChild("YourOffer"):FindFirstChild("YoursScroll", true)

local TradeState = "Ready" -- Ready, Waiting, Accept
local selectedItems = {}

local COLORS = {
    ConfirmTop = Color3.fromRGB(244, 150, 49),
    ConfirmBot = Color3.fromRGB(220, 100, 20),
    ConfirmShadow = Color3.fromRGB(150, 50, 10),

    WaitTop = Color3.fromRGB(200, 200, 200),
    WaitBot = Color3.fromRGB(100, 100, 100),
    WaitShadow = Color3.fromRGB(50, 50, 50),

    AcceptTop = Color3.fromRGB(160, 245, 120),
    AcceptBot = Color3.fromRGB(50, 210, 60),
    AcceptShadow = Color3.fromRGB(20, 120, 25),
}

local function bindButton(btn)
    local main = btn:FindFirstChild("MainFrame") or btn:FindFirstChildOfClass("Frame")
    if not main then return end
    
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local scaleObj = btn:FindFirstChild("UIScale")
    
    btn.MouseEnter:Connect(function()
        local ogColor = main.BackgroundColor3
        TweenService:Create(main, tweenInfo, {
            BackgroundColor3 = Color3.new(
                math.clamp(ogColor.R + 0.1, 0, 1),
                math.clamp(ogColor.G + 0.1, 0, 1),
                math.clamp(ogColor.B + 0.1, 0, 1)
            )
        }):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 1.05}):Play() end
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(main, tweenInfo, {BackgroundColor3 = Color3.new(1,1,1)}):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 1}):Play() end
    end)
    
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0)}):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 0.95}):Play() end
    end)
    
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(1,0,1,-btn.Size.Y.Offset * 0.1), Position = UDim2.new(0,0,0,0)}):Play()
        if scaleObj then TweenService:Create(scaleObj, tweenInfo, {Scale = 1.05}):Play() end
    end)
    
    -- Close & Cancel
    if btn:GetAttribute("IsClose") or btn:GetAttribute("IsCancelAction") then
        btn.Activated:Connect(function()
            UI.Enabled = false
        end)
    end
    
    -- Inventory selection logic
    if btn:GetAttribute("IsInvItem") then
        local stroke = main:FindFirstChild("SelectorStroke")
        
        btn.Activated:Connect(function()
            local index = table.find(selectedItems, btn)
            if index then
                -- Deselect
                table.remove(selectedItems, index)
                TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.new(0,0,0), Thickness = 2}):Play()
            else
                -- Select (Green vibrant glow with the implicit back shadow outline)
                table.insert(selectedItems, btn)
                TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(90, 255, 100), Thickness = 4}):Play()
            end

            if #selectedItems > 0 then
                AddToOfferBtn.Visible = true
                AddToOfferText.Text = "Add to Offer (" .. #selectedItems .. ")"
            else
                AddToOfferBtn.Visible = false
            end
        end)
    end

    -- Add to Offer visual shift
    if btn:GetAttribute("IsAddAction") then
        btn.Activated:Connect(function()
            if #selectedItems > 0 and YoursScroll then
                for _, item in ipairs(selectedItems) do
                    local clone = item:Clone()
                    local cloneStroke = clone:FindFirstChild("MainFrame") and clone:FindFirstChild("MainFrame"):FindFirstChild("SelectorStroke") or clone:FindFirstChildOfClass("Frame"):FindFirstChild("SelectorStroke")
                    if cloneStroke then
                        cloneStroke.Color = Color3.new(0,0,0)
                        cloneStroke.Thickness = 2
                    end
                    -- Strip interactions on the clone inside "Your Offer" for visual purity
                    clone:SetAttribute("InteractiveBtn", false)
                    clone:SetAttribute("IsInvItem", false)
                    clone.Parent = YoursScroll
                    
                    -- Hide from inventory instead of destroying, to allow taking back if needed (complex)
                    item.Visible = false 
                end
                selectedItems = {}
                AddToOfferBtn.Visible = false
            end
        end)
    end

    -- Trade Flow (Confirm -> Wait -> Accept)
    if btn:GetAttribute("IsTradeAction") then
        local txt = main:FindFirstChild("BtnText")
        local grad = main:FindFirstChild("BtnGradient")
        local stroke = main:FindFirstChild("BtnStroke")

        btn.Activated:Connect(function()
            if TradeState == "Ready" then
                -- Transition to Waiting
                TradeState = "Waiting"
                txt.Text = "Waiting..."
                grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, COLORS.WaitTop), ColorSequenceKeypoint.new(1, COLORS.WaitBot)}
                stroke.Color = COLORS.WaitShadow
                btn.BackgroundColor3 = COLORS.WaitShadow

                -- Wait 3 seconds
                task.spawn(function()
                    task.wait(3)
                    if TradeState == "Waiting" then
                        -- Transition to Accept
                        TradeState = "Accept"
                        txt.Text = "Accept"
                        
                        -- Pop effect
                        if scaleObj then
                            scaleObj.Scale = 1.3
                            TweenService:Create(scaleObj, TweenInfo.new(0.4, Enum.EasingStyle.Bounce), {Scale = 1.05}):Play()
                        end

                        grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, COLORS.AcceptTop), ColorSequenceKeypoint.new(1, COLORS.AcceptBot)}
                        stroke.Color = COLORS.AcceptShadow
                        btn.BackgroundColor3 = COLORS.AcceptShadow
                    end
                end)
            elseif TradeState == "Accept" then
                -- Finalize trade (Reset for demo purposes)
                txt.Text = "Trade Completed!"
                task.wait(1.5)
                
                TradeState = "Ready"
                txt.Text = "Confirm Trade"
                grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, COLORS.ConfirmTop), ColorSequenceKeypoint.new(1, COLORS.ConfirmBot)}
                stroke.Color = COLORS.ConfirmShadow
                btn.BackgroundColor3 = COLORS.ConfirmShadow
            end
        end)
    end
end

for _, obj in pairs(Main:GetDescendants()) do
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        if obj:GetAttribute("InteractiveBtn") then
            bindButton(obj)
        end
    end
end

local sc = Main:FindFirstChildOfClass("UIScale")
if sc then
    sc.Scale = 0
    TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end
