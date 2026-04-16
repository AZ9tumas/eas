-- ============================================================
-- Conveyor Belt System  |  Server-only
-- ============================================================
-- Direction for each belt is derived from its Start → End parts.
-- Players are nudged each Heartbeat (X/Z only), so they can still
-- freely walk off the belt in any direction.
-- ============================================================

-- ╔══════════════════════════════════════════════════════════╗
-- ║                     CONFIGURATION                        ║
-- ╚══════════════════════════════════════════════════════════╝
local CONFIG = {
	-- Default belt speed in studs per second (applies to every conveyor
	-- unless overridden below).
	DefaultSpeed = 35,

	-- Per-conveyor speed overrides.
	-- Keys must match the exact Model names inside Workspace.Conveyors.
	-- Remove the comment dashes to enable an override.
	SpeedOverrides = {
		-- ConveyorBack  = 30,
		-- ConveyorFront = 15,
	},

	-- Maximum XZ force applied by the LinearVelocity (studs/s²-equivalent).
	-- Y is always 0 so gravity and jumping are unaffected.
	-- Higher = harder to resist / walk against the belt.
	MaxForce = 2e5,
}
-- ============================================================

local Players = game:GetService("Players")

-- LinearVelocity template stored directly under this script in Studio.
-- It is cloned per-character and configured at runtime.
local lvTemplate: LinearVelocity = script:FindFirstChildWhichIsA("LinearVelocity") :: LinearVelocity
if not lvTemplate then
	warn("[Conveyors] LinearVelocity template not found under script — aborting.")
	return
end

local conveyorsFolder = workspace:WaitForChild("Conveyors", 10)
if not conveyorsFolder then
	warn("[Conveyors] workspace.Conveyors not found — aborting.")
	return
end

-- ──────────────────────────────────────────────────────────
-- Helper: extract the character + HumanoidRootPart from a
-- part that fired a Touched / TouchEnded event.
-- ──────────────────────────────────────────────────────────
local function getCharFromHit(hit: BasePart): (Model?, BasePart?)
	local char = hit.Parent
	if not char or not char:IsA("Model") then return nil, nil end
	local humanoid: Humanoid? = char:FindFirstChildWhichIsA("Humanoid")
	local hrp: BasePart?      = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and hrp and humanoid.Health > 0 then
		return char, hrp
	end
	return nil, nil
end

-- ──────────────────────────────────────────────────────────
-- Build a data table for every conveyor model found in the
-- Workspace.Conveyors folder.
-- ──────────────────────────────────────────────────────────
type ConveyorData = {
	name      : string,
	part      : BasePart,
	direction : Vector3,   -- flat (Y=0), normalised
	speed     : number,    -- studs / second
	visual    : BasePart?, -- optional visual part
}

local conveyors: { ConveyorData } = {}

for _, model in ipairs(conveyorsFolder:GetChildren()) do
	if not model:IsA("Model") then continue end

	local under     : BasePart? = model:FindFirstChild("ConveyorUnder") :: BasePart?
    local visual    : BasePart? = model:FindFirstChild("ConveyorVisual") :: BasePart?
	local startPart : BasePart? = model:FindFirstChild("Start")         :: BasePart?
	local endPart   : BasePart? = model:FindFirstChild("End")           :: BasePart?

	if not (under and startPart and endPart) then
		warn(string.format(
			"[Conveyors] '%s' is missing Start, End, or ConveyorUnder — skipping.",
			model.Name
		))
		continue
	end

	-- Derive direction from Start → End, flattened to the XZ plane.
	local rawDir  = endPart.Position - startPart.Position
	local flatDir = Vector3.new(rawDir.X, 0, rawDir.Z).Unit

	local speed: number = CONFIG.SpeedOverrides[model.Name] or CONFIG.DefaultSpeed

	table.insert(conveyors, {
		name      = model.Name,
		part      = under,
        visual    = visual,
		direction = flatDir,
		speed     = speed,
	} :: ConveyorData)
