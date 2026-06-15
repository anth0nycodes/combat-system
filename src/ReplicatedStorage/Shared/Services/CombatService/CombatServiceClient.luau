--!strict
-- Types
local Types = require(script.Parent.Types)
local CombatServiceClient = {} :: Types.CombatServiceClientType

-- Game Services
local RS = game:GetService("ReplicatedStorage")

-- Modules
local HitboxClientModule = require(RS.Shared.Modules.Game.Hitbox)
local FighterConfigModule = require(RS.Utils.FighterConfig)

-- Player
local character: Model
local humanoid: Humanoid
local humanoidRootPart: BasePart

-- Fighter Config
local fighterConfig = FighterConfigModule.get()

-- Remotes
local AttackRemote = RS.Remotes.AttackRemote
local BlockRemote = RS.Remotes.BlockRemote

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
local BLOCK_DRAIN_AMOUNT = 15

-- Module Config
CombatServiceClient.Config = {
	Combo = 1,
	ComboResetTime = 0.80,
	IsAttacking = false,
	ComboBreakTime = 0,
	LastAttackTime = 0,
	CurrentAnimationTrack = nil,
	CurrentCanCancelAt = 0,
	AttackId = 0, -- Purpose is to prevent stale attacks from continuing if already cancelled
}

local function onCharacterAdded(newCharacter: Model, newHumanoid: Humanoid)
	character = newCharacter
	humanoid = newHumanoid
	humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	CombatServiceClient.Config.IsAttacking = false
	CombatServiceClient.Config.CurrentAnimationTrack = nil
	CombatServiceClient.Config.AttackId = 0

	character:GetAttributeChangedSignal("IsStunned"):Connect(function()
		if character:GetAttribute("IsStunned") then
			if blockTrack then
				blockTrack:Stop()
			end
			local blockBreakTrack = AnimationLoader.LoadAnimation(fighterConfig.Animations.BlockBreakAnimation)
			blockBreakTrack:Play()
			blockBreakTrack:AdjustSpeed(2)
			fighterConfig.SFX.BlockBreak:Play()
			humanoid.WalkSpeed = fighterConfig.WalkSpeed.BlockBroken
			blockBreakTrack.Stopped:Wait()
			humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
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
			local elapsed = now - CombatServiceClient.Config.LastAttackTime
			if elapsed < CombatServiceClient.Config.CurrentCanCancelAt then -- can't cancel until at least the can cancel time has passed
				return
			end
		end

		CombatServiceClient.Attack()
	end)

	blockAction.Pressed:Connect(function()
		CombatServiceClient.Block()
	end)

	blockAction.Released:Connect(function()
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
	CombatServiceClient.Config.CurrentCanCancelAt = m1Data.CanCancelAt

	local strikeSound = if CombatServiceClient.Config.Combo == fighterConfig.MaxComboCount
		then fighterConfig.SFX.HeavyAttack
		else fighterConfig.SFX.NormalAttack

	currentAnimationTrack:Play()
	strikeSound:Play()
	humanoid.WalkSpeed = fighterConfig.WalkSpeed.Attacking

	for _, hitTime in m1Data.HitAt do
		task.delay(hitTime, function()
			if CombatServiceClient.Config.AttackId ~= attackId then
				return
			end
			if character:GetAttribute("IsStunned") then
				return
			end
			if not humanoidRootPart then
				return
			end
			HitboxClientModule.CreateHitbox(humanoidRootPart)
			AttackRemote:FireServer(combo)
		end)
	end

	if m1Data.Lunge then
		for _, lungeTime in m1Data.Lunge.LungeAt do
			task.delay(lungeTime, function()
				if CombatServiceClient.Config.AttackId ~= attackId then
					return
				end
				if character:GetAttribute("IsStunned") then
					return
				end
				if not humanoidRootPart then
					return
				end
				ForceManager.applyForce(humanoidRootPart, m1Data.Lunge.LungeForce)
			end)
		end
	end

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
		or character:GetAttribute("BlockMeter") < BLOCK_DRAIN_AMOUNT
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
