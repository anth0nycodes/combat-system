local Types = {}

type Config = {
	Combo: number,
	ComboResetTime: number,
	IsAttacking: boolean,
	ComboBreakTime: number,
	LastAttackTime: number,
	CurrentAnimationTrack: AnimationTrack?,
	CurrentCanCancelAt: number,
	AttackId: number,
}

export type CombatServiceClientType = {
	Config: Config,
	Init: () -> (),
	BindEvents: () -> (),
	Attack: () -> (),
	Block: () -> (),
}

return Types
