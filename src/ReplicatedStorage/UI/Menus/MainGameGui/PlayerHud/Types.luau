local Types = {}

export type PlayerHudGui = ScreenGui & {
	Container: Frame & {
		PlayerStats: Frame & {
			Block: Frame & {
				BlockPercentage: TextLabel,
				BlockGroup: CanvasGroup & {
					BlockBar: Frame & {
						BlockMeter: Frame,
					},
				},
			},
			Health: Frame & {
				HealthPercentage: TextLabel,
				HealthGroup: CanvasGroup & {
					HealthBar: Frame & {
						HealthMeter: Frame,
					},
				},
			},
		},
	},
}

return Types
