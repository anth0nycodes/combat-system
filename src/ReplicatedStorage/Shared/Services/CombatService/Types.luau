local Types = {}

type Config = {
	Combo: number,
	ComboResetTime: number,
	IsAttacking: boolean,
	ComboBreakTime: number,
	LastAttackTime: number,
	CurrentAnimationTrack: AnimationTrack?,
	CanCancel: boolean,
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
