--!strict
local PlayerStateServiceServer = {}

-- Game Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Packages
local Janitor = require(RS.Packages.Janitor)
local DataService = require(RS.Packages.DataService).server

-- Remotes
local PlayerRemote = RS.Remotes.PlayerRemote :: RemoteEvent
local FighterSelectionRemote = RS.Remotes.FighterSelectionRemote :: RemoteEvent
local SettingsRemote = RS.Remotes.SettingsRemote :: RemoteEvent
local NotificationRemote = RS.Remotes.NotificationRemote :: RemoteEvent

local loadingCharacter: { [Player]: boolean } = {}
local fighterSelectionCooldowns: { [Player]: number } = {}
local playerJanitors: { [Player]: typeof(Janitor.new()) } = {}

local function setupPlayer(player: Player)
	local janitor = Janitor.new()
	playerJanitors[player] = janitor

	player:SetAttribute("IsInMainMenu", true)

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if humanoidRootPart then
		humanoidRootPart.Anchored = true
	end

	janitor:Add(
		player.CharacterAdded:Connect(function(newCharacter: Model)
			if not player:GetAttribute("IsInMainMenu") then
				return
			end

			local hrp = newCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
			if hrp then
				hrp.Anchored = true
			end
		end),
		"Disconnect"
	)

	janitor:Add(function()
		loadingCharacter[player] = nil
		fighterSelectionCooldowns[player] = 0
	end, true)
end

function PlayerStateServiceServer.Init()
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		if playerJanitors[player] then
			continue
		end
		setupPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local janitor = playerJanitors[player]
		if not janitor then
			return
		end
		janitor:Destroy()
		playerJanitors[player] = nil
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
		local character = player.Character or player.CharacterAdded:Wait()
		local currentSelectedFighter = DataService:get(player, { "selectedFighter" })
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		if humanoid.Health <= 0 then
			NotificationRemote:FireClient(
				player,
				"You cannot switch fighters while dead!",
				"Please respawn before switching.",
				3
			)
			return
		end

		if fighterName == currentSelectedFighter then
			NotificationRemote:FireClient(
				player,
				"You're already using this fighter!",
				"Please select a different fighter.",
				3
			)
			return
		end

		local cooldown = fighterSelectionCooldowns[player] or 0
		if cooldown > 0 then
			NotificationRemote:FireClient(
				player,
				"You're switching too quickly!",
				`Wait {cooldown} seconds before retrying.`,
				3
			)
			return
		end

		fighterSelectionCooldowns[player] = 5
		task.spawn(function()
			while fighterSelectionCooldowns[player] > 0 do
				task.wait(1)
				fighterSelectionCooldowns[player] -= 1
			end
		end)

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
