--!strict
local GameServiceClient = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- SFX
local notificationSound = RS.Assets.SFX.Notification

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Packages
local Networker = require(RS.Packages.Networker)

function GameServiceClient.Init(self: GameServiceClient)
	self.Networker = Networker.client.new("GameService", self)
	SG:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
end

function GameServiceClient.StartGame(self: GameServiceClient)
	self.Networker:fire("StartGame")
end

function GameServiceClient.SetSettings(self: GameServiceClient, settingName: string, value: boolean)
	self.Networker:fire("SetSettings", settingName, value)
end

function GameServiceClient.SetFighterForPlayer(self: GameServiceClient, fighterName: string)
	self.Networker:fire("SetFighterForPlayer", fighterName)
end

function GameServiceClient.ShowNotification(_self: GameServiceClient, title: string, message: string, duration: number)
	SG:SetCore("SendNotification", {
		Title = title,
		Text = message,
		Duration = duration,
	})
	notificationSound:Play()
end

type GameServiceClient = typeof(GameServiceClient) & {
	Networker: Networker.Client,
}

return GameServiceClient
