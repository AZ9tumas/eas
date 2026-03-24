local Ragdoll = {}

function Ragdoll.RagdollCharacter(Character, Timer: number)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local Torso = Character:FindFirstChild("Torso")
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	local Hum: Humanoid = Character:FindFirstChild("Humanoid")
	
	
	Player:SetAttribute("Ragdolled", true)
	
		for _, joint in pairs(Character:GetDescendants()) do
			if joint:IsA("Motor6D") then
				local Socket = Instance.new("BallSocketConstraint", joint.Parent)
				local Att0 = Instance.new("Attachment", joint.Part0)
				local Att1 = Instance.new("Attachment", joint.Part1)

				Att0.CFrame = joint.C0
				Att1.CFrame = joint.C1

				Socket.Attachment0 = Att0
				Socket.Attachment1 = Att1
				Socket.LimitsEnabled = true
				Socket.TwistLimitsEnabled = true

				joint.Enabled = false
			end
		end

		wait(Timer)
		for _, joint in pairs(Character:GetDescendants()) do
			if joint:IsA("Motor6D") then
				joint.Enabled = true
			elseif joint:IsA("BallSocketConstraint") then
				joint.Enabled = false
			end
		end
		Hum.EvaluateStateMachine = true
		Hum.AutoRotate = true
		if Player then
			if Character then
				Player:SetAttribute("Ragdolled", false)
			end
		end

end



return Ragdoll
