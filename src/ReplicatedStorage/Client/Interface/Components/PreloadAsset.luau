local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentService = game:GetService("ContentProvider")

local PreloadAsset = {}

-- Table to hold assets waiting to be preloaded
local pendingAssets = {}

-- Function called when a new asset is tagged
function PreloadAsset.tagAdded(GuiAsset: GuiObject)
	--warn("Added:", GuiAsset.Name)
	
	table.insert(pendingAssets, GuiAsset)
end

-- Background task that batches preloading every 2 seconds
task.spawn(function()
	while true do
		if #pendingAssets > 0 then
			local batch = table.clone(pendingAssets)
			table.clear(pendingAssets)

			-- Safely preload the batch
			local success, err = pcall(function()
				ContentService:PreloadAsync(batch)
			end)

			if not success then
				warn("[PreloadAsset] Failed to preload batch:", err)
			else
				--print("[PreloadAsset] Preloaded batch of", #batch, "assets.")
			end
		end

		task.wait(2)
	end
end)

return PreloadAsset