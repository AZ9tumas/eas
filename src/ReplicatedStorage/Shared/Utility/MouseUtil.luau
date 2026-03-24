local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

local visualize = false


local MouseUtil = {}

function MouseUtil.getPositionInWorld(): Vector3
    local mouseLocation = UserInputService:GetMouseLocation()
    local unitRay = currentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.RespectCanCollide = false

    local filter = {}
    local tags = {"IgnoreMouse", "InvisibleBlock"}
    for _, tag in ipairs(tags) do
        for _, object in pairs(CollectionService:GetTagged(tag)) do
            table.insert(filter, object)
        end
    end
    local character = localPlayer.Character
    if character then
        table.insert(filter, character)
    end
    raycastParams.FilterDescendantsInstances = filter

    local origin = currentCamera.CFrame.Position
    local direction = unitRay.Direction * 500
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result and visualize then
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Position = result.Position
        part.Parent = workspace
    end
    return if result then result.Position else origin + direction
end

return MouseUtil