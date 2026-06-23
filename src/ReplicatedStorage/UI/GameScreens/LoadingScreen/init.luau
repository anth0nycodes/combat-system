--!strict
local LoadingScreen = {}

-- Game Services
local TS = game:GetService("TweenService")
local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local playerGui = player.PlayerGui

-- Types
local LoadingScreenTypes = require(script.Types)

local loadingScreenGuiTemplate = RS.Assets.GUIs.LoadingScreenGui :: LoadingScreenTypes.LoadingScreenGui
local loadingScreenGui = loadingScreenGuiTemplate:Clone()
local loadingFrame = loadingScreenGui.LoadingFrame
local loadingCanvasGroup = loadingFrame.CanvasGroup
local loadingTitle = loadingFrame.Title
local loadingText = loadingFrame.LoadingText
local skipButton = loadingFrame.SkipButton
local loadingPercentage = loadingFrame.Percentage
local loadingBar = loadingCanvasGroup.LoadingBar
local loadingMeter = loadingBar.LoadingMeter
local fadeOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- UIs
local MainMenu = require(RS.UI.Menus.MainMenu)

local function fadeOutAndDestroy()
	loadingText.Text = "Loading complete!"
	TS:Create(loadingMeter, TweenInfo.new(0.25), { Size = UDim2.fromScale(1, 1) }):Play()
	loadingPercentage.Text = "100%"
	task.wait(0.5)
	local tweens = {
		TS:Create(loadingFrame, fadeOutInfo, {
			BackgroundTransparency = 1,
		}),
		TS:Create(loadingTitle, fadeOutInfo, {
			TextTransparency = 1,
		}),
		TS:Create(loadingText, fadeOutInfo, {
			TextTransparency = 1,
		}),
		TS:Create(skipButton, fadeOutInfo, {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}),
		TS:Create(loadingPercentage, fadeOutInfo, {
			TextTransparency = 1,
		}),
		TS:Create(loadingCanvasGroup, fadeOutInfo, {
			GroupTransparency = 1,
		}),
	}

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	tweens[3].Completed:Wait()
	loadingScreenGui:Destroy()
end

function LoadingScreen.Init()
	local skipped = false
	task.delay(2, function()
		if loadingScreenGui.Parent then
			skipButton.Visible = true
		end
	end)

	skipButton.Activated:Connect(function()
		if skipped then
			return
		end
		skipped = true
		fadeOutAndDestroy()
	end)

	MainMenu.Init()
	loadingScreenGui.Parent = playerGui
	RF:RemoveDefaultLoadingScreen()

	local assets = RS.Assets:GetDescendants()
	local totalAssets = #assets

	for i, asset in ipairs(assets) do
		if skipped then
			break
		end
		loadingText.Text = `Loading... ({i}/{totalAssets})`
		ContentProvider:PreloadAsync({ asset })
		if skipped then
			return
		end
		local progress = i / totalAssets
		TS:Create(loadingMeter, TweenInfo.new(0.25), { Size = UDim2.fromScale(progress, 1) }):Play()
		loadingPercentage.Text = `{math.round(progress * 100)}%`
	end

	if skipped then
		return
	end

	fadeOutAndDestroy()
end

return LoadingScreen
