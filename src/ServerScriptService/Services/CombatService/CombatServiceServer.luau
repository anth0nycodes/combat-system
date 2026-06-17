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

local blockStartTimes: { [Model]: number } = {}

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
		character:SetAttribute("IsBlocking", false)
		character:SetAttribute("BlockMeter", 100)
		character:SetAttribute("IsStunned", false)
		character:SetAttribute("IsParryStunned", false)
		character:SetAttribute("IsBlockBroken", false)
	end)
end

local function getDamage(combo: number, isBlocking: boolean)
	local DAMAGE_REDUCTION_FACTOR: number = if isBlocking then 0.50 else 1
	local DAMAGE = if combo == fighterConfig.MaxComboCount
		then fighterConfig.Damage.Heavy
		else fighterConfig.Damage.Normal

	return DAMAGE * DAMAGE_REDUCTION_FACTOR
end

local function processHit(combo: number, attackerCharacter: Model, hitHumanoid: Humanoid)
	local hitCharacter = hitHumanoid.Parent :: Model
	local NEW_BLOCK_METER_VALUE =
		math.max(0, hitCharacter:GetAttribute("BlockMeter") :: number - CombatServiceConstants.BLOCK_DRAIN_AMOUNT)
	local isBlockValid = false

	if hitCharacter:GetAttribute("IsBlocking") then -- if the defender is blocking, reduce their block meter
		local attackerRootPart = attackerCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
		local defenderRootPart = hitCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
		local directionToAttacker = (attackerRootPart.Position - defenderRootPart.Position).Unit
		local defenderLookVector = defenderRootPart.CFrame.LookVector
		local frontalDot = defenderLookVector:Dot(directionToAttacker)

		if frontalDot > CombatServiceConstants.BLOCK_ANGLE_THRESHOLD then -- if the defender is facing the attacker within the threshold
			if
				blockStartTimes[hitCharacter]
				and os.clock() - blockStartTimes[hitCharacter] <= CombatServiceConstants.PARRY_WINDOW
			then
				local parrySFX = fighterConfig.SFX.Parry:Clone()
				parrySFX.Parent = defenderRootPart
				attackerCharacter:SetAttribute("IsStunned", true)
				attackerCharacter:SetAttribute("IsParryStunned", true)
				parrySFX:Play()
				task.delay(fighterConfig.Stuns.ParryDuration, function()
					attackerCharacter:SetAttribute("IsStunned", false)
					attackerCharacter:SetAttribute("IsParryStunned", false)
				end)
				return
			else
				isBlockValid = true
				hitCharacter:SetAttribute("BlockMeter", NEW_BLOCK_METER_VALUE)
			end
		end
	end

	if hitCharacter:GetAttribute("BlockMeter") == 0 and not hitCharacter:GetAttribute("IsStunned") then -- if the defender's block meter is empty, stun them and break their block
		hitCharacter:SetAttribute("IsBlocking", false)
		hitCharacter:SetAttribute("IsStunned", true)
		hitCharacter:SetAttribute("IsBlockBroken", true)
		task.delay(fighterConfig.Stuns.BlockBreakDuration, function()
			hitCharacter:SetAttribute("IsStunned", false)
			hitCharacter:SetAttribute("IsBlockBroken", false)
			startBlockRegen(hitCharacter)
		end)
	end

	local DAMAGE = getDamage(combo, isBlockValid)
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
			processHit(combo, character, humanoid)
		end
	end)

	BlockRemote.OnServerEvent:Connect(function(player: Player, isBlocking: boolean)
		local character = player.Character or player.CharacterAdded:Wait()
		-- the isBlocking check is necessary to prevent exploiters from manually sending `true` to the server despite their meter being too low to block
		if isBlocking and character:GetAttribute("BlockMeter") < CombatServiceConstants.BLOCK_DRAIN_AMOUNT then -- if the player's block meter is too low, they shouldn't be able to block
			return
		end

		character:SetAttribute("IsBlocking", isBlocking)

		if isBlocking then
			blockStartTimes[character] = os.clock()
		else
			blockStartTimes[character] = nil
			startBlockRegen(character)
		end
	end)
end

return CombatServiceServer
