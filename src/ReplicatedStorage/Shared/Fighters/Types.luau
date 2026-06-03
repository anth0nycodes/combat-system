local Types = {}

type FighterConfigType = {
	Animations: { Animation },
	SFX: {
		Normal: Sound,
		Heavy: Sound,
	},
	Damage: {
		Normal: number,
		Heavy: number,
	},
	MaxComboCount: number,
	HitboxType: "Box" | "Weapon" | "Projectile",
}

export type ConfigType = {
	FighterConfig: FighterConfigType,
}

return Types
