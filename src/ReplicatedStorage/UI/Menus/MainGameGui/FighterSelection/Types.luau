local Types = {}

export type FighterSelectionGui = ScreenGui & {
	Container: Frame & {
		FighterList: Frame & {
			Brawler: TextButton,
			Homerun: TextButton,
			Slayer: TextButton,
		},
		FighterSelectionButton: TextButton,
	},
}

return Types
