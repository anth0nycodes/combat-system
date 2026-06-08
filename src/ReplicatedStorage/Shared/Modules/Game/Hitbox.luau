--!strict
local HitboxClientModule = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

-- Modules
local SettingsModule = require(RS.UI.Menus.MainGameGui.Settings)
local FighterConfigModule = require(RS.Utils.FighterConfig)

-- Fighter Config
local fighterConfig = FighterConfigModule.get()

function HitboxClientModule.CreateHitbox()
	if fighterConfig.Hitbox.HitboxType == "Box" then
		local hitboxCFrame = humanoidRootPart.CFrame * fighterConfig.Hitbox.CFrame
		local hitboxSize = fighterConfig.Hitbox.Size
		if SettingsModule.Config.isHitboxChecked then
			local hitbox = Instance.new("Part")
			hitbox.Size = hitboxSize
			hitbox.Color = Color3.new(1, 0, 0)
			hitbox.Transparency = 0.8
			hitbox.Anchored = true
			hitbox.CanCollide = false
			hitbox.CFrame = hitboxCFrame
			hitbox.Parent = workspace

			task.delay(0.35, function()
				hitbox:Destroy()
			end)
		end
	end
end

return HitboxClientModule
