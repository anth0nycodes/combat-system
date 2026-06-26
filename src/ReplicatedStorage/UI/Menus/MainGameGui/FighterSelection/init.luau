--!strict
local FighterSelectionModule = {}

-- Game Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Types
local FighterSelectionTypes = require(script.Types)

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local playerGui = player.PlayerGui

-- Services
local GameServiceClient = require(RS.Shared.Services.GameService.GameServiceClient)

-- Inputs
local toggleFighterListAction = RS.Inputs.GUIs.MainGame.FighterSelectionButton

-- GUIs
local fighterSelectionGuiTemplate = RS.Assets.GUIs.FighterSelectionGui :: FighterSelectionTypes.FighterSelectionGui
local fighterSelectionGui = fighterSelectionGuiTemplate:Clone()
local fighterSelectionButton = fighterSelectionGui.Container.FighterSelectionButton
local fighterList = fighterSelectionGui.Container.FighterList
local BrawlerButton = fighterList.Brawler
local SlayerButton = fighterList.Slayer
local fighterButtons = { Brawler = BrawlerButton, Slayer = SlayerButton }
local fighterSelectionInputActions = {
	Brawler = RS.Inputs.GUIs.MainGame.Fighters.Brawler,
	Slayer = RS.Inputs.GUIs.MainGame.Fighters.Slayer,
}

-- SFX
local buttonPress = RS.Assets.SFX.GuiButtonPress
local buttonRelease = RS.Assets.SFX.GuiButtonRelease

-- Module Config
local isFighterListOpen = false

function FighterSelectionModule.Init()
	toggleFighterListAction.TapAndClick.UIButton = fighterSelectionButton
	fighterSelectionGui.Parent = playerGui
	toggleFighterListAction.Pressed:Connect(FighterSelectionModule.ToggleFighters)
	toggleFighterListAction.Released:Connect(function()
		buttonRelease:Play()
		fighterList.Visible = isFighterListOpen
	end)

	for name, action in fighterSelectionInputActions do
		local fighterName = name :: string
		local fighterSelectionInputAction = action :: InputAction & { TapAndClick: InputBinding }
		fighterSelectionInputAction.TapAndClick.UIButton = fighterButtons[fighterName]
		fighterSelectionInputAction.Pressed:Connect(function()
			buttonPress:Play()
		end)
		fighterSelectionInputAction.Released:Connect(function()
			buttonRelease:Play()
			FighterSelectionModule.SelectFighter(fighterName)
		end)
	end
end

function FighterSelectionModule.ToggleFighters()
	buttonPress:Play()
	isFighterListOpen = not isFighterListOpen
end

function FighterSelectionModule.SelectFighter(fighterName: string)
	(GameServiceClient :: any):SetFighterForPlayer(fighterName)
end

return FighterSelectionModule
