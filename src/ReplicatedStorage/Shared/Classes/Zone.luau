local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local isPointInBox = require(ReplicatedStorage.Shared.Utility.Math.isPointInBox)
local isPointInCylinder = require(ReplicatedStorage.Shared.Utility.Math.isPointInCylinder)

local localPlayer = Players.LocalPlayer


local Zone = {}

local zones = {} :: {[Part]: {
    PlayerInZone: boolean,
    Position: Vector3,
    Size: Vector3,
    ShapeFunction: (point: Vector3, partPos: Vector3, partSize: Vector3) -> (boolean),

    Entered: () -> ()?,
    Exited: () -> ()?,
}}

local shapeFunctions = {
    [Enum.PartType.Block] = isPointInBox,
    [Enum.PartType.Cylinder] = isPointInCylinder,
}


export type ZoneProperties = {
    Entered: () -> ()?, 
    Exited: () -> ()?,
}

function Zone.addZone(part: Part, zoneProperties: ZoneProperties)
    if zoneProperties.Entered == nil and zoneProperties.Exited == nil then
        warn(`[Zone] There aren't any listeners for entered or exited for part: {part.Name}!`)
        return
    end

    local shapeFunction = shapeFunctions[part.Shape]
    if shapeFunction == nil then
        warn("No shape function for the shape: " .. part.Shape.Name)
        return
    end

    zones[part] = {
        PlayerInZone = false,
        Position = part.CFrame.Position,
        Size = part.ExtentsSize,
        ShapeFunction = shapeFunction,

        Entered = zoneProperties.Entered,
        Exited = zoneProperties.Exited,
    }
end

function Zone.playerIsInZone(part: Part) : boolean
    local zone = zones[part]
    if zone == nil then
        warn(`[Zone] No zone found for part: {part}`)
        return false
    end

    return zone.PlayerInZone
end

function Zone.removeZone(part: Part)
    local zoneData = zones[part]
    if zoneData == nil then
        return
    end
    
    local exited = zoneData.Exited
    if exited then
        exited()
    end

    zones[part] = nil
end


local humanoidRootPart = nil :: BasePart?
local function characterAdded()
    local character = localPlayer.Character
    if not character then
        return
    end
    humanoidRootPart = character:WaitForChild("HumanoidRootPart", 120) :: BasePart?
end
task.spawn(characterAdded)
localPlayer.CharacterAdded:Connect(characterAdded)


RunService.Heartbeat:Connect(function()
    if humanoidRootPart == nil then
        return
    end

    local rootPos = humanoidRootPart.CFrame.Position
    for _, zoneData in pairs(zones) do
        local isInZone = zoneData.ShapeFunction(rootPos, zoneData.Position, zoneData.Size)

        -- State has changed
        if zoneData.PlayerInZone ~= isInZone then
            local entered, exited = zoneData.Entered, zoneData.Exited
            if isInZone and entered then
                entered()
            elseif not isInZone and exited then
                exited()
            end
        end

        zoneData.PlayerInZone = isInZone
    end
end)

return Zone