--!strict

-- Game Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local DataService = require(RS.Packages.DataService).server
local ConnectionHub = require(RS.Packages.ConnectionHub)

local services = script.Parent.Services

DataService:init({
	template = {
		selectedFighter = "Brawler",
		totalKills = 0,
		settings = {
			isHitboxChecked = false,
		},
	},
})

local function onPlayerAdded(player: Player)
	DataService:waitForData(player)
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local kills = Instance.new("IntValue", leaderstats)
	kills.Name = "Kills"
	kills.Value = 0

	local totalKills = Instance.new("IntValue", leaderstats)
	totalKills.Name = "Total Kills"
	totalKills.Value = DataService:get(player, { "totalKills" })
end

ConnectionHub.Subscribe(Players, "PlayerAdded", onPlayerAdded)

for _, service in services:GetChildren() do
	local serviceName = service.Name
	local serverModuleScript = service:FindFirstChild(`{serviceName}Server`) :: ModuleScript
	if serverModuleScript then
		local success, result = pcall(function()
			local module = require(serverModuleScript) :: any
			module:Init()
		end)

		if not success then
			warn(`Error initializing {serverModuleScript}: {result}`)
			return
		end

		print(`Initialized {serverModuleScript} successfully!`)
	end
end
