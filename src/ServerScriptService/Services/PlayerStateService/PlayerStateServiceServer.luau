--!strict
local PlayerStateServiceServer = {}

-- Game Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Remotes
local PlayerRemote = RS.Remotes.PlayerRemote :: RemoteEvent

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
end

return PlayerStateServiceServer
