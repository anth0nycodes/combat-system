--!strict
local MobileButtonsModule = {}

-- Game Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Types
local MobileButtonsTypes = require(script.Types)

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local playerGui = player.PlayerGui

-- Utils
local UserDevice = require(RS.Utils.UserDevice)

-- Input Actions
local m1MobileBinding = RS.Inputs.Combat.M1.Mobile
local blockMobileBinding = RS.Inputs.Combat.Block.Mobile

-- GUIs
local mobileButtonsGuiTemplate = RS.Assets.GUIs.MobileButtonsGui :: MobileButtonsTypes.MobileButtonsGui
local mobileButtonsGui = mobileButtonsGuiTemplate:Clone()
local container = mobileButtonsGui.MobileButtonsContainer

local function updateVisibility(device: string)
	container.Visible = (device == "Mobile")
end

function MobileButtonsModule.Init()
	mobileButtonsGui.Parent = playerGui

	-- Point InputAction UIButton bindings to cloned button instances
	m1MobileBinding.UIButton = container.Punch
	blockMobileBinding.UIButton = container.Block

	updateVisibility(UserDevice.GetUserDevice())
	UserDevice.DeviceUpdated:Connect(updateVisibility)
end

return MobileButtonsModule
