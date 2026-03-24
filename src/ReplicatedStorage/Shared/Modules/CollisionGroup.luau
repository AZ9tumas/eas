local PhysicsService = game:GetService("PhysicsService")

local registerCache = {} :: {[string]: {string | boolean}}


local CollisionGroup = {}

function CollisionGroup.setGroupOfCharacter(character: Model, groupName: string)
    CollisionGroup.setGroupOfModel(character, groupName)

    -- Listen for new parts being added
    return character.ChildAdded:Connect(function(part)
        if not part:IsA("BasePart") then
            return
        end
        CollisionGroup.setGroup(part, groupName)
    end)
end

function CollisionGroup.setGroupOfModel(model: Model, groupName: string)
    for _, part in pairs(model:GetDescendants()) do
        if not part:IsA("BasePart") then 
            continue 
        end
        CollisionGroup.setGroup(part, groupName)
    end
end

function CollisionGroup.setGroup(part: BasePart, groupName: string)
    if not part:IsA("BasePart") then
        return
    end
    if not PhysicsService:IsCollisionGroupRegistered(groupName) then
        warn("Collision Group doesn't exist: " .. groupName)
        return
    end    
    
    part.CollisionGroup = groupName
end

function CollisionGroup.createGroup(groupName: string, collidable: boolean)
    collidable = collidable or false

    PhysicsService:RegisterCollisionGroup(groupName)
    CollisionGroup.setCollidable(groupName, groupName, collidable)
    CollisionGroup.updateCache(groupName)
end

function CollisionGroup.setCollidable(groupName1: string, groupName2: string, collidable: boolean)
    if not PhysicsService:IsCollisionGroupRegistered(groupName1) and PhysicsService:IsCollisionGroupRegistered(groupName2) then
        warn("None of these groups are registered: " .. groupName1 .. ", " .. groupName2)
        return
    end

    if not PhysicsService:IsCollisionGroupRegistered(groupName1) then
        registerCache[groupName1] = {groupName2, collidable}
        return
    elseif not PhysicsService:IsCollisionGroupRegistered(groupName2) then
        registerCache[groupName2] = {groupName1, collidable}
        return
    end

    PhysicsService:CollisionGroupSetCollidable(groupName1, groupName2, collidable)
end

-- In the case that groupName1 doesn't exist when setting collisions,
-- set the collision once the group has been created using .CreateGroup.
function CollisionGroup.updateCache(groupName1: string)
    local cache = registerCache[groupName1]
    if cache == nil then
        return
    end

    local groupName2, collidable = cache[1] :: string, cache[2] :: boolean

    CollisionGroup.setCollidable(groupName1, groupName2, collidable)
    registerCache[groupName1] = nil
end

return CollisionGroup