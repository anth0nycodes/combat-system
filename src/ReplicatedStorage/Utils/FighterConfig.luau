--!strict
local FighterConfig = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")

-- Packages
local DataService = require(RS.Packages.DataService).client

-- Types
local FighterConfigTypes = require(RS.Shared.Fighters.Types)

function FighterConfig.get(fighterName: string?)
	local Fighters = RS.Shared.Fighters
	local name = fighterName or DataService:get("selectedFighter") or "Brawler" -- Defaults to Brawler
	local fighter = Fighters:FindFirstChild(name)
	if not fighter then
		warn(`FighterConfig.get: {name} fighter not found. Defaulting to Brawler.`)
		fighter = Fighters.Brawler -- Defaults to Brawler again for extra safety
	end
	local fighterConfigModule = require(fighter) :: any
	local fighterConfig = fighterConfigModule.FighterConfig :: FighterConfigTypes.FighterConfigType
	return fighterConfig
end

return FighterConfig
