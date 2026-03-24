local gui = script.Parent
local sidebar = gui.Container.Sidebar.TabContainer
local content = gui.Container.ContentArea
local closeBtn = content.CloseButton
local ActiveColor = Color3.fromRGB(255, 255, 255)
local InactiveColor = Color3.fromRGB(150, 155, 170)

local function switchTab(btnName)
	-- Reset Boutons
	for _, btn in pairs(sidebar:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.TextColor3 = InactiveColor
			btn.BackgroundTransparency = 1
			if btn:FindFirstChild("ActiveBar") then btn.ActiveBar.Visible = false end
		end
	end
	-- Reset Pages
	for _, page in pairs(content:GetChildren()) do
		if page:IsA("ScrollingFrame") then page.Visible = false end
	end
	
	-- Activer
	local selectedBtn = sidebar:FindFirstChild(btnName)
	if selectedBtn then
		selectedBtn.TextColor3 = ActiveColor
		selectedBtn.BackgroundTransparency = 0.95
		if selectedBtn:FindFirstChild("ActiveBar") then selectedBtn.ActiveBar.Visible = true end
		
		local pageName = string.gsub(btnName, "Tab_", "Page_")
		if content:FindFirstChild(pageName) then
			content[pageName].Visible = true
		end
	end
end

for _, btn in pairs(sidebar:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function() switchTab(btn.Name) end)
	end
end

-- Init on "All"
switchTab("Tab_All")