local Types = {}

export type LoadingScreenGui = ScreenGui & {
	LoadingFrame: Frame & {
		Title: TextLabel,
		LoadingText: TextLabel,
		Percentage: TextLabel,
		SkipButton: TextButton,
		CanvasGroup: CanvasGroup & {
			LoadingBar: Frame & {
				LoadingMeter: Frame,
			},
		},
	},
}

return Types
