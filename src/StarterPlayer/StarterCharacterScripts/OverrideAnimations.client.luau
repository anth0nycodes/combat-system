--!strict

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local FighterConfig = require(RS.Shared.Utils.FighterConfig)

local player = Players.LocalPlayer
local character = script.Parent :: Model
local fighterConfig = FighterConfig.get()
local idleAnimationId = fighterConfig.Animations.MovementAnimations.Idle.AnimationId

local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animate = character:WaitForChild("Animate")
local idleConfig = animate:WaitForChild("idle")

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
	animate:Destroy()
end)
