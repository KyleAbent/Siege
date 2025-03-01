-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Cyst.lua
--
--    Created by:   Mats Olsson (mats.olsson@matsotech.se)
--
-- A cyst controls and spreads infestation
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
--Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/SpawnBlockMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/CystVariantMixin.lua")

Script.Load("lua/CommAbilities/Alien/EnzymeCloud.lua")
Script.Load("lua/CommAbilities/Alien/Rupture.lua")

class 'Cyst' (ScriptActor)

Cyst.kMaxEncodedPathLength = 30
Cyst.kMapName = "cyst"
Cyst.kModelName = PrecacheAsset("models/alien/cyst/cyst.model")

Cyst.kAnimationGraph = PrecacheAsset("models/alien/cyst/cyst.animation_graph")

Cyst.kEnergyCost = 25
Cyst.kPointValue = 5
-- how fast the impulse moves
Cyst.kImpulseSpeed = 8

Cyst.kThinkInterval = 1 
Cyst.kImpulseColor = Color(1,1,0)
Cyst.kImpulseLightIntensity = 8
local kImpulseLightRadius = 1.5

Cyst.kExtents = Vector(0.2, 0.1, 0.2)

Cyst.kBurstDuration = 3

-- range at which we can be a parent
Cyst.kCystMaxParentRange = kCystMaxParentRange

-- size of infestation patch
Cyst.kInfestationRadius = kInfestationRadius
Cyst.kInfestationGrowthDuration = Cyst.kInfestationRadius / kCystInfestDuration
-- increase the visual redeploy range slightly to avoid network field truncation and other woes accidentally redeploying cysts
Cyst.kRedeployBias = 0.2

-- how many seconds before a fully mature cyst, disconnected, becomes fully immature again.
Cyst.kMaturityLossTime = 15

-- cyst infestation spreads/recedes faster
Cyst.kInfestationRateMultiplier = 3

Cyst.kInfestationGrowRateMultiplier = 6
Cyst.kInfestationRecideRateMultiplier = 3

Cyst.kFlamableDamageMultiplier = kCystFlamableDamageMultiplier

local kEnemyDetectInterval = 0.2

