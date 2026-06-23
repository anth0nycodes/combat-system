--!strict
local HitboxServerModule = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")

-- Packages
local DataService = require(RS.Packages.DataService).server

-- Modules
local FighterConfigModule = require(RS.Utils.FighterConfig)

function HitboxServerModule.CreateHitbox(player: Player)
	local fighterName = DataService:get(player, { "selectedFighter" }) :: string
	local fighterConfig = FighterConfigModule.get(fighterName)
	local character = player.Character or player.CharacterAdded:Wait()
	local hitHumanoids: { Humanoid } = {}

	if fighterConfig.Hitbox.HitboxType == "Box" then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if not humanoidRootPart then
			return hitHumanoids
		end

		local hitboxSize = fighterConfig.Hitbox.Size
		local hitboxCFrame = humanoidRootPart.CFrame * fighterConfig.Hitbox.CFrame

		local overlapParams = OverlapParams.new()
		overlapParams.ExcludeInstances = { character }

		local hitboxParts = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams)

		for _, part in hitboxParts do
			local model = part:FindFirstAncestorOfClass("Model")
			if not model then
				continue
			end

			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				continue
			end

			-- Prevent multiple hits on the same humanoid in one attack
			if table.find(hitHumanoids, humanoid) then
				continue
			end

			table.insert(hitHumanoids, humanoid)
		end
	end

	-- TODO: Implement weapon and projectile hitbox types
	if fighterConfig.Hitbox.HitboxType == "Weapon" then
		print("Weapon hitbox type is not yet implemented.")
	end

	if fighterConfig.Hitbox.HitboxType == "Projectile" then
		print("Projectile hitbox type is not yet implemented.")
	end

	return hitHumanoids
end

return HitboxServerModule
