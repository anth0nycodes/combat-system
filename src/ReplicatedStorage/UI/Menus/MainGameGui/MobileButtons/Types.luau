local Types = {}

export type MobileButtonsGui = ScreenGui & {
	MobileButtonsContainer: Frame & {
		Punch: TextButton,
		Block: TextButton,
	},
}

return Types