local networkVars =
{

    -- Since cysts don't move, we don't need the fields to be lag compensated
    -- or delta encoded
    m_origin = "position (by 0.05 [], by 0.05 [], by 0.05 [])",
    m_angles = "angles (by 0.1 [], by 10 [], by 0.1 [])",
    
    -- Cysts are never attached to anything, so remove the fields inherited from Entity
    m_attachPoint = "integer (-1 to 0)",
    m_parentId = "integer (-1 to 0)",
    
    -- if we are connected. Note: do NOT use on the server side when calculating reconnects/disconnects,
    -- as the random order of entity update means that you can't trust it to reflect the actual connect/disconnects
    -- used on the client side by the ui to determine connection status for potently cyst building locations
    connected = "boolean",

    --Cysts scale their health based on the distance to the clostest hive
    healthScalar = "float (0 to 1 by 0.01)",

    cloakInfestation = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(PointGiverMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(CystVariantMixin, networkVars)

local cystChainDebug = false
local function CystChainToggleDebug()
    cystChainDebug = not cystChainDebug
    Log("cystChainDebug now " .. tostring(cystChainDebug))
end

local function OnCommandCystBias(distance)
    if not Shared.GetCheatsEnabled() then return end
    Cyst.kRedeployBias = tonumber(distance) or Cyst.kRedeployBias
    Print("Cyst.kRedeployBias: %f", Cyst.kRedeployBias)
end

--
-- To avoid problems with minicysts on walls connection to each other through solid rock,
-- we need to move the start/end points a little bit along the start/end normals
--
local function CreateBetween(trackStart, startNormal, trackEnd, endNormal, startOffset, endOffset)

    trackStart = trackStart + startNormal * 0.01
    trackEnd = trackEnd + endNormal * 0.01
    
    local pathDirection = trackEnd - trackStart
    pathDirection:Normalize()
    
    if startOffset == nil then
        startOffset = 0.1
    end
    
    if endOffset == nil then
        endOffset = 0.1
    end
    
    -- DL: Offset the points a little towards the center point so that we start with a polygon on a nav mesh
    -- that is closest to the start. This is a workaround for edge case where a start polygon is picked on
    -- a tiny island blocked off by an obstacle.
    trackStart = trackStart + pathDirection * startOffset
    trackEnd = trackEnd - pathDirection * endOffset
    
    local points = PointArray()
    local isReachable = Pathing.GetPathPoints(trackStart, trackEnd, points)
    
    if isReachable then
        -- Always include the starting point in this path for convenience
        Pathing.InsertPoint(points, 1, trackStart)
end
    return isReachable, points

end

--
-- Convinience function when creating a path between two entities, submits the y-axis of the entities coords as
-- the normal for use in CreateBetween()
--
function CreateBetweenEntities(srcEntity, endEntity)    
    return CreateBetween(srcEntity:GetOrigin(), srcEntity:GetCoords().yAxis, endEntity:GetOrigin(), endEntity:GetCoords().yAxis)    
end

if Server then
    Script.Load("lua/Cyst_Server.lua")
end

function Cyst:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, FlinchMixin, { kPlayFlinchAnimations = true })
    InitMixin(self, SelectableMixin)
    InitMixin(self, PointGiverMixin)
    --InitMixin(self, AchievementGiverMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, DetectableMixin)
    
    if Server then
    
        InitMixin(self, SpawnBlockMixin)
        self:UpdateIncludeRelevancyMask()
        self.timeLastCystConstruction = 0
        
    elseif Client then
        InitMixin(self, CommanderGlowMixin)
        self.connectedFraction = 1
    end

    self:SetPhysicsCollisionRep(CollisionRep.Move)
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)
    
    self:SetLagCompensated(false)
    
    self.parentId = Entity.invalidId
    
end

function Cyst:OnDestroy()

    if Client then
        
        if self.redeployCircleModel then
        
            Client.DestroyRenderModel(self.redeployCircleModel)
            self.redeployCircleModel = nil
            
        end
        
    end
    
    ScriptActor.OnDestroy(self)
    
end

function Cyst:GetShowSensorBlip()
    return false
end

function Cyst:GetSpawnBlockDuration()
    return 1
end

--
-- A Cyst is redeployable if it is within range of the origin but
-- we ignore the Y distance within some tolerance.
--
local function GetCystIsRedeployable(cyst, origin, bias)
    bias = bias or 0

    local immune = cyst.immuneToRedeploymentTime and Shared.GetTime() <= cyst.immuneToRedeploymentTime
    if cyst:GetDistance(origin) <= (kCystRedeployRange + bias) and not immune then
        if math.abs(cyst:GetOrigin().y - origin.y) < 2 then
            return GetPathDistance(cyst:GetOrigin(), origin) <= (kCystRedeployRange + bias)
    end
    end
    
    return false
    
end

local function DestroyNearbyCysts(self)

    local nearbyCysts = GetEntitiesForTeamWithinRange("Cyst", self:GetTeamNumber(), self:GetOrigin(), kCystRedeployRange)
    for c = 1, #nearbyCysts do
    
        local cyst = nearbyCysts[c]
        if cyst ~= self and GetCystIsRedeployable(cyst, self:GetOrigin()) then
            cyst:Kill()
        end
        
    end
    
end

