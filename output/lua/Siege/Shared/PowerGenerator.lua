-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\PowerGenerator.lua
--
-- Power Generator entity that controls lighting for multiple locations.
-- Unlike PowerPoint which controls power, PowerGenerator only controls lighting
-- for assigned locations based on generator ID.
--
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'PowerGenerator' (ScriptActor)

if Client then
    Script.Load("lua/Siege/Client/PowerGenerator_Client.lua")
end

PowerGenerator.kMapName = "power_generator"

local kModelName = PrecacheAsset("models/system/editor/power_node.model")
local kAnimationGraph = PrecacheAsset("models/system/editor/power_node.animation_graph")

-- Reuse effects from PowerPoint
local kDamagedEffect = PrecacheAsset("cinematics/common/powerpoint_damaged.cinematic")
local kOfflineEffect = PrecacheAsset("cinematics/common/powerpoint_offline.cinematic")

local kTakeDamageSound = PrecacheAsset("sound/NS2.fev/marine/power_node/take_damage")
local kDamagedSound = PrecacheAsset("sound/NS2.fev/marine/power_node/damaged")
local kDestroyedSound = PrecacheAsset("sound/NS2.fev/marine/power_node/destroyed")

PowerGenerator.kDestroyedMaterial = PrecacheAsset("models/system/editor/power_node_destroyed.material")
PowerGenerator.kCriticalDamageMaterial = PrecacheAsset("models/system/editor/power_node_damaged.material")

-- Health and armor values
local kPowerGeneratorHealth = 2000
local kPowerGeneratorArmor = 500

-- Percentage value for damaged state
PowerGenerator.kDamagedPercentage = 0.4

local networkVars =
{
    lightMode = "enum kLightMode",
    timeOfLightModeChange = "time",
    powerGeneratorId = "integer", -- Unique ID to link locations to this generator
    attackTime = "float (0 to 10.1 by 0.01)"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function PowerGenerator:OnCreate()
    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, CombatMixin)

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

    self.lightMode = kLightMode.Normal

    if Client then
        self:AddTimedCallback(PowerGenerator.OnTimedUpdate, kUpdateIntervalLow)
    end

    self:SetModel(kModelName, kAnimationGraph)

    self.health = kPowerGeneratorHealth
    self.armor = kPowerGeneratorArmor
    self:SetMaxHealth(kPowerGeneratorHealth)
    self:SetMaxArmor(kPowerGeneratorArmor)

    if self.powerGeneratorId == nil then
        self.powerGeneratorId = 0
    end

    if Server then
        self.attackTime = 0.0
        self.playingLoopedDamaged = false
    end
end

function PowerGenerator:OnInitialized()
    ScriptActor.OnInitialized(self)

    if Server then
        -- PowerGenerators always belong to the Marine team
        self:SetTeamNumber(kTeam1Index)

        -- This Mixin must be inited inside this OnInitialized() function
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        InitMixin(self, WeldableMixin)

        -- extend relevancy range since the generator affects lights beyond normal range
        self:SetRelevancyDistance(100 + 20)
        self:SetConstructionComplete()
    end
end

function PowerGenerator:GetLightMode()
    return self.lightMode
end

function PowerGenerator:GetTimeOfLightModeChange()
    return self.timeOfLightModeChange
end

function PowerGenerator:SetLightMode(lightMode)
    local time = Shared.GetTime()

    -- Don't change light mode too often
    if self.lightMode ~= lightMode or (not self.timeOfLightModeChange or (time > (self.timeOfLightModeChange + 1.0))) then
        self.lastLightMode = self.lightMode
        self.lightMode = lightMode
        self.timeOfLightModeChange = time
    end
end

function PowerGenerator:GetPowerGeneratorId()
    return self.powerGeneratorId
end

function PowerGenerator:GetCanBeWeldedOverride(player)
    return self:GetHealthScalar() < 1, true
end

function PowerGenerator:GetHealthbarOffset()
    return 0.8
end

function PowerGenerator:GetAttackTime()
    return self.attackTime
end

-- Update light state based on health
function PowerGenerator:UpdateLightMode()
    local healthScalar = self:GetHealthScalar()

    if healthScalar <= 0 then
        self:SetLightMode(kLightMode.NoPower)
    elseif healthScalar < self.kDamagedPercentage then
        self:SetLightMode(kLightMode.LowPower)
    elseif self:GetAttackTime() > 0 then
        self:SetLightMode(kLightMode.Damaged)
    else
        self:SetLightMode(kLightMode.Normal)
    end
end

