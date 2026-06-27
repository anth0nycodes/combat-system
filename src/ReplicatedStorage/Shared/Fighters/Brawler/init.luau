--!strict
-- Types
local FighterTypes = require(script.Parent.Types)
local Config = {} :: FighterTypes.ConfigType

-- Game Services
local RS = game:GetService("ReplicatedStorage")

-- Brawler Animations
local BrawlerAnimations = RS.Assets.Animations.Brawler

-- Brawler SFX
local NormalStrikeSFX = RS.Assets.SFX.Fighters.Brawler.Normal
local HeavyStrikeSFX = RS.Assets.SFX.Fighters.Brawler.Heavy
local ImpactSFX = RS.Assets.SFX.Fighters.Brawler.Impact
local BlockDrainSFX = RS.Assets.SFX.Fighters.Brawler.BlockDrain
local BlockBreakSFX = RS.Assets.SFX.Fighters.Brawler.BlockBreak
local ParrySFX = RS.Assets.SFX.Fighters.Brawler.Parry

Config.FighterConfig = {
	Animations = {
		M1Animations = {
			{ Animation = BrawlerAnimations.M1One },
			{ Animation = BrawlerAnimations.M1Two },
			{
				Animation = BrawlerAnimations.M1Three,
				Lunge = { LungeForce = 18, LungeDuration = 0.2 },
			},
		},
		MovementAnimations = { Idle = BrawlerAnimations.Idle },
		BlockAnimation = BrawlerAnimations.Block,
		BlockBreakAnimation = BrawlerAnimations.BlockBreak,
		ParryStunAnimation = BrawlerAnimations.ParryStun,
		KnockbackAnimation = BrawlerAnimations.Knockback,
	},
	Stuns = {
		BlockBreakDuration = 2,
		ParryDuration = 1,
	},
	WalkSpeed = { Base = 16, Attacking = 12, Blocking = 8, Parried = 2, BlockBroken = 1.5 },
	SFX = {
		NormalAttack = NormalStrikeSFX,
		HeavyAttack = HeavyStrikeSFX,
		Impact = ImpactSFX,
		BlockDrain = BlockDrainSFX,
		BlockBreak = BlockBreakSFX,
		Parry = ParrySFX,
	},
	Damage = { Normal = 3, Heavy = 8 },
	MaxComboCount = 3,
	Hitbox = {
		HitboxType = "Box",
		Size = Vector3.new(5, 5, 3),
		CFrame = CFrame.new(0, 0, -2.5),
	} :: FighterTypes.BoxHitboxConfig,
}

return Config
