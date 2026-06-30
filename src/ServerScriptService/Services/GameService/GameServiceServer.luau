--!strict
local GameServiceServer = {}

-- Game Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Packages
local Networker = require(RS.Packages.Networker)
local Janitor = require(RS.Packages.Janitor)
local DataService = require(RS.Packages.DataService).server
local ConnectionHub = require(RS.Packages.ConnectionHub)

-- Constants
local GameServiceConstants = require(RS.Shared.Services.GameService.Constants)

-- Types
local FighterConfigTypes = require(RS.Shared.Fighters.Types)

local function getFighterConfig(fighterName: string): FighterConfigTypes.FighterConfigType
	local fighterModule = RS.Shared.Fighters:FindFirstChild(fighterName)
	if not fighterModule then
		return require(RS.Shared.Fighters.Brawler).FighterConfig
	end
	return (require(fighterModule) :: any).FighterConfig
end

local function giveWeapon(character: Model, weaponName: string)
	local arm = character:WaitForChild("Right Arm") :: BasePart
	if not arm then
		return
	end
	local weaponFolder = ServerStorage:FindFirstChild(`{weaponName}Group`)
	if not weaponFolder then
		warn(`giveWeapon: weapon "{weaponName}" not found in ServerStorage`)
		return
	end

	-- Clone parts from folder
	local handle: BasePart? = nil
	local weaponMesh: MeshPart? = nil
	local motor: Motor6D? = nil

	for _, child in weaponFolder:GetChildren() do
		local clone = child:Clone()
		if clone:IsA("BasePart") then
			clone.CanCollide = false
			clone.Parent = character
			if clone.Name == "Handle" then
				handle = clone
			else
				weaponMesh = clone
			end
		elseif clone:IsA("Motor6D") then
			motor = clone
		end
	end

	if not handle or not weaponMesh or not motor then
		warn(`giveWeapon: weapon "{weaponName}" is missing required parts`)
		return
	end

	local weaponMeshHandleWeld = weaponMesh:FindFirstChildOfClass("Weld")
	if weaponMeshHandleWeld then
		weaponMeshHandleWeld.Part0 = weaponMesh
		weaponMeshHandleWeld.Part1 = handle
	end

	motor.Part0 = arm
	motor.Part1 = handle
	motor.Parent = arm
end

local loadingCharacter: { [Player]: boolean } = {}
local fighterSelectionCooldowns: { [Player]: number } = {}
local playerJanitors: { [Player]: typeof(Janitor.new()) } = {}

local function setupPlayer(player: Player)
	local janitor = Janitor.new()
	playerJanitors[player] = janitor

	player:SetAttribute("IsInMainMenu", true)

	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if humanoidRootPart then
			humanoidRootPart.Anchored = true
		end
	end

	player.CharacterAdded:Connect(function(newCharacter: Model)
		DataService:waitForData(player)
		local selectedFighter = DataService:get(player, { "selectedFighter" })
		local fighterConfig = getFighterConfig(selectedFighter)
		if fighterConfig.WeaponName then
			giveWeapon(newCharacter, fighterConfig.WeaponName)
		end

		if not player:GetAttribute("IsInMainMenu") then
			return
		end

		local humanoidRootPart = newCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
		if humanoidRootPart then
			humanoidRootPart.Anchored = true
		end
	end)

	janitor:Add(function()
		loadingCharacter[player] = nil
		fighterSelectionCooldowns[player] = 0
	end, true)
end

local function cleanupPlayer(player: Player)
	local janitor = playerJanitors[player]
	if not janitor then
		return
	end
	janitor:Destroy()
	playerJanitors[player] = nil
end

function GameServiceServer.Init(self: GameServiceServer)
	self.Networker = Networker.server.new(
		"GameService",
		self,
		{ self.StartGame :: any, self.SetSettings :: any, self.SetFighterForPlayer :: any }
	)
	ConnectionHub.Subscribe(Players, "PlayerAdded", setupPlayer)
	for _, player in Players:GetPlayers() do
		if playerJanitors[player] then
			continue
		end
		setupPlayer(player)
	end
	ConnectionHub.Subscribe(Players, "PlayerRemoving", cleanupPlayer)
end

function GameServiceServer.StartGame(_self: GameServiceServer, player: Player)
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not humanoidRootPart then
		return
	end

	humanoidRootPart.Anchored = false
	player:SetAttribute("IsInMainMenu", false)
end

function GameServiceServer.SetSettings(_self: GameServiceServer, player: Player, settingName: string, value: boolean)
	DataService:set(player, { "settings", settingName }, value)
end

function GameServiceServer.SetFighterForPlayer(self: GameServiceServer, player: Player, fighterName: string)
	local character = player.Character
	if not character then
		return
	end

	local currentSelectedFighter = DataService:get(player, { "selectedFighter" })
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if humanoid.Health <= 0 then
		self.Networker:fire(
			player,
			"ShowNotification",
			"You cannot switch fighters while dead!",
			"Please respawn before switching.",
			GameServiceConstants.FIGHTER_SELECTION_NOTIFICATION_DURATION
		)
		return
	end

	if fighterName == currentSelectedFighter then
		self.Networker:fire(
			player,
			"ShowNotification",
			"You're already using this fighter!",
			"Please select a different fighter.",
			GameServiceConstants.FIGHTER_SELECTION_NOTIFICATION_DURATION
		)
		return
	end

	local cooldown = fighterSelectionCooldowns[player] or 0
	if cooldown > 0 then
		self.Networker:fire(
			player,
			"ShowNotification",
			"You're switching too quickly!",
			`Wait {cooldown} seconds before retrying.`,
			GameServiceConstants.FIGHTER_SELECTION_NOTIFICATION_DURATION
		)
		return
	end

	fighterSelectionCooldowns[player] = GameServiceConstants.FIGHTER_SELECTION_COOLDOWN
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
end

type GameServiceServer = typeof(GameServiceServer) & {
	Networker: Networker.Server,
}

return GameServiceServer :: GameServiceServer
