--!strict
local AnimationServiceClient = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")

-- Utils
local CharacterLoader = require(RS.Utils.CharacterLoader)
local FighterConfig = require(RS.Shared.Utils.FighterConfig)

function AnimationServiceClient.Init(self: AnimationServiceClient)
	CharacterLoader.Init(function(newCharacter: Model, newHumanoid: Humanoid)
		task.spawn(function()
			self:OverrideAnimations(newCharacter, newHumanoid)
		end)
	end)
end

function AnimationServiceClient.OverrideAnimations(_self: AnimationServiceClient, character: Model, humanoid: Humanoid)
	local fighterConfig = FighterConfig.get()
	local idleAnimationId = fighterConfig.Animations.MovementAnimations.Idle.AnimationId
	local animateScript = character:WaitForChild("Animate") :: LocalScript
	local idleConfig = animateScript:WaitForChild("idle")

	-- Wait for game to start (Animate is fully initialized by then)
	if player:GetAttribute("IsInMainMenu") then
		player:GetAttributeChangedSignal("IsInMainMenu"):Wait()
	end

	for _, child in idleConfig:GetChildren() do
		if child:IsA("Animation") then
			local newAnim = Instance.new("Animation")
			newAnim.Name = child.Name
			newAnim.AnimationId = idleAnimationId
			child:Destroy()
			newAnim.Parent = idleConfig
		end
	end

	humanoid.Died:Connect(function()
		if animateScript then
			animateScript.Enabled = false
		end

		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if animator then
			for _, track in animator:GetPlayingAnimationTracks() do
				track:Stop()
			end
		end
	end)
end

type AnimationServiceClient = typeof(AnimationServiceClient)

return AnimationServiceClient :: AnimationServiceClient
