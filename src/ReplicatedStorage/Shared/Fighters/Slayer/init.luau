--!strict

-- TODO: Swap out slayer animation assets for the actual slayer animations once they are done

-- Types
local Types = require(script.Parent.Types)
local Config = {} :: Types.ConfigType

-- Game Services
local RS = game:GetService("ReplicatedStorage")

-- Slayer Animations
local SlayerAnimations = RS.Assets.Animations.Slayer

-- Slayer SFX
local NormalSliceSFX = RS.Assets.SFX.Fighters.Slayer.Normal
local HeavySliceSFX = RS.Assets.SFX.Fighters.Slayer.Heavy
local BlockBreakSFX = RS.Assets.SFX.Fighters.Slayer.BlockBreak
local ParrySFX = RS.Assets.SFX.Fighters.Slayer.Parry

Config.FighterConfig = {
	Animations = {
		M1Animations = {
			{ Animation = SlayerAnimations.M1One },
			{ Animation = SlayerAnimations.M1Two },
			{
				Animation = SlayerAnimations.M1Three,
				Lunge = { LungeForce = 18, LungeDuration = 0.2 },
			},
		},
		BlockAnimation = SlayerAnimations.Block,
		BlockBreakAnimation = SlayerAnimations.BlockBreak,
		ParryStunAnimation = SlayerAnimations.ParryStun,
		KnockbackAnimation = SlayerAnimations.Knockback,
	},
	Stuns = {
		BlockBreakDuration = 2,
		ParryDuration = 1,
	},
	WalkSpeed = { Base = 16, Attacking = 12, Blocking = 8, Parried = 2, BlockBroken = 1.5 },
	SFX = { NormalAttack = NormalSliceSFX, HeavyAttack = HeavySliceSFX, BlockBreak = BlockBreakSFX, Parry = ParrySFX },
	Damage = { Normal = 3, Heavy = 8 },
	MaxComboCount = 3,
	Hitbox = {
		HitboxType = "Box",
		Size = Vector3.new(8, 8, 8),
		CFrame = CFrame.new(0, 0, -2.5),
	} :: Types.BoxHitboxConfig,
}

return Config
