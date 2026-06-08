--!strict
local CombatServiceServer = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- Modules
local HitboxServerModule = require(SSS.Modules.Game.Hitbox)
local FighterConfigModule = require(RS.Utils.FighterConfig)

-- Fighter Config
local fighterConfig = FighterConfigModule.get()

-- Remotes
local AttackRemote = RS.Remotes.AttackRemote
local BlockRemote = RS.Remotes.BlockRemote

function CombatServiceServer.Init()
	AttackRemote.OnServerEvent:Connect(function(player: Player, combo: number)
		local DAMAGE = if combo == fighterConfig.MaxComboCount
			then fighterConfig.Damage.Heavy
			else fighterConfig.Damage.Normal
		local hitHumanoids = HitboxServerModule.CreateHitbox(player)

		-- TODO: Handle block meter and player damage reduction logic
		if not hitHumanoids then
			return
		end

		for _, humanoid in hitHumanoids do
			if humanoid.Health <= 0 then
				continue
			end
			humanoid:TakeDamage(DAMAGE)
		end
	end)

	BlockRemote.OnServerEvent:Connect(function(player: Player)
		local character = player.Character or player.CharacterAdded:Wait()
		-- character:SetAttribute("BlockMeter", newBlockValue)
	end)
end

return CombatServiceServer
