--!strict
-- Game Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Types
local CombatServiceClientTypes = require(script.Parent.Types)
local FighterConfigTypes = require(RS.Shared.Fighters.Types)
local CombatServiceClient = {} :: CombatServiceClientTypes.CombatServiceClientType

-- Modules
local HitboxClientModule = require(RS.Shared.Modules.Game.Hitbox)
local FighterConfigModule = require(RS.Utils.FighterConfig)

-- Player
local player = Players.LocalPlayer
assert(player, "Player is not defined")
local character: Model
local humanoid: Humanoid
local humanoidRootPart: BasePart

-- Fighter Config
local fighterConfig: FighterConfigTypes.FighterConfigType

-- Remotes
local AttackRemote = RS.Remotes.AttackRemote
local BlockRemote = RS.Remotes.BlockRemote
local SFXRemote = RS.Remotes.SFXRemote

-- Utils
local AnimationLoader = require(RS.Utils.AnimationLoader)
local CharacterLoader = require(RS.Utils.CharacterLoader)
local ForceManager = require(RS.Utils.ForceManager)

-- Combat Actions
local m1Action = RS.Inputs.Combat.M1
local blockAction = RS.Inputs.Combat.Block

-- Block Animation
local blockTrack: AnimationTrack

-- Constants
local CombatServiceConstants = require(script.Parent.Constants)

-- Module Config
CombatServiceClient.Config = {
	Combo = 1,
	ComboResetTime = 0.80,
	IsAttacking = false,
	ComboBreakTime = 0,
	LastAttackTime = 0,
	CurrentAnimationTrack = nil,
	CanCancel = false,
	AttackId = 0, -- Purpose is to prevent stale attacks from continuing if already cancelled
}

local function onCharacterAdded(newCharacter: Model, newHumanoid: Humanoid)
	fighterConfig = FighterConfigModule.get()
	character = newCharacter
	humanoid = newHumanoid
	humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	CombatServiceClient.Config.IsAttacking = false
	CombatServiceClient.Config.CurrentAnimationTrack = nil
	CombatServiceClient.Config.AttackId = 0

	character:GetAttributeChangedSignal("IsStunned"):Connect(function()
		if character:GetAttribute("IsStunned") then
			if character:GetAttribute("IsBlockBroken") then
				if blockTrack then
					blockTrack:Stop()
				end
				local blockBreakTrack = AnimationLoader.LoadAnimation(fighterConfig.Animations.BlockBreakAnimation)
				blockBreakTrack:Play()
				blockBreakTrack:AdjustSpeed(2)
				humanoid.WalkSpeed = fighterConfig.WalkSpeed.BlockBroken
				character:GetAttributeChangedSignal("IsBlockBroken"):Wait()
				blockBreakTrack:Stop()
				humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
			elseif character:GetAttribute("IsParryStunned") then
				if CombatServiceClient.Config.CurrentAnimationTrack then
					CombatServiceClient.Config.CurrentAnimationTrack:Stop()
				end
				local parryStunTrack = AnimationLoader.LoadAnimation(fighterConfig.Animations.ParryStunAnimation)
				parryStunTrack:Play()
				humanoid.WalkSpeed = fighterConfig.WalkSpeed.Parried
				character:GetAttributeChangedSignal("IsParryStunned"):Wait()
				parryStunTrack:Stop()
				humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
			end
		end
	end)
end

function CombatServiceClient.Init()
	CharacterLoader.Init(onCharacterAdded)
	AnimationLoader.Init()
	CombatServiceClient.BindEvents()
end

function CombatServiceClient.BindEvents()
	m1Action.Pressed:Connect(function()
		local now = DateTime.now().UnixTimestampMillis / 1000
		if
			humanoid.Health <= 0
			or character:GetAttribute("IsStunned")
			or character:GetAttribute("IsBlocking")
			or now < CombatServiceClient.Config.ComboBreakTime
		then
			return
		end

		if CombatServiceClient.Config.IsAttacking then
			if not CombatServiceClient.Config.CanCancel then
				return
			end
		end

		CombatServiceClient.Attack()
	end)

	blockAction.Pressed:Connect(function()
		CombatServiceClient.Block()
	end)

	blockAction.Released:Connect(function()
		if not character:GetAttribute("IsBlocking") and not (blockTrack and blockTrack.IsPlaying) then
			BlockRemote:FireServer(false)
			return
		end
		if blockTrack then
			blockTrack:Stop()
		end
		BlockRemote:FireServer(false)
		humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
	end)
