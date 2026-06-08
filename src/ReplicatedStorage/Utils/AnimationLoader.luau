--!strict
local AnimationLoader = {}

-- Game Services
local Players = game:GetService("Players")

-- Player
local player = Players.LocalPlayer
assert(player, "AnimationLoader.LoadAnimation can only be called from a Client script!")
local character: Model
local humanoid: Humanoid

local function onCharacterAdded(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
end

function AnimationLoader.Init()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

function AnimationLoader.LoadAnimation(animation: Animation): AnimationTrack
	local animator = humanoid:WaitForChild("Animator") :: Animator
	local animationTrack = animator:LoadAnimation(animation)
	return animationTrack
end

type AnimationLoader = typeof(AnimationLoader)

return AnimationLoader :: AnimationLoader
