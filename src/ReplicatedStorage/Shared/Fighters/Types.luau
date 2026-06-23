local Types = {}

export type BoxHitboxConfig = {
	HitboxType: "Box",
	Size: Vector3,
	CFrame: CFrame,
}

export type WeaponHitboxConfig = {
	HitboxType: "Weapon",
	WeaponPart: BasePart,
}

export type ProjectileHitboxConfig = {
	HitboxType: "Projectile",
	Speed: number,
	Direction: Vector3,
}

type HitboxConfig = BoxHitboxConfig | WeaponHitboxConfig | ProjectileHitboxConfig

type M1AnimationData = {
	Animation: Animation,
	Lunge: { LungeForce: number, LungeDuration: number }?,
}

export type FighterConfigType = {
	Animations: {
		M1Animations: { M1AnimationData },
		BlockAnimation: Animation,
		BlockBreakAnimation: Animation,
		ParryStunAnimation: Animation,
		KnockbackAnimation: Animation,
	},
	Stuns: {
		BlockBreakDuration: number,
		ParryDuration: number,
	},
	WalkSpeed: { Base: number, Attacking: number, Blocking: number, Parried: number, BlockBroken: number },
	SFX: {
		NormalAttack: Sound,
		HeavyAttack: Sound,
		Impact: Sound,
		BlockDrain: Sound,
		BlockBreak: Sound,
		Parry: Sound,
	},
	Damage: {
		Normal: number,
		Heavy: number,
	},
	MaxComboCount: number,
	Hitbox: HitboxConfig,
}

export type ConfigType = {
	FighterConfig: FighterConfigType,
}

return Types
