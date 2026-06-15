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

Config.FighterConfig = {
	Animations = {
		M1Animations = {
			{ Animation = SlayerAnimations.M1One, HitAt = { 0.15 }, CanCancelAt = 0.30 },
			{ Animation = SlayerAnimations.M1Two, HitAt = { 0.12 }, CanCancelAt = 0.27 },
			{
				Animation = SlayerAnimations.M1Three,
				HitAt = { 0.18 },
				CanCancelAt = 0.35,
				Lunge = { LungeAt = { 0.28 }, LungeForce = 18 },
			},
		},
		BlockAnimation = SlayerAnimations.Block,
		BlockBreakAnimation = SlayerAnimations.BlockBreak,
		ParryStunAnimation = SlayerAnimations.ParryStun,
		KnockbackAnimation = SlayerAnimations.Knockback,
	},
	Stuns = {
		BlockBreakDuration = 2,
		ParryDuration = 2,
	},
	WalkSpeed = { Base = 16, Attacking = 12, Blocking = 8, BlockBroken = 2 },
	SFX = { NormalAttack = NormalSliceSFX, HeavyAttack = HeavySliceSFX, BlockBreak = BlockBreakSFX },
	Damage = { Normal = 3, Heavy = 8 },
	MaxComboCount = 3,
	Hitbox = {
		HitboxType = "Box",
		Size = Vector3.new(8, 8, 8),
		CFrame = CFrame.new(0, 0, -2.5),
	} :: Types.BoxHitboxConfig,
}

return Config