function Cyst:OnInitialized()

    InitMixin(self, InfestationMixin)
    
    ScriptActor.OnInitialized(self)

    if Server then
    
        -- start out as disconnected; wait for impulse to arrive
        self.connected = true
        
        self.nextUpdate = Shared.GetTime()
        self.impulseActive = false
        self.bursted = false
        self.timeBursted = 0
        self.children = unique_set()
        
        InitMixin(self, SleeperMixin)
        InitMixin(self, StaticTargetMixin)
        
        self:SetModel(Cyst.kModelName, Cyst.kAnimationGraph)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        self.cloakInfestation = false
        self:AddTimedCallback(self.UpdateInfestationCloaking, 0.2)
        self:AddTimedCallback(self.ScanForNearbyEnemy, kEnemyDetectInterval)
        
    elseif Client then    
    
        InitMixin(self, UnitStatusMixin)
        self:AddTimedCallback(Cyst.OnTimedUpdate, 0)
        -- note that even though a Client side cyst does not do OnUpdate, its mixins (cloakable mixin) requires it for
        -- now. If we can change that, then cysts _may_ be able to skip OnUpdate
         
    end   
    
    if Server then
        DestroyNearbyCysts(self)
    end
    
    InitMixin(self, IdleMixin)

    if not Predict then
        InitMixin(self, CystVariantMixin)
        self:ForceCystSkinsUpdate()
    end
    
end

function Cyst:GetPlayIdleSound()
    return self:GetIsBuilt() and self:GetCurrentInfestationRadiusCached() < 1
end

function Cyst:SetImmuneToRedeploymentTime(forTime)
    self.immuneToRedeploymentTime = Shared.GetTime() + forTime
end

function Cyst:GetInfestationGrowthRate()
    return Cyst.kInfestationGrowthDuration
end

function Cyst:GetHealthbarOffset()
    return 0.5
end 

--
-- Infestation never sights nearby enemy players.
--
function Cyst:OverrideCheckVision()
    return false
end

function Cyst:GetIsFlameAble()
    return true
end

function Cyst:GetIsFlameableMultiplier()
    return self.kFlamableDamageMultiplier
end

function Cyst:GetIsCamouflaged()
    return self:GetIsConnected() and self:GetIsBuilt() and not self:GetIsInCombat() and GetHasTech(self, kTechId.ShadeHive)
end

function Cyst:GetCloakInfestation()
    return self.cloakInfestation
end

function Cyst:GetAutoBuildRateMultiplier()
    if GetHasTech(self, kTechId.ShiftHive) then
        return 1.25
    end

    return 1
end

function Cyst:GetMatureMaxHealth()
    return math.max(kMatureCystHealth * self.healthScalar or 0, kMinMatureCystHealth)
end

function Cyst:GetMatureMaxArmor()
    if GetHasTech(self, kTechId.CragHive) then
        return 25
    end

    return kMatureCystArmor

end 

function Cyst:GetMatureMaxEnergy()
    return 0
end

function Cyst:GetCanSleep()
    return true
end    

function Cyst:GetTechButtons(techId)
  
    return  { kTechId.Infestation,  kTechId.None, kTechId.None, kTechId.None,
              kTechId.None, kTechId.None, kTechId.None, kTechId.None }

end

function Cyst:GetInfestationRadius()
    return kInfestationRadius
end

function Cyst:GetInfestationMaxRadius()
    return kInfestationRadius
end

function Cyst:GetCystParentRange()
    return Cyst.kCystMaxParentRange
end  

function Cyst:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Cyst:GetIsConnectedAndAlive()
    return self:GetIsAlive()
end

function Cyst:GetIsConnected()
    return true  -- Always return true
end

-- function Cyst:GetDescription()
--
--     local prePendText = ConditionalValue(self:GetIsConnected(), "", "Unconnected ")
--     return prePendText .. ScriptActor.GetDescription(self)
--
-- end

function Cyst:OnOverrideSpawnInfestation(infestation)

    infestation.maxRadius = kInfestationRadius
    -- New infestation starts partially built, but this allows it to start totally built at start of game
    local radiusPercent = math.max(infestation:GetRadius(), .2)
    infestation:SetRadiusPercent(radiusPercent)
    
end

function Cyst:GetReceivesStructuralDamage()
    return true
end

function Cyst:CanBeBuilt()
    if self:GetIsBuilt() then
        return false
    end
    return true
end

function Cyst:GetCanAutoBuild()
    return self:CanBeBuilt()
end

