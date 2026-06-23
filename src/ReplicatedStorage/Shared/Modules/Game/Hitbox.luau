--!strict
local HitboxClientModule = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")

-- Packages
local DataService = require(RS.Packages.DataService).client

-- Modules
local FighterConfigModule = require(RS.Utils.FighterConfig)

function HitboxClientModule.CreateHitbox(humanoidRootPart: BasePart)
	local fighterConfig = FighterConfigModule.get()
	local isHitboxChecked = DataService:get({ "settings", "isHitboxChecked" })

	if fighterConfig.Hitbox.HitboxType == "Box" then
		if isHitboxChecked then
			local hitboxCFrame = humanoidRootPart.CFrame * fighterConfig.Hitbox.CFrame
			local hitboxSize = fighterConfig.Hitbox.Size
			local hitbox = Instance.new("Part")
			hitbox.Size = hitboxSize
			hitbox.Color = Color3.new(1, 0, 0)
			hitbox.TopSurface = Enum.SurfaceType.Smooth
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
