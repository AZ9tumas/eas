local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)


local TabOpenButton = {}

function TabOpenButton.tagAdded(button: GuiButton)
	local tab = InterfaceTabUtil.findTab(button.Name)
	if tab == nil then
		warn("[Buttons] No screen gui found for:", button.Name)
		return
	end
	button.Activated:Connect(function()
		InterfaceTabUtil.openTab(tab)
	end)
end

return TabOpenButton