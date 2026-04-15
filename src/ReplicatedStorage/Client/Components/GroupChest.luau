local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ClientData = require(ReplicatedStorage.Client.ClientData)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)
local Constants = require(ReplicatedStorage.Shared.Constants)
local SyncedTime = require(ReplicatedStorage.Shared.Modules.SyncedTime)

local GroupChestAsset = ReplicatedStorage.Assets.Chests.GroupChest

local interfaceTabUtil = require(ReplicatedStorage.Client.Interface.Utility.InterfaceTabUtil)

local visualMeshes = {} :: { [BasePart]: { VisualMesh: BasePart, Origin: CFrame } }
local trove = Trove.new()

local bobCycle = 0
local rotation = 0
local height = 0.3


local function getPartCFrame(part: BasePart, origin: CFrame)
    local partHeight = (height + height * math.sin(bobCycle)) / 2
    local offset = Vector3.new(0, partHeight, 0)

    local actualRotation = math.sin(rotation) * 0.15
    --return origin * CFrame.Angles(0, actualRotation, 0) * CFrame.Angles(0, math.rad(-90), 0) + offset
    return origin * CFrame.Angles(0, actualRotation, 0) + offset
end


local GroupChest = {}

function GroupChest.tagAdded(groupChest: BasePart)
	--groupChest.Transparency = 1
	
	local Plot = ClientData.Plot()
	if not Plot then
		repeat task.wait(0.1) Plot = ClientData.Plot() until Plot
	end
	
	local GroupChestPart = Plot:WaitForChild("Floor1")
		:WaitForChild("GroupChestPart")

	local function checkEligibility(new: number)
		--warn("VALUE CHANGED:", new)
		
		local HasClaimed = false

		if new then
			if new > 0 then
				-- Claimed
				
				HasClaimed = true
				
				--local Chest = workspace.Chests.GroupChestPart:FindFirstChild("GroupChest")
				local Chest = GroupChestPart:FindFirstChild("GroupChest")
				if Chest then
					Chest:Destroy()
				end

				trove:Destroy()
			end
		end
		
		if not HasClaimed then
			GroupChestAsset:PivotTo(GroupChestPart.CFrame)
			GroupChestAsset.Parent = GroupChestPart
			
			local LastTabClose = 0
			
			local function OpenGroupRewardTab(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)

				if player == Players.LocalPlayer then
					local HRP: BasePart? = hit.Parent:FindFirstChild("HumanoidRootPart")
					if not HRP then return end

					local dist: number = (HRP.Position - GroupChestAsset.Hitbox.Position).Magnitude
					if dist > GroupChestAsset.Hitbox.Size.X / 2 + 1.25 then
						return
					end
					
					if os.clock() - LastTabClose <= 1 then return end
					
					if not interfaceTabUtil.isTabOpen("GroupReward") then
						interfaceTabUtil.openTab("GroupReward")
						ReplicatedStorage.Assets.Sounds.Interface.ButtonClick:Play()
					end
				end
			end

			trove:Add(GroupChestAsset.Hitbox.Touched:Connect(OpenGroupRewardTab))
			
			trove:Add(task.spawn(function()
				while task.wait(0.5) do
					for _, hit in pairs(GroupChestAsset.Hitbox:GetTouchingParts()) do
						OpenGroupRewardTab(hit)
					end
				end
			end))
			
			trove:Add(interfaceTabUtil.OnTabClose:Connect(function()
				LastTabClose = os.clock()
			end))
		end
	end
	
	-- Listen to Value Changes
	
	trove:Add(
		Charm.subscribe(ClientData.GroupRewardClaimTime, checkEligibility)
	)

	checkEligibility(ClientData.GroupRewardClaimTime())

    local trove = Trove.new()
    trove:AttachToInstance(groupChest)


    local origin = groupChest.CFrame
	local visualMesh = groupChest
    visualMesh.CFrame = getPartCFrame(visualMesh, origin)
    trove:AttachToInstance(visualMesh)
    visualMeshes[groupChest] = { VisualMesh = visualMesh, Origin = origin }
end

function GroupChest.tagRemoved(groupChest: BasePart)
    visualMeshes[groupChest] = nil
end

local targetFPS = 10
local updateInterval = 1 / targetFPS  -- ≈ 0.0667 seconds per update
local timeSinceLastUpdate = 0

RunService.Heartbeat:Connect(function(deltaTime: number)
	timeSinceLastUpdate += deltaTime
	if timeSinceLastUpdate < updateInterval then
		return -- skip this frame
	end
	timeSinceLastUpdate -= updateInterval

	-- Update cycles using fixed interval for consistent speed
	bobCycle += updateInterval * 1.6
	bobCycle %= math.pi * 2

	rotation += updateInterval * 0.6
	rotation %= math.pi * 2

	local partList = {} :: { BasePart }
	local cframeList = {} :: { CFrame }
	for _, info in pairs(visualMeshes) do
		table.insert(partList, info.VisualMesh)
		table.insert(cframeList, getPartCFrame(info.VisualMesh, info.Origin))
	end

	workspace:BulkMoveTo(partList, cframeList)
end)

--RunService.Heartbeat:Connect(function(deltaTime: number)
--    bobCycle += deltaTime * 1.6
--    bobCycle %= math.pi * 2

--    rotation += deltaTime * 0.6
--    rotation %= math.pi * 2

--    local partList = {} :: { BasePart }
--    local cframeList = {} :: { CFrame }
--    for _, info in pairs(visualMeshes) do
--        table.insert(partList, info.VisualMesh)
--        table.insert(cframeList, getPartCFrame(info.VisualMesh, info.Origin))
--    end
--    workspace:BulkMoveTo(partList, cframeList)
--end)

return GroupChest