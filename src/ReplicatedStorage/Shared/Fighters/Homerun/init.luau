--!strict
-- Types
local FighterTypes = require(script.Parent.Types)
local Config = {} :: FighterTypes.ConfigType

-- Game Services
local RS = game:GetService("ReplicatedStorage")

-- Homerun Animations
local HomerunAnimations = RS.Assets.Animations.Homerun

-- Homerun SFX
local NormalStrikeSFX = RS.Assets.SFX.Fighters.Homerun.Normal
local HeavyStrikeSFX = RS.Assets.SFX.Fighters.Homerun.Heavy
local ImpactSFX = RS.Assets.SFX.Fighters.Homerun.Impact
local BlockDrainSFX = RS.Assets.SFX.Fighters.Homerun.BlockDrain
local BlockBreakSFX = RS.Assets.SFX.Fighters.Homerun.BlockBreak
local ParrySFX = RS.Assets.SFX.Fighters.Homerun.Parry

Config.FighterConfig = {
	Animations = {
		M1Animations = {
			{ Animation = HomerunAnimations.M1One },
			{ Animation = HomerunAnimations.M1Two },
			{
				Animation = HomerunAnimations.M1Three,
			},
		},
		MovementAnimations = { Idle = HomerunAnimations.Idle },
		BlockAnimation = HomerunAnimations.Block,
		BlockBreakAnimation = HomerunAnimations.BlockBreak,
		ParryStunAnimation = HomerunAnimations.ParryStun,
		KnockbackAnimation = HomerunAnimations.Knockback,
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
	WeaponName = "Bat",
}

return Config