end

-- ──────────────────────────────────────────────────────────
-- Touch tracking + LinearVelocity management
-- On first contact a LinearVelocity is cloned from the script
-- template and parented into HumanoidRootPart.
--   • Attachment0  = first Attachment found in HRP (e.g. RootAttachment
--                    on R15), or a fresh one is created if absent.
--   • VelocityConstraintMode = Vector  (full 3-D target velocity)
--   • ForceLimitMode = PerAxis         (MaxAxesForce.Y = 0 so gravity
--                                       and jumping are never overridden)
--   • RelativeTo = World               (XZ in world space)
-- On full leave the clone (and any attachment we created) is destroyed.
-- ──────────────────────────────────────────────────────────
for _, data in ipairs(conveyors) do
	local part    = data.part
	local visual  = data.visual
	local beltVec = Vector3.new(data.direction.X * data.speed, 0, data.direction.Z * data.speed)

	type MoverState = { lv: LinearVelocity, ownedAttachment: boolean }
	local touchCount: { [Model]: number }     = {}
	local movers:     { [Model]: MoverState } = {}

	local function applyMover(char: Model)
		if movers[char] then return end
		local hrp: BasePart? = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		-- Reuse an existing attachment in HRP (R15 has RootAttachment),
		-- or create a temporary one at the centre if none exists.
		local att: Attachment? = hrp:FindFirstChildWhichIsA("Attachment") :: Attachment?
		local owned = false
		if not att then
			att = Instance.new("Attachment")
			att.Position = Vector3.zero
			att.Parent   = hrp
			owned        = true
		end

		local lv: LinearVelocity    = lvTemplate:Clone() :: LinearVelocity
		lv.Name                      = "ConveyorMover"
		lv.VelocityConstraintMode    = Enum.VelocityConstraintMode.Vector
		lv.RelativeTo                = Enum.ActuatorRelativeTo.World
		lv.ForceLimitMode            = Enum.ForceLimitMode.PerAxis
		-- Y = 0 ensures gravity / jumping are untouched.
		lv.MaxAxesForce              = Vector3.new(0, 0, CONFIG.MaxForce)
		lv.VectorVelocity            = beltVec
		lv.Attachment0               = att
		lv.Enabled                   = true
		lv.Parent                    = hrp

		movers[char] = { lv = lv, ownedAttachment = owned }
		if owned then
			-- Store so we can clean it up; attach to the lv so it follows it.
			(att :: Attachment).Parent = hrp
			-- tag the attachment so we can destroy it with the lv
			local tag      = Instance.new("ObjectValue")
			tag.Name       = "_OwnedAtt"
			tag.Value      = att
			tag.Parent     = lv
		end
	end

	local function removeMover(char: Model)
		local state = movers[char]
		if state then
			-- Destroy attachment we created, if any.
			local tag: ObjectValue? = state.lv:FindFirstChild("_OwnedAtt") :: ObjectValue?
			if tag and tag.Value then tag.Value:Destroy() end
			state.lv:Destroy()
			movers[char] = nil
		end
		touchCount[char] = nil
	end

	local function enter(hit: BasePart)
		local char = getCharFromHit(hit)
		if not char then return end
		local count = (touchCount[char] or 0) + 1
		touchCount[char] = count
		if count == 1 then applyMover(char) end
	end

	local function leave(hit: BasePart)
		local char = getCharFromHit(hit)
		if not char then return end
		local count = (touchCount[char] or 1) - 1
		if count <= 0 then
			removeMover(char)
		else
			touchCount[char] = count
		end
	end

	part.Touched:Connect(enter)
	part.TouchEnded:Connect(leave)

	if visual then
		visual.Touched:Connect(enter)
		visual.TouchEnded:Connect(leave)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local char = player.Character
		if char then removeMover(char) end
	end)
end
