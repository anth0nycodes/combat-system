--!strict
local SettingsModule = {}

-- Game Services
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local DataService = require(RS.Packages.DataService).client

-- Remotes
local SettingsRemote = RS.Remotes.SettingsRemote :: RemoteEvent

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local playerGui = player.PlayerGui

-- Types
local SettingsTypes = require(script.Types)

-- GUI Template
local settingsGuiTemplate = RS.Assets.GUIs.SettingsGui :: SettingsTypes.SettingsGui

-- GUIs
local settingsGui = settingsGuiTemplate:Clone()
local settingsMenu = settingsGui.SettingsMenu
local settingsButton = settingsGui.SettingsButton
local settingsMenuScale = settingsMenu.UIScale
local settingsOptions = settingsMenu.Options
local showHitboxOption = settingsOptions.ShowHitbox
local hitboxOptionCheckbox = showHitboxOption.Checkbox

-- Inputs
local combatContext = RS.Inputs.Combat
local settingsButtonAction = RS.Inputs.GUIs.MainGame.SettingsButton

-- SFX
local buttonPress = RS.Assets.SFX.GuiButtonPress
local buttonRelease = RS.Assets.SFX.GuiButtonRelease

-- Module Config
local isSettingsOpen = false

function SettingsModule.Init()
	settingsButtonAction.TapAndClick.UIButton = settingsButton
	settingsGui.Parent = playerGui
	settingsButtonAction.Pressed:Connect(SettingsModule.ToggleVisibility)
	settingsButtonAction.Released:Connect(function()
		buttonRelease:Play()
		local scaleAmount = if isSettingsOpen then 1 else 0
		local toggleTween =
			TS:Create(settingsMenuScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Scale = scaleAmount })
		toggleTween:Play()
	end)
	SettingsModule.HandleOptionChecked()
end

function SettingsModule.ToggleVisibility()
	buttonPress:Play()
	isSettingsOpen = not isSettingsOpen

	if isSettingsOpen then
		combatContext.Enabled = false
	else
		combatContext.Enabled = true
	end
end

function SettingsModule.HandleOptionChecked()
	local isHitboxChecked = DataService:get({ "settings", "isHitboxChecked" })
	hitboxOptionCheckbox.Text = if isHitboxChecked then "✓" else ""
	hitboxOptionCheckbox.MouseButton1Down:Connect(function()
		buttonPress:Play()
	end)
	hitboxOptionCheckbox.MouseButton1Up:Connect(function()
		buttonRelease:Play()
		isHitboxChecked = not isHitboxChecked
		hitboxOptionCheckbox.Text = if isHitboxChecked then "✓" else ""
		SettingsRemote:FireServer("isHitboxChecked", isHitboxChecked)
	end)
end

return SettingsModule
