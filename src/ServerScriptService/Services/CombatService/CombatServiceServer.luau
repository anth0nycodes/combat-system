--!strict
local CombatServiceServer = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

-- Modules
local HitboxServerModule = require(SSS.Modules.Game.Hitbox)

-- Packages
local Networker = require(RS.Packages.Networker)
local DataService = require(RS.Packages.DataService).server
local Janitor = require(RS.Packages.Janitor)
local ConnectionHub = require(RS.Packages.ConnectionHub)

-- Utils
local FighterConfig = require(RS.Shared.Utils.FighterConfig)

-- Constants
local CombatServiceConstants = require(RS.Shared.Services.CombatService.Constants)

local activeRegenTasks: { [Model]: boolean } = {} -- active regen tasks to prevent multiple regen tasks from being created for the same character
local blockStartTimes: { [Model]: number } = {}
local playerJanitors: { [Player]: typeof(Janitor.new()) } = {}

local function getPlayerFighterConfig(player: Player)
	local fighterName = DataService:get(player, { "selectedFighter" }) :: string
	return FighterConfig.get(fighterName)
end

local function startBlockRegen(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local janitor = playerJanitors[player]
	if not janitor then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if activeRegenTasks[character] then
		return
	end
	activeRegenTasks[character] = true

	-- task.spawn to prevent yielding the current thread wherever this function is called
	janitor:Add(
		task.spawn(function()
			while
				activeRegenTasks[character]
				and character:GetAttribute("BlockMeter") < 100
				and not character:GetAttribute("IsBlocking")
				and humanoid.Health > 0
				and character.Parent
			do
				local currentBlockMeter = character:GetAttribute("BlockMeter") :: number
				character:SetAttribute(
					"BlockMeter",
					math.min(100, currentBlockMeter + CombatServiceConstants.BLOCK_REGEN_RATE)
				)
				task.wait(CombatServiceConstants.BLOCK_REGEN_INTERVAL)
			end
			activeRegenTasks[character] = nil
		end),
		true
	)
end

local function setInitialPlayerCombatAttributes(player: Player)
	local janitor = playerJanitors[player]
	if not janitor then
		return
	end

	janitor:Add(
		player.CharacterAdded:Connect(function(character)
			character:SetAttribute("IsBlocking", false)
			character:SetAttribute("BlockMeter", 100)
			character:SetAttribute("IsStunned", false)
			character:SetAttribute("IsParryStunned", false)
			character:SetAttribute("IsBlockBroken", false)
		end),
		"Disconnect"
	)
end

local function getDamage(player: Player, combo: number, isBlocking: boolean)
	local fighterConfig = getPlayerFighterConfig(player)
	local DAMAGE_REDUCTION_FACTOR: number = if isBlocking then 0.50 else 1
	local DAMAGE = if combo == fighterConfig.MaxComboCount
		then fighterConfig.Damage.Heavy
		else fighterConfig.Damage.Normal

	return DAMAGE * DAMAGE_REDUCTION_FACTOR
end

local function processHit(player: Player, combo: number, attackerCharacter: Model, hitHumanoid: Humanoid)
	local hitCharacter = hitHumanoid.Parent :: Model
	local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
	local attackerLeaderstats =
		player:FindFirstChild("leaderstats") :: Folder & { Kills: IntValue, ["Total Kills"]: IntValue }

	-- Ignore damage prevention logic for dummies
	if hitCharacter.Name ~= "Dummy" and hitCharacter.Name ~= "Killable Dummy" then
		if not hitPlayer or hitPlayer:GetAttribute("IsInMainMenu") then
			return
		end
	end

	local attackerFighterConfig = getPlayerFighterConfig(player)
	local defenderFighterConfig = if hitPlayer then getPlayerFighterConfig(hitPlayer) else attackerFighterConfig

	local defenderRootPart = hitCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
	local NEW_BLOCK_METER_VALUE =
		math.max(0, hitCharacter:GetAttribute("BlockMeter") :: number - CombatServiceConstants.BLOCK_DRAIN_AMOUNT)
	local isBlockValid = false

	if hitCharacter:GetAttribute("IsBlocking") then -- if the defender is blocking, reduce their block meter
		local attackerRootPart = attackerCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
		local directionToAttacker = (attackerRootPart.Position - defenderRootPart.Position).Unit
		local defenderLookVector = defenderRootPart.CFrame.LookVector
		local frontalDot = defenderLookVector:Dot(directionToAttacker)

		if frontalDot > CombatServiceConstants.BLOCK_ANGLE_THRESHOLD then -- if the defender is facing the attacker within the threshold
			if
				blockStartTimes[hitCharacter]
				and os.clock() - blockStartTimes[hitCharacter] <= CombatServiceConstants.PARRY_WINDOW
			then
				local parrySFX = defenderFighterConfig.SFX.Parry:Clone()
				parrySFX.Parent = defenderRootPart
				attackerCharacter:SetAttribute("IsStunned", true)
				attackerCharacter:SetAttribute("IsParryStunned", true)
				parrySFX:Play()
				task.delay(defenderFighterConfig.Stuns.ParryDuration, function()
					attackerCharacter:SetAttribute("IsStunned", false)
					attackerCharacter:SetAttribute("IsParryStunned", false)
				end)
				parrySFX.Ended:Once(function()
					parrySFX:Destroy()
				end)
				return
			else
				isBlockValid = true
				local blockDrainSFX = defenderFighterConfig.SFX.BlockDrain:Clone()
				blockDrainSFX.Parent = defenderRootPart
				hitCharacter:SetAttribute("BlockMeter", NEW_BLOCK_METER_VALUE)
				blockDrainSFX:Play()
				blockDrainSFX.Ended:Once(function()
					blockDrainSFX:Destroy()
				end)
			end
		end
	end

	if hitCharacter:GetAttribute("BlockMeter") == 0 and not hitCharacter:GetAttribute("IsStunned") then -- if the defender's block meter is empty, stun them and break their block
		local blockBreakSFX = defenderFighterConfig.SFX.BlockBreak:Clone()
		blockBreakSFX.Parent = defenderRootPart
		hitCharacter:SetAttribute("IsBlocking", false)
		hitCharacter:SetAttribute("IsStunned", true)
		hitCharacter:SetAttribute("IsBlockBroken", true)
		blockBreakSFX:Play()
		task.delay(defenderFighterConfig.Stuns.BlockBreakDuration, function()
			hitCharacter:SetAttribute("IsStunned", false)
			hitCharacter:SetAttribute("IsBlockBroken", false)
			startBlockRegen(hitCharacter)
		end)
		blockBreakSFX.Ended:Once(function()
			blockBreakSFX:Destroy()
		end)
	end

	if not isBlockValid then
		local impactSFX = attackerFighterConfig.SFX.Impact:Clone()
		impactSFX.Parent = defenderRootPart
		impactSFX:Play()
		impactSFX.Ended:Once(function()
			impactSFX:Destroy()
		end)
	end
	local DAMAGE = getDamage(player, combo, isBlockValid)
	hitHumanoid:TakeDamage(DAMAGE)

	if hitCharacter.Name ~= "Dummy" then
		if hitHumanoid.Health <= 0 then
			attackerLeaderstats.Kills.Value += 1
			DataService:update(player, "totalKills", function(currentTotalKills: number)
				return currentTotalKills + 1
			end)
			attackerLeaderstats["Total Kills"].Value += 1
		end
	end
end

local function setupPlayer(player: Player)
	local janitor = Janitor.new()
	playerJanitors[player] = janitor
	setInitialPlayerCombatAttributes(player)

	janitor:Add(function()
		local character = player.Character
		if not character then
			return
		end
		activeRegenTasks[character] = nil
		blockStartTimes[character] = nil
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

function CombatServiceServer.Init(self: CombatServiceServer)
	self.Networker = Networker.server.new(
		"CombatService",
		self,
		{ self.Attack :: any, self.PlayCombatSFX :: any, self.HandleBlock :: any }
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

function CombatServiceServer.Attack(_self: CombatServiceServer, player: Player, combo: number)
	local character = player.Character
	if not character then
		return
	end

	if character:GetAttribute("IsStunned") then -- if the attacker is stunned, they shouldn't be able to attack
		return
	end

	local hitHumanoids = HitboxServerModule.CreateHitbox(player)

	for _, humanoid in hitHumanoids do
		if humanoid.Health <= 0 then
			continue
		end
		processHit(player, combo, character, humanoid)
	end
end

function CombatServiceServer.PlayCombatSFX(_self: CombatServiceServer, player: Player, sfxName: string)
	local fighterConfig = getPlayerFighterConfig(player)
	local character = player.Character
	if not character then
		return
	end

	local attackerRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local SFX: Sound
	if sfxName == "Normal" then
		SFX = fighterConfig.SFX.NormalAttack:Clone()
	elseif sfxName == "Heavy" then
		SFX = fighterConfig.SFX.HeavyAttack:Clone()
	end
	if not SFX then
		return
	end
	SFX.Parent = attackerRootPart
	SFX:Play()
	SFX.Ended:Once(function()
		SFX:Destroy()
	end)
end

function CombatServiceServer.HandleBlock(_self: CombatServiceServer, player: Player, isBlocking: boolean)
	local character = player.Character
	if not character then
		return
	end
	-- the isBlocking check is necessary to prevent exploiters from manually sending `true` to the server despite their meter being too low to block
	if isBlocking and character:GetAttribute("BlockMeter") < CombatServiceConstants.BLOCK_DRAIN_AMOUNT then -- if the player's block meter is too low, they shouldn't be able to block
		return
	end

	character:SetAttribute("IsBlocking", isBlocking)

	if isBlocking then
		blockStartTimes[character] = os.clock()
	else
		blockStartTimes[character] = nil
		if not character:GetAttribute("IsStunned") then
			startBlockRegen(character)
		end
	end
end

type CombatServiceServer = typeof(CombatServiceServer) & {
	Networker: Networker.Server,
}

return CombatServiceServer :: CombatServiceServer
