local Types = {}

type Config = {
	Combo: number,
	ComboResetTime: number,
	IsAttacking: boolean,
	NextAttackTime: number,
	LastAttackTime: number,
}

export type CombatServiceClientType = {
	Config: Config,
	Init: () -> (),
	BindEvents: () -> (),
	Attack: () -> (),
}

return Types
