--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local emitParticlesAtCFrame = require(ReplicatedStorage.Shared.Utility.Particles.emitParticlesAtCFrame)
local observers = require(ReplicatedStorage.Shared.Utility.observers)
local ripple = require(ReplicatedStorage.Shared.Classes.ripple)
local Trove = require(ReplicatedStorage.Shared.Classes.Trove)

local assets = ReplicatedStorage.Assets
local effectsFolder = assets.Effects

local currentCamera = workspace.CurrentCamera :: Camera


local EFFECT_CULL_DISTANCE = 100


observers.observeTag("EggModel", function(eggModel: Model)
	local trove = Trove.new()

	local eggModelCFrame = eggModel:GetPivot()
	local originCFrame = eggModelCFrame

	local distanceFromCamera = (originCFrame.Position - currentCamera.CFrame.Position).Magnitude
	if distanceFromCamera < EFFECT_CULL_DISTANCE then
		emitParticlesAtCFrame(effectsFolder.SpawnEgg, eggModelCFrame + Vector3.new(0, 2.5, 0))
		
		local startOffset = Vector3.new(0, 2.5, 0)
		local goalOffset = Vector3.zero
		eggModel:PivotTo(originCFrame + startOffset)

		local motion = ripple.createMotion(startOffset)
		motion:onStep(function(value)
			eggModel:PivotTo(originCFrame + value)
		end)
		motion:spring(goalOffset, { frequency = 0.35, tension = 50, friction = 12, damping = 0.5 })
		trove:Add(motion.stop :: any)
	else
		--eggModel:PivotTo(originCFrame)
	end

	-- Cleanup
	return function()
		trove:Clean()
	end
end)

return {}