local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local buttons = script.Parent.Buttons

buttons.Store.MouseButton1Click:Connect(function()
	InterfaceTabUtil.openTab("Store")
end)

buttons.Index.MouseButton1Click:Connect(function()
	InterfaceTabUtil.openTab("Index")
end)

buttons.Rebirth.MouseButton1Click:Connect(function()
	InterfaceTabUtil.openTab("Rebirth")
end)