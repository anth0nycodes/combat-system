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

-- Fighter Config
local fighterConfig = FighterConfigModule.get()

-- Remotes
local AttackRemote = RS.Remotes.AttackRemote
local BlockRemote = RS.Remotes.BlockRemote

-- Utils
local AnimationLoader = require(RS.Utils.AnimationLoader)
local CharacterLoader = require(RS.Utils.CharacterLoader)

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
}

local function onCharacterAdded(newCharacter: Model, newHumanoid: Humanoid)
	character = newCharacter
	humanoid = newHumanoid

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
			or CombatServiceClient.Config.IsAttacking
			or character:GetAttribute("IsStunned")
			or character:GetAttribute("IsBlocking")
			or now < CombatServiceClient.Config.ComboBreakTime
		then
			return
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

	local currentAnimationTrack =
		AnimationLoader.LoadAnimation(fighterConfig.Animations.M1Animations[CombatServiceClient.Config.Combo])
	local strikeSound = if CombatServiceClient.Config.Combo == fighterConfig.MaxComboCount
		then fighterConfig.SFX.HeavyAttack
		else fighterConfig.SFX.NormalAttack

	currentAnimationTrack:Play()
	humanoid.WalkSpeed = fighterConfig.WalkSpeed.Attacking
	currentAnimationTrack:GetMarkerReachedSignal("Hit"):Connect(function()
		if character:GetAttribute("IsStunned") then -- client check to prevent sfx and hitbox from activating
			return
		end
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
		strikeSound:Play()
		HitboxClientModule.CreateHitbox(humanoidRootPart)
		AttackRemote:FireServer(combo)
	end)
	currentAnimationTrack.Stopped:Wait()
	if not character:GetAttribute("IsStunned") then
		humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
	end
	CombatServiceClient.Config.IsAttacking = false
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
