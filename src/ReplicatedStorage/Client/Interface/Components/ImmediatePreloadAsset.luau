local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentService = game:GetService("ContentProvider")

local ImmediatePreloadAsset = {}

-- Table to hold assets waiting to be preloaded
local pendingAssets = {}

-- Function called when a new asset is tagged
function ImmediatePreloadAsset.tagAdded(GuiAsset)
	-- Safely preload the batch
	local success, err = pcall(function()
		ContentService:PreloadAsync({GuiAsset})
	end)

	if not success then
		warn("[ImmediatePreloadAsset] Failed to preload asset:", err)
	else
		
	end
end

function ImmediatePreloadAsset.preloadAsset(GuiAsset)
	-- Safely preload the batch
	local success, err = pcall(function()
		ContentService:PreloadAsync({GuiAsset})
	end)

	if not success then
		warn("[ImmediatePreloadAsset] Failed to preload asset:", err)
	else

	end
end

return ImmediatePreloadAsset