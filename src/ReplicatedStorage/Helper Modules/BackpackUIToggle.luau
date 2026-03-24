local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local StarterUI = game:GetService("StarterGui")

module.LockedStates = {
	["Carrying"] = false, -- steal
}

local Satchel = require(ReplicatedStorage:WaitForChild("Satchel"):WaitForChild("SatchelLoader")
		:WaitForChild("Satchel")
)

module.OpenNoBackpackUIs = 0

-- Create a BindableEvent
module.OpenBackpackUIsChanged = Instance.new("BindableEvent")

module.new = function()
	module.OpenNoBackpackUIs += 1
	--StarterUI:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	Satchel:SetBackpackEnabled(false)
	
	module.OpenBackpackUIsChanged:Fire(module.OpenNoBackpackUIs)
end

module.destroy = function()
	module.OpenNoBackpackUIs -= 1
	module.OpenNoBackpackUIs = math.max(module.OpenNoBackpackUIs, 0)
	
	if module.OpenNoBackpackUIs <= 0 then
		--StarterUI:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		
		local IsAnyLocked: boolean = false
		
		for name, bool in pairs(module.LockedStates) do
			if bool then
				IsAnyLocked = true
				break
			end
		end
		
		if not IsAnyLocked then
			Satchel:SetBackpackEnabled(true)
		end
	end
	
	module.OpenBackpackUIsChanged:Fire(module.OpenNoBackpackUIs)
end

module.UpdateLockedState = function(name: string, state: boolean)
	if module.LockedStates[name] == state then return end
	
	module.LockedStates[name] = state
	
	if not state then
		local IsAnyLocked: boolean = false

		for name, bool in pairs(module.LockedStates) do
			if bool then
				IsAnyLocked = true
				break
			end
		end

		if not IsAnyLocked then
			if module.OpenNoBackpackUIs <= 0 then
				Satchel:SetBackpackEnabled(true)
			end
		end
	else
		Satchel:SetBackpackEnabled(false)
	end
end

return module
