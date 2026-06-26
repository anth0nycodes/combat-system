--!strict
-- Game Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Types
local FighterConfigTypes = require(RS.Shared.Fighters.Types)
local CombatServiceClient = {}

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

-- Packages
local Networker = require(RS.Packages.Networker)

function CombatServiceClient.Init(self: CombatServiceClient)
	local function onCharacterAdded(newCharacter: Model, newHumanoid: Humanoid)
		fighterConfig = FighterConfigModule.get()
		character = newCharacter
		humanoid = newHumanoid
		humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

		self.Config.IsAttacking = false
		self.Config.CurrentAnimationTrack = nil
		self.Config.AttackId = 0

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
					if self.Config.CurrentAnimationTrack then
						self.Config.CurrentAnimationTrack:Stop()
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

	self.Config = {
		Combo = 1,
		ComboResetTime = 0.80,
		IsAttacking = false,
		ComboBreakTime = 0,
		LastAttackTime = 0,
		CurrentAnimationTrack = nil,
		CanCancel = false,
		AttackId = 0, -- Purpose is to prevent stale attacks from continuing if already cancelled
	}
	self.Networker = Networker.client.new("CombatService", self)
	CharacterLoader.Init(onCharacterAdded)
	AnimationLoader.Init()
	self:BindEvents()
end

function CombatServiceClient.BindEvents(self: CombatServiceClient)
	m1Action.Pressed:Connect(function()
		local now = DateTime.now().UnixTimestampMillis / 1000
		if
			humanoid.Health <= 0
			or character:GetAttribute("IsStunned")
			or character:GetAttribute("IsBlocking")
			or now < self.Config.ComboBreakTime
		then
			return
		end

		if self.Config.IsAttacking then
			if not self.Config.CanCancel then
				return
			end
		end

		self:Attack()
	end)

	blockAction.Pressed:Connect(function()
		self:Block()
	end)

	blockAction.Released:Connect(function()
		if not character:GetAttribute("IsBlocking") and not (blockTrack and blockTrack.IsPlaying) then
			self.Networker:fire("HandleBlock", false)
			return
		end
		if blockTrack then
			blockTrack:Stop()
		end
		self.Networker:fire("HandleBlock", false)
		humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
	end)
end

function CombatServiceClient.Attack(self: CombatServiceClient)
	if
		blockAction:GetState()
		or humanoid.Health <= 0
		or character:GetAttribute("IsStunned")
		or character:GetAttribute("IsBlocking")
	then
		return
	end

	self.Config.AttackId += 1
	local attackId = self.Config.AttackId

	if self.Config.CurrentAnimationTrack then
		self.Config.CurrentAnimationTrack:Stop()
	end

	self.Config.IsAttacking = true
	local combo = self.Config.Combo
	local currentTime = DateTime.now().UnixTimestampMillis / 1000
	local timeSinceLastAttack = currentTime - self.Config.LastAttackTime

	if timeSinceLastAttack <= self.Config.ComboResetTime then
		combo += 1
	else
		combo = 1
	end

	self.Config.Combo = combo
	local isLastHit = self.Config.Combo == fighterConfig.MaxComboCount

	if isLastHit then
		self.Config.ComboBreakTime = currentTime + 1
	end

	if combo > fighterConfig.MaxComboCount then
		combo = 1
	end

	self.Config.LastAttackTime = currentTime

	local m1Data = fighterConfig.Animations.M1Animations[combo]
	local currentAnimationTrack = AnimationLoader.LoadAnimation(m1Data.Animation)
	self.Config.CurrentAnimationTrack = currentAnimationTrack
	self.Config.CanCancel = false

	currentAnimationTrack:GetMarkerReachedSignal("Hit"):Connect(function()
		if self.Config.AttackId ~= attackId then
			return
		end
		if character:GetAttribute("IsStunned") then
			return
		end
		if not humanoidRootPart then
			return
		end

		local sfxEvent = if combo == fighterConfig.MaxComboCount then "Heavy" else "Normal"
		self.Networker:fire("PlayCombatSFX", sfxEvent)
		HitboxClientModule.CreateHitbox(humanoidRootPart)
		self.Networker:fire("Attack", combo)
	end)

	currentAnimationTrack:GetMarkerReachedSignal("CanCancel"):Connect(function()
		if self.Config.AttackId ~= attackId then
			return
		end
		self.Config.CanCancel = true
	end)

	if m1Data.Lunge then
		currentAnimationTrack:GetMarkerReachedSignal("Lunge"):Connect(function()
			if self.Config.AttackId ~= attackId then
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

	if self.Config.AttackId ~= attackId then -- Stale attack check, don't overwrite state below owned by the new attack
		return
	end

	self.Config.CurrentAnimationTrack = nil
	self.Config.IsAttacking = false
	if not character:GetAttribute("IsStunned") then
		humanoid.WalkSpeed = fighterConfig.WalkSpeed.Base
	end
end

function CombatServiceClient.Block(self: CombatServiceClient)
	if
		character:GetAttribute("IsStunned")
		or character:GetAttribute("BlockMeter") < CombatServiceConstants.BLOCK_DRAIN_AMOUNT
		or self.Config.IsAttacking
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
	self.Networker:fire("HandleBlock", true)
	humanoid.WalkSpeed = fighterConfig.WalkSpeed.Blocking
end

type CombatServiceClient = typeof(CombatServiceClient) & {
	Config: {
		Combo: number,
		ComboResetTime: number,
		IsAttacking: boolean,
		ComboBreakTime: number,
		LastAttackTime: number,
		CurrentAnimationTrack: AnimationTrack?,
		CanCancel: boolean,
		AttackId: number, -- Purpose is to prevent stale attacks from continuing if already cancelled
	},
	Networker: Networker.Client,
}

return CombatServiceClient :: CombatServiceClient
