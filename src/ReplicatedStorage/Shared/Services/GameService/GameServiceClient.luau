--!strict
local GameServiceClient = {}

-- Game Services
local Players = game:GetService("Players")
local SG = game:GetService("StarterGui")

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

function GameServiceClient.Init()
	SG:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
end

return GameServiceClient