end

function CombatServiceClient.Attack()
	if
		blockAction:GetState()
		or humanoid.Health <= 0
		or character:GetAttribute("IsStunned")
		or character:GetAttribute("IsBlocking")
	then
		return
	end

	CombatServiceClient.Config.AttackId += 1
	local attackId = CombatServiceClient.Config.AttackId

	if CombatServiceClient.Config.CurrentAnimationTrack then
		CombatServiceClient.Config.CurrentAnimationTrack:Stop()
	end

	CombatServiceClient.Config.IsAttacking = true
	local combo = CombatServiceClient.Config.Combo
	local currentTime = DateTime.now().UnixTimestampMillis / 1000
	local timeSinceLastAttack = currentTime - CombatServiceClient.Config.LastAttackTime

	if timeSinceLastAttack <= CombatServiceClient.Config.ComboResetTime then
		combo += 1
	else
		combo = 1
	end

	CombatServiceClient.Config.Combo = combo
	local isLastHit = CombatServiceClient.Config.Combo == fighterConfig.MaxComboCount

	if isLastHit then
		CombatServiceClient.Config.ComboBreakTime = currentTime + 1
	end

	if combo > fighterConfig.MaxComboCount then
		combo = 1
	end

	CombatServiceClient.Config.LastAttackTime = currentTime

	local m1Data = fighterConfig.Animations.M1Animations[combo]
	local currentAnimationTrack = AnimationLoader.LoadAnimation(m1Data.Animation)
	CombatServiceClient.Config.CurrentAnimationTrack = currentAnimationTrack
	CombatServiceClient.Config.CanCancel = false

	currentAnimationTrack:GetMarkerReachedSignal("Hit"):Connect(function()
		if CombatServiceClient.Config.AttackId ~= attackId then
			return
		end
		if character:GetAttribute("IsStunned") then
			return
		end
		if not humanoidRootPart then
			return
		end

		local sfxEvent = if combo == fighterConfig.MaxComboCount then "Heavy" else "Normal"
		SFXRemote:FireServer(sfxEvent)
		HitboxClientModule.CreateHitbox(player, humanoidRootPart)
		AttackRemote:FireServer(combo)
	end)

	currentAnimationTrack:GetMarkerReachedSignal("CanCancel"):Connect(function()
		if CombatServiceClient.Config.AttackId ~= attackId then
			return
		end
		CombatServiceClient.Config.CanCancel = true
	end)

	if m1Data.Lunge then
		currentAnimationTrack:GetMarkerReachedSignal("Lunge"):Connect(function()
			if CombatServiceClient.Config.AttackId ~= attackId then
				return
			end
			if character:GetAttribute("IsStunned") then
				return
			end
			if not humanoidRootPart then
				return
			end
			ForceManager.ApplyForce(humanoidRootPart, m1Data.Lunge.LungeForce, m1Data.Lunge.LungeDuration)
		end)
	end

	currentAnimationTrack:Play()
	humanoid.WalkSpeed = fighterConfig.WalkSpeed.Attacking

	currentAnimationTrack.Stopped:Wait()

	if CombatServiceClient.Config.AttackId ~= attackId then -- Stale attack check, don't overwrite state below owned by the new attack
		return
	end

	CombatServiceClient.Config.CurrentAnimationTrack = nil
	CombatServiceClient.Config.IsAttacking = false
	if not character:GetAttribute("IsStunned") then
		humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
	end
end

function CombatServiceClient.Block()
	if
		character:GetAttribute("IsStunned")
		or character:GetAttribute("BlockMeter") < CombatServiceConstants.BLOCK_DRAIN_AMOUNT
		or CombatServiceClient.Config.IsAttacking
		or humanoid.Health <= 0
	then
		return
	end
	task.wait(0.0375) -- Small delay to prevent blocking immediately after attacking
	if not blockAction:GetState() then -- Bail if player released block during startup delay
		return
	end
	print("Block")
	blockTrack = AnimationLoader.LoadAnimation(fighterConfig.Animations.BlockAnimation)
	blockTrack:Play()
	BlockRemote:FireServer(true)
	humanoid.WalkSpeed = fighterConfig.WalkSpeed.Blocking
end

return CombatServiceClient
