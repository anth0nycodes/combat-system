--!strict
local PlayerStateServiceServer = {}

-- Game Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Packages
local DataService = require(RS.Packages.DataService).server

-- Remotes
local PlayerRemote = RS.Remotes.PlayerRemote :: RemoteEvent
local FighterSelectionRemote = RS.Remotes.FighterSelectionRemote :: RemoteEvent
local SettingsRemote = RS.Remotes.SettingsRemote :: RemoteEvent

local loadingCharacter: { [Player]: boolean } = {}

function PlayerStateServiceServer.Init()
	Players.PlayerAdded:Connect(function(player: Player)
		player:SetAttribute("IsInMainMenu", true)

		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if humanoidRootPart then
			humanoidRootPart.Anchored = true
		end

		player.CharacterAdded:Connect(function(newCharacter: Model)
			if not player:GetAttribute("IsInMainMenu") then
				return
			end

			local hrp = newCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
			if hrp then
				hrp.Anchored = true
			end
		end)
	end)

	PlayerRemote.OnServerEvent:Connect(function(player: Player, event: string)
		local character = player.Character or player.CharacterAdded:Wait()

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if not humanoidRootPart then
			return
		end

		if event == "StartGame" then
			humanoidRootPart.Anchored = false
			player:SetAttribute("IsInMainMenu", false)
		end
	end)

	SettingsRemote.OnServerEvent:Connect(function(player: Player, settingName: string, value: any)
		DataService:set(player, { "settings", settingName }, value)
	end)

	FighterSelectionRemote.OnServerEvent:Connect(function(player: Player, fighterName: string)
		if loadingCharacter[player] then
			return
		end
		if not RS.Shared.Fighters:FindFirstChild(fighterName) then
			warn("Invalid fighter name: " .. fighterName)
			return
		end
		loadingCharacter[player] = true
		DataService:set(player, { "selectedFighter" }, fighterName)
		player:LoadCharacterAsync()
		loadingCharacter[player] = nil
	end)
end

return PlayerStateServiceServer
