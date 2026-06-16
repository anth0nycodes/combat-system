--!strict
local CombatServiceServer = {}

-- Game Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

-- Modules
local HitboxServerModule = require(SSS.Modules.Game.Hitbox)
local FighterConfigModule = require(RS.Utils.FighterConfig)

-- Fighter Config
local fighterConfig = FighterConfigModule.get()

-- Remotes
local AttackRemote = RS.Remotes.AttackRemote
local BlockRemote = RS.Remotes.BlockRemote

-- Constants
local CombatServiceConstants = require(RS.Shared.Services.CombatService.Constants)

-- active regen tasks to prevent multiple regen tasks from being created for the same character
local activeRegenTasks: { [Model]: boolean } = {}

-- should regenerate 10%/sec
local function startBlockRegen(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end
	if activeRegenTasks[character] then
		return
	end
	activeRegenTasks[character] = true

	-- task.spawn to prevent yielding the current thread wherever this function is called
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
	end)
end

local function setInitialPlayerCombatAttributes(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:SetAttribute("IsStunned", false)
		character:SetAttribute("IsBlocking", false)
		character:SetAttribute("BlockMeter", 100)
	end)
end

local function getDamage(combo: number, hitHumanoid: Humanoid)
	local hitCharacter = hitHumanoid.Parent :: Model
	local DAMAGE_REDUCTION_FACTOR: number
	if hitCharacter:GetAttribute("IsBlocking") then
		DAMAGE_REDUCTION_FACTOR = 0.50
	else
		DAMAGE_REDUCTION_FACTOR = 1
	end
	local DAMAGE = if combo == fighterConfig.MaxComboCount
		then fighterConfig.Damage.Heavy
		else fighterConfig.Damage.Normal

	return DAMAGE * DAMAGE_REDUCTION_FACTOR
end

local function processHit(combo: number, hitHumanoid: Humanoid)
	local hitCharacter = hitHumanoid.Parent :: Model
	local DAMAGE = getDamage(combo, hitHumanoid)
	local NEW_BLOCK_METER_VALUE =
		math.max(0, hitCharacter:GetAttribute("BlockMeter") :: number - CombatServiceConstants.BLOCK_DRAIN_AMOUNT)

	if hitCharacter:GetAttribute("IsBlocking") then -- if the hit character is blocking, reduce their block meter
		hitCharacter:SetAttribute("BlockMeter", NEW_BLOCK_METER_VALUE)
	end

	if hitCharacter:GetAttribute("BlockMeter") == 0 and not hitCharacter:GetAttribute("IsStunned") then -- if the hit character's block meter is empty, stun them and break their block
		hitCharacter:SetAttribute("IsBlocking", false)
		hitCharacter:SetAttribute("IsStunned", true)
		task.delay(fighterConfig.Stuns.BlockBreakDuration, function()
			hitCharacter:SetAttribute("IsStunned", false)
			startBlockRegen(hitCharacter)
		end)
	end

	hitHumanoid:TakeDamage(DAMAGE)
end

function CombatServiceServer.Init()
	Players.PlayerAdded:Connect(setInitialPlayerCombatAttributes)
	for _, player in Players:GetPlayers() do
		setInitialPlayerCombatAttributes(player)
	end

	AttackRemote.OnServerEvent:Connect(function(player: Player, combo: number)
		local character = player.Character or player.CharacterAdded:Wait()
		if character:GetAttribute("IsStunned") then -- if the attacker is stunned, they shouldn't be able to attack
			return
		end
		local hitHumanoids = HitboxServerModule.CreateHitbox(player)

		if not hitHumanoids then
			return
		end

		for _, humanoid in hitHumanoids do
			if humanoid.Health <= 0 then
				continue
			end
			processHit(combo, humanoid)
		end
	end)

	BlockRemote.OnServerEvent:Connect(function(player: Player, isBlocking: boolean, regenerateBlock: boolean?)
		local character = player.Character or player.CharacterAdded:Wait()
		-- the isBlocking check is necessary to prevent exploiters from manually sending `true` to the server despite their meter being too low to block
		if isBlocking and character:GetAttribute("BlockMeter") < CombatServiceConstants.BLOCK_DRAIN_AMOUNT then -- if the player's block meter is too low, they shouldn't be able to block
			return
		end
		character:SetAttribute("IsBlocking", isBlocking)

		if regenerateBlock then
			startBlockRegen(character)
		end
	end)
end

return CombatServiceServer