function Cyst:GetHealSprayBuildAllowed()
    return self:CanBeBuilt()
end


if Client then
    
    -- avoid using OnUpdate for cysts, instead use a variable timed callback
    function Cyst:OnTimedUpdate(deltaTime)
      
      PROFILE("Cyst:OnTimedUpdate")
      if self:GetIsAlive() then
          local animateDirection = self.connected and 1 or -1
          self.connectedFraction = Clamp(self.connectedFraction + animateDirection * deltaTime, 0, self:GetBuiltFraction())      
          if self.connectedFraction > 0 and self.connectedFraction < 1 then
              return kUpdateIntervalAnimation
          end
      end
      return kUpdateIntervalLow
      
    end

end


function MarkPotentialDeployedCysts(ents, origin)

    for i = 1, #ents do
    
        local ent = ents[i]
        if ent:isa("Cyst") and GetCystIsRedeployable(ent, origin, Cyst.kRedeployBias) then
            ent.markAsPotentialRedeploy = true
        end
        
    end
    
end


-- Temporarily don't use "target" attach point
function Cyst:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.2, 0)
end

function Cyst:GetIsHealableOverride()
  return self:GetIsAlive()
end

function Cyst:PerformActivation(techId, position, normal, commander)

    if techId == kTechId.Rupture and self:GetMaturityLevel() == kMaturityLevel.Mature then
    
        CreateEntity(Rupture.kMapName, self:GetOrigin(), self:GetTeamNumber())
        self.bursted = true
        self.timeBursted = Shared.GetTime()
        self:ResetMaturity()
        
        return true, true
        
    end
    
    return false, true
    
end

local function UpdateRedeployCircle(self, display)

    if not self.redeployCircleModel then
    
        self.redeployCircleModel = Client.CreateRenderModel(RenderScene.Zone_Default)
        self.redeployCircleModel:SetModel(Commander.kAlienCircleModelName)
        local coords = Coords.GetLookIn(self:GetOrigin() + Vector(0, kZFightingConstant, 0), Vector.xAxis)
        coords:Scale((kCystRedeployRange + Cyst.kRedeployBias) * 2)
        self.redeployCircleModel:SetCoords(coords)
        
    end
    
    self.redeployCircleModel:SetIsVisible(display)
    
end

function Cyst:OnUpdateRender()

    PROFILE("Cyst:OnUpdateRender")
    
    local model = self:GetRenderModel()
    if model then
    

        model:SetMaterialParameter("connected", self.connectedFraction)
        
        model:SetMaterialParameter("killWarning", self.markAsPotentialRedeploy and 1 or 0)
        
        UpdateRedeployCircle(self, self.markAsPotentialRedeploy or false)
        
        self.markAsPotentialRedeploy = false
        
    end
    
end


function Cyst:SetIncludeRelevancyMask(includeMask)

    includeMask = bit.bor(includeMask, kRelevantToTeam2Commander)    
    ScriptActor.SetIncludeRelevancyMask(self, includeMask)    

end

local kBestLength = 20
local kPointOffset = Vector(0, 0.1, 0)
local kParentSearchRange = 400


local function IsPathable(position)

    local kExtents = Vector(0.4, 0.5, 0.4)
    local noBuild = Pathing.GetIsFlagSet(position, kExtents, Pathing.PolyFlag_NoBuild)
    local walk = Pathing.GetIsFlagSet(position, kExtents, Pathing.PolyFlag_Walk)
    return not noBuild and walk

end


function Cyst:GetCanCatalyzeHeal()
    return true
end

function Cyst:GetInfestationRateMultiplier(growing)
    if not growing then
        return Cyst.kInfestationRecideRateMultiplier
    end

    return Cyst.kInfestationGrowRateMultiplier
end


Shared.LinkClassToMap("Cyst", Cyst.kMapName, networkVars)

Event.Hook("Console_cchain_debug", CystChainToggleDebug)

Event.Hook("Console_cyst_placement_bias", OnCommandCystBias)
