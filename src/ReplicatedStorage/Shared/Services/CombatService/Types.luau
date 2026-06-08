local Types = {}

type Config = {
	Combo: number,
	ComboResetTime: number,
	IsAttacking: boolean,
	IsBlocking: boolean,
	BlockMeter: number,
	IsStunned: boolean,
	ComboBreakTime: number,
	LastAttackTime: number,
}

export type CombatServiceClientType = {
	Config: Config,
	Init: () -> (),
	BindEvents: () -> (),
	Attack: () -> (),
	Block: () -> (),
}

return Types