if Server then
    function PowerGenerator:StopDamagedSound()
        if self.playingLoopedDamaged then
            self:TriggerEffects("powerpoint_damaged_loop_stop")
            self.playingLoopedDamaged = false
        end
    end

    function PowerGenerator:DoDamageLighting()
        local healthScalar = self:GetHealthScalar()
        if healthScalar < self.kDamagedPercentage then
            self:SetLightMode(kLightMode.LowPower)
        else
            self:SetLightMode(kLightMode.Damaged)
        end
        self:AddAttackTime(0.9)
    end

    function PowerGenerator:AddAttackTime(value)
        self.attackTime = Clamp(self.attackTime + value, 0, 10)
    end

    function PowerGenerator:OnTakeDamage(damage, attacker, doer, direction, damageType, preventAlert)
        if damage > 0 then
            -- Handle damage similar to PowerPoint
            self:DoDamageLighting()
            self:PlaySound(kTakeDamageSound)

            local healthScalar = self:GetHealthScalar()
            if healthScalar < self.kDamagedPercentage then
                if not self.playingLoopedDamaged then
                    self:TriggerEffects("powerpoint_damaged_loop")
                    self.playingLoopedDamaged = true
                end
            end
        end
    end

    function PowerGenerator:OnWeldOverride(entity, elapsedTime)
        local welded = false

        -- Calculate repair amount based on welder type
        local repairAmount = 0
        if entity:isa("Welder") then
            repairAmount = kWelderPowerRepairRate * elapsedTime
        elseif entity:isa("MAC") then
            repairAmount = MAC.kRepairHealthPerSecond * elapsedTime
        else
            repairAmount = kBuilderPowerRepairRate * elapsedTime
        end

        welded = (self:AddHealth(repairAmount) > 0)

        if self:GetHealthScalar() > self.kDamagedPercentage then
            self:StopDamagedSound()

            if self:GetLightMode() == kLightMode.LowPower then
                self:SetLightMode(kLightMode.Normal)
            end
        end

        if welded then
            self:AddAttackTime(-0.1)
        end

        return welded
    end

    function PowerGenerator:OnKill(attacker, doer, point, direction)
        ScriptActor.OnKill(self, attacker, doer, point, direction)

        self:StopDamagedSound()
        self:PlaySound(kDestroyedSound)
        self:SetLightMode(kLightMode.NoPower)

        if attacker and attacker:isa("Player") and GetEnemyTeamNumber(self:GetTeamNumber()) == attacker:GetTeamNumber() then
            attacker:AddScore(50) -- Point value for destroying a generator
        end
    end

    function PowerGenerator:OnUpdate(deltaTime)
        self:AddAttackTime(-0.1)

        if self:GetLightMode() == kLightMode.Damaged and self:GetAttackTime() == 0 then
            self:SetLightMode(kLightMode.Normal)
        end
    end
end

if Client then
    function PowerGenerator:OnTimedUpdate(deltaTime)
        -- Create visual effects based on light mode
        local lightMode = self:GetLightMode()
        local model = self:GetRenderModel()
        local isAlive = self:GetIsAlive()

        if model then
            if not isAlive then
                model:SetOverrideMaterial(0, PowerGenerator.kDestroyedMaterial)
            elseif lightMode == kLightMode.LowPower then
                model:SetOverrideMaterial(0, PowerGenerator.kCriticalDamageMaterial)
            else
                model:ClearOverrideMaterials()
            end
        end

        -- Create/destroy effects based on light mode
        if lightMode == kLightMode.LowPower and not self.lowPowerEffect and isAlive then
            self.lowPowerEffect = Client.CreateCinematic(RenderScene.Zone_Default)
            self.lowPowerEffect:SetCinematic(kDamagedEffect)
            self.lowPowerEffect:SetRepeatStyle(Cinematic.Repeat_Loop)
            self.lowPowerEffect:SetCoords(self:GetCoords())
        elseif lightMode ~= kLightMode.LowPower and self.lowPowerEffect then
            Client.DestroyCinematic(self.lowPowerEffect)
            self.lowPowerEffect = nil
        end

        if lightMode == kLightMode.NoPower and not self.noPowerEffect and isAlive then
            self.noPowerEffect = Client.CreateCinematic(RenderScene.Zone_Default)
            self.noPowerEffect:SetCinematic(kOfflineEffect)
            self.noPowerEffect:SetRepeatStyle(Cinematic.Repeat_Loop)
            self.noPowerEffect:SetCoords(self:GetCoords())
        elseif lightMode ~= kLightMode.NoPower and self.noPowerEffect then
            Client.DestroyCinematic(self.noPowerEffect)
            self.noPowerEffect = nil
        end

        return true
    end
end

-- This is used specifically for light display, not actual power
function PowerGenerator:GetIsPowering()
    -- Only used for lighting effects
    return self:GetIsAlive() and self.lightMode ~= kLightMode.NoPower
end

Shared.LinkClassToMap("PowerGenerator", PowerGenerator.kMapName, networkVars)