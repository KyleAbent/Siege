-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ConstructMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

PrecacheAsset("cinematics/vfx_materials/build.surface_shader")

ConstructMixin = CreateMixin( ConstructMixin )
ConstructMixin.type = "Construct"

local kBuildMaterial = PrecacheAsset("cinematics/vfx_materials/build.material")

local kBuildEffectsInterval = 1

ConstructMixin.networkVars =
{
    -- 0-1 scalar representing build completion time. Since we use this to blend
    -- animations, it must be interpolated for the animations to appear smooth
    -- on the client.
    buildFraction           = "interpolated float (0 to 1 by 0.01)",
    
    -- true if structure finished building
    constructionComplete    = "boolean",

    -- Show different material when under construction
    underConstruction       = "boolean"
    
}

ConstructMixin.expectedMixins =
{
    Live = "ConstructMixin manipulates the health when construction progresses."
}

ConstructMixin.expectedCallbacks = 
{
}

ConstructMixin.optionalCallbacks = 
{
    OnConstruct = "Called whenever construction progress changes.",
    OnConstructionComplete = "Called whenever construction is completes.",
    GetCanBeUsedConstructed = "Return true when this entity has a use function when constructed.",
    GetAddConstructHealth = "Return false to prevent adding health when constructing.",
    GetStartingHealthScalar = "Return the scalar value for the percent of max Health/Armor on structure spawn",
    AllowConstructionComplete = "Return false to prevent the building from being completed",
}


function ConstructMixin:__initmixin()
    
    PROFILE("ConstructMixin:__initmixin")
    
    -- used for client side building effect
    self.underConstruction = false

    self.timeLastConstruct = 0
    self.timeOfNextBuildWeldEffects = 0
    self.buildTime = 0
    self.buildFraction = 0
    self.timeOfLastHealSpray = 0
    
    -- Structures start with a percentage of their full health and gain more as they're built.
    if self.startsBuilt then

        self:SetHealth( self:GetMaxHealth() )
        self:SetArmor( self:GetMaxArmor() )

    else

        local startingHealthScalar = kStartHealthScalar
        if self.GetStartingHealthScalar then
            startingHealthScalar = self:GetStartingHealthScalar()
        end

        self:SetHealth( self:GetMaxHealth() * startingHealthScalar )
        self:SetArmor( self:GetMaxArmor() * startingHealthScalar )

        self.startingConstructHealthScalar = startingHealthScalar

        -- if we didn't start built, record a placed event
        -- Skip placed events for power nodes (because they're level entities)
        if Server then
            self.notifyOnPlaced = true
        end

    end

    -- using a timed callback so we only run OnConstruct till construction completion
    self:AddTimedCallback(ConstructMixin.OnConstructUpdate, 0)
    
    self.startsBuilt  = false
    
end

local function CreateBuildEffect(self)

    if not self.buildMaterial then
        
        local model = self:GetRenderModel()
        if model then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial(kBuildMaterial)
            model:AddMaterial(material)
            self.buildMaterial = material
        
        end
        
    end    
    
end

local function RemoveBuildEffect(self)

    if self.buildMaterial then
      
        local model = self:GetRenderModel()  
        local material = self.buildMaterial
        model:RemoveMaterial(material)
        Client.DestroyRenderMaterial(material)
        self.buildMaterial = nil
                    
    end            

end

if Server then

    function ConstructMixin:OnConstructUpdate(deltaTime)

        local effectTimeout = Shared.GetTime() - self.timeLastConstruct > 0.65
        self.underConstruction = not self:GetIsBuilt() and not effectTimeout

        -- Only Alien structures auto build.
        -- Update build fraction every tick to be smooth.
        if not self:GetIsBuilt() and GetIsAlienUnit(self) then

            if not self.GetCanAutoBuild or self:GetCanAutoBuild() then

                local multiplier = self.hasDrifterEnzyme and kDrifterBuildRate or kAutoBuildRate
                multiplier = multiplier * ( (HasMixin(self, "Catalyst") and self:GetIsCatalysted()) and kNutrientMistAutobuildMultiplier or 1 )

                if self.GetAutoBuildRateMultiplier then
                    multiplier = multiplier * self:GetAutoBuildRateMultiplier()
                end

                self:Construct(deltaTime * multiplier)

            end

        end

        if self.timeDrifterConstructEnds then

            if self.timeDrifterConstructEnds <= Shared.GetTime() then

                self.hasDrifterEnzyme = false
                self.timeDrifterConstructEnds = nil

            end

        end

        -- record this structure being placed (has to be in this function to have the correct origin)
        if self.notifyOnPlaced and not self.constructionComplete then
            self.notifyOnPlaced = false
            StatsUI_AddExportBuilding(self:GetTeamNumber(),
                self.GetTechId and self:GetTechId(),
                self:GetId(),
                self:GetOrigin(),
                StatsUI_kLifecycle.Placed,
                false)
        end

        -- respect the cheat here; sometimes the cheat breaks due to things relying on it NOT being built until after a frame
        if GetGamerules():GetAutobuild() then
            self:SetConstructionComplete()
        end

        if self.underConstruction or not self.constructionComplete then
            return kUpdateIntervalFull
        end

        -- stop running once we are fully constructed
        return false


    end

end -- Server


if Client then

function ConstructMixin:OnConstructUpdate(deltaTime)

    if GetIsMarineUnit(self) then
        if self.underConstruction then
            CreateBuildEffect(self)
        else
            RemoveBuildEffect(self)
        end
        if self.underConstruction or not self.constructionComplete then
            return kUpdateIntervalLow
        end
    end
    
    return false
    
end

end  -- Client


if Server then

    function ConstructMixin:OnKill()

        local extraInfo
        if self:isa("Hive") and self:GetIsBuilt() then
            extraInfo = {name = "biomass", value = self:GetTeam():GetBioMassLevel()-self:GetBioMassLevel()}
        end

        -- Killed structure
        StatsUI_AddExportBuilding(self:GetTeamNumber(),
                self.GetTechId and self:GetTechId(),
                self:GetId(),
                self:GetOrigin(),
                StatsUI_kLifecycle.Destroyed,
                self:GetIsBuilt(),
                extraInfo)

        if not self:GetIsBuilt() then
        
            local techTree = self:GetTeam():GetTechTree()
            local techNode = techTree:GetTechNode(self:GetTechId())
            
            if techNode then
                techNode:SetResearchProgress(0)
                techTree:SetTechNodeChanged(techNode, "researchProgress = 0")
            end 
            
        end
        
    end
    
end

function ConstructMixin:ModifyHeal(healTable)

    if not self:GetIsBuilt() then
    
        local maxFraction = self.startingConstructHealthScalar + (1 - self.startingConstructHealthScalar) * self.buildFraction
        local maxHealth = self:GetMaxHealth() * maxFraction + self:GetMaxArmor() * maxFraction
        local health = self:GetHealth() + self:GetArmor()
        
        healTable.health = Clamp(maxHealth - health, 0, healTable.health) 
    
    end

end

function ConstructMixin:ResetConstructionStatus()

    self.buildTime = 0
    self.buildFraction = 0
    self.constructionComplete = false
    
end

function ConstructMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("ConstructMixin:OnUpdateAnimationInput")    
    modelMixin:SetAnimationInput("built", self.constructionComplete)
    modelMixin:SetAnimationInput("active", self.constructionComplete) -- TODO: remove this and adjust animation graphs
    
end

function ConstructMixin:OnUpdatePoseParameters()

    self:SetPoseParam("grow", self.buildFraction)
    
end

--
-- Add health to structure as it builds.
--
local function AddBuildHealth(self, scalar)

    -- Add health according to build time.
    if scalar > 0 then
    
        local maxHealth = self:GetMaxHealth()
        self:AddHealth(scalar * (1 - self.startingConstructHealthScalar) * maxHealth, false, false, true)
        
    end
    
end

--
-- Add health to structure as it builds.
--
local function AddBuildArmor(self, scalar)

    -- Add health according to build time.
    if scalar > 0 then
    
        local maxArmor = self:GetMaxArmor()
        self:SetArmor(self:GetArmor() + scalar * (1 - self.startingConstructHealthScalar) * maxArmor, true)
        
    end
    
end

--
-- Build structure by elapsedTime amount and play construction sounds. Pass custom construction sound if desired,
-- otherwise use Gorge build sound or Marine sparking build sounds. Returns two values - whether the construct
-- action was successful and if enough time has elapsed so a construction AV effect should be played.
--
function ConstructMixin:Construct(elapsedTime, builder)

    local success = false
    local playAV = false
    
    if not self.constructionComplete and (not HasMixin(self, "Live") or self:GetIsAlive()) then
        
        if builder and builder.OnConstructTarget then
            builder:OnConstructTarget(self)
        end
        
        if Server then

            if not self.lastBuildFractionTechUpdate then
                self.lastBuildFractionTechUpdate = self.buildFraction
            end
            
            local techTree = self:GetTeam():GetTechTree()
            local techNode = techTree:GetTechNode(self:GetTechId())

            local modifier = (self:GetTeamType() == kMarineTeamType and GetIsPointOnInfestation(self:GetOrigin())) and kInfestationBuildModifier or 1
            local startBuildFraction = self.buildFraction
            local newBuildTime = self.buildTime + elapsedTime * modifier
            local timeToComplete = self:GetTotalConstructionTime()           
            
            if newBuildTime >= timeToComplete then

                if not self.AllowConstructionComplete or self:AllowConstructionComplete(builder) then
                    
                    self:SetConstructionComplete(builder)

                    if techNode then
                        techNode:SetResearchProgress(1)
                        techTree:SetTechNodeChanged(techNode, "researchProgress = 1")
                    end
                    
                else
                    
                    self.buildTime = timeToComplete
                    self.oldBuildFraction = self.buildFraction
                    self.buildFraction = 1

                    if not self.GetAddConstructHealth or self:GetAddConstructHealth() then
                        local scalar = self.buildFraction - startBuildFraction
                        AddBuildHealth(self, scalar)
                        AddBuildArmor(self, scalar)
                    end

                    if self.oldBuildFraction ~= self.buildFraction then

                        if self.OnConstruct then
                            self:OnConstruct(builder, self.buildFraction, self.oldBuildFraction)
                        end

                    end
                    
                end
            else
            
                if self.buildTime <= self.timeOfNextBuildWeldEffects and newBuildTime >= self.timeOfNextBuildWeldEffects then
                
                    playAV = true
                    self.timeOfNextBuildWeldEffects = newBuildTime + kBuildEffectsInterval
                    
                end
                
                self.timeLastConstruct = Shared.GetTime()
                self.underConstruction = true
                
                self.buildTime = newBuildTime
                self.oldBuildFraction = self.buildFraction
                self.buildFraction = math.max(math.min((self.buildTime / timeToComplete), 1), 0)
                
                if techNode and (self.buildFraction - self.lastBuildFractionTechUpdate) >= 0.05 then
                
                    techNode:SetResearchProgress(self.buildFraction)
                    techTree:SetTechNodeChanged(techNode, string.format("researchProgress = %.2f", self.buildFraction))
                    self.lastBuildFractionTechUpdate = self.buildFraction
                    
                end
                
                if not self.GetAddConstructHealth or self:GetAddConstructHealth() then
                
                    local scalar = self.buildFraction - startBuildFraction
                    AddBuildHealth(self, scalar)
                    AddBuildArmor(self, scalar)
                
                end
                
                if self.oldBuildFraction ~= self.buildFraction then
                
                    if self.OnConstruct then
                        self:OnConstruct(builder, self.buildFraction, self.oldBuildFraction)
                    end
                    
                end
                
            end
        
        end
        
        success = true
        
    end
    
    if playAV then

        local builderClassName = builder and builder:GetClassName()    
        self:TriggerEffects("construct", {classname = self:GetClassName(), doer = builderClassName, isalien = GetIsAlienUnit(self)})
        
    end

    -- Handle Stats
    if Server then

        if success then
            local steamId = builder and builder.GetSteamId and builder:GetSteamId()
            if steamId then
                StatsUI_AddBuildTime(steamId, elapsedTime, builder:GetTeamNumber())
            end
        end
    end
    
    return success, playAV
    
end

function ConstructMixin:GetCanBeUsedConstructed(byPlayer)
    return false
end

function ConstructMixin:GetCanBeUsed(player, useSuccessTable)

    if self:GetIsBuilt() and not self:GetCanBeUsedConstructed(player) then
        useSuccessTable.useSuccess = false
    end
    
end

function ConstructMixin:SetConstructionComplete(builder)

    -- Construction cannot resurrect the dead.
    if self:GetIsAlive() then
    
        local wasComplete = self.constructionComplete
        self.constructionComplete = true
        
        AddBuildHealth(self, 1 - self.buildFraction)
        AddBuildArmor(self, 1 - self.buildFraction)
        
        self.buildFraction = 1

        if wasComplete ~= self.constructionComplete then
            self:OnConstructionComplete(builder)
        end
        
    end
    
end


function ConstructMixin:GetCanConstruct(constructor)

    if self.GetCanConstructOverride then
        return self:GetCanConstructOverride(constructor)
    end
    
    -- Check if we're on infestation
    -- Doing the origin-based check may be expensive, but this is only done sparsely. And better than tracking infestation all the time.
    if LookupTechData(self:GetTechId(), kTechDataNotOnInfestation) and GetIsPointOnInfestation(self:GetOrigin()) then
        return false
    end
    
    return not self:GetIsBuilt() and GetAreFriends(self, constructor) and self:GetIsAlive() and
           (not constructor or constructor:isa("Marine") or constructor:isa("Gorge") or constructor:isa("MAC"))
    
end

function ConstructMixin:OnUse(player, elapsedTime, useSuccessTable)

    local used = false

    if not GetIsAlienUnit(self) and self:GetCanConstruct(player) then        

        -- Always build by set amount of time, for AV reasons
        -- Calling code will put weapon away we return true
		local constructInterval = 0
		
		local activeWeapon = player:GetActiveWeapon()
		if activeWeapon and activeWeapon:GetMapName() == Builder.kMapName then
			constructInterval = elapsedTime
		end
		
        local success, playAV = self:Construct(constructInterval, player)
		
		if success then
			used = true
		end
                
    end
    
    useSuccessTable.useSuccess = useSuccessTable.useSuccess or used
    
end

function ConstructMixin:RefreshDrifterConstruct()

    self.timeDrifterConstructEnds = Shared.GetTime() + 0.3
    self.hasDrifterEnzyme = true

end

function ConstructMixin:OnHealSpray(gorge)

    if not gorge:isa("Gorge") then
        return
    end

    if GetIsAlienUnit(self) and GetAreFriends(self, gorge) and not self:GetIsBuilt() then

        if self.GetHealSprayBuildAllowed and not self:GetHealSprayBuildAllowed() then
            return
        end

        local currentTime = Shared.GetTime()
        
        -- Multiple Gorges scale non-linearly 
        local timePassed = Clamp((currentTime - self.timeOfLastHealSpray), 0, kMaxBuildTimePerHealSpray)
        local constructTimeForSpray = math.min(kMinBuildTimePerHealSpray + timePassed, kMaxBuildTimePerHealSpray)
        
        self:Construct(constructTimeForSpray, gorge)
        
        self.timeOfLastHealSpray = currentTime
        
    end

end

function ConstructMixin:GetIsBuilt()
    return self.constructionComplete
end

function ConstructMixin:OnConstructionComplete(builder)

    local team = HasMixin(self, "Team") and self:GetTeam()
    
    if team then

        if self.GetCompleteAlertId then
            team:TriggerAlert(self:GetCompleteAlertId(), self)
        elseif GetIsMarineUnit(self) then

            if builder and builder:isa("MAC") then
                team:TriggerAlert(kTechId.MACAlertConstructionComplete, self)
            else
                team:TriggerAlert(kTechId.MarineAlertConstructionComplete, self)
            end
            
        end

        team:OnConstructionComplete(self)

    end     

    self:TriggerEffects("construction_complete")

    -- Record stats.
    if Server then

        -- Built structure
        StatsUI_AddExportBuilding(self:GetTeamNumber(),
            self.GetTechId and self:GetTechId(),
            self:GetId(),
            self:GetOrigin(),
            StatsUI_kLifecycle.Built,
            true)

        if self:isa("ResourceTower") then

            StatsUI_AddRTStat(self:GetTeamNumber(), true, false)

        elseif self.GetClassName and StatsUI_GetBuildingLogged(self:GetClassName()) then

            StatsUI_AddTechStat(self:GetTeamNumber(), self.GetTechId and self:GetTechId(), true, false, false)
            StatsUI_AddBuildingStat(self:GetTeamNumber(), self.GetTechId and self:GetTechId(), false)

        elseif self.GetClassName and not StatsUI_GetBuildingBlockedFromLog(self:GetClassName()) then

            StatsUI_AddBuildingStat(self:GetTeamNumber(), self.GetTechId and self:GetTechId(), false)
        end
    end
end    

function ConstructMixin:GetBuiltFraction()
    return self.buildFraction
end

function ConstructMixin:GetTotalConstructionTime()
    return LookupTechData(self:GetTechId(), kTechDataBuildTime, kDefaultBuildTime)
end

if Server then

    function ConstructMixin:Reset()

        if self.startsBuilt then
            self:SetConstructionComplete()
        end
        
    end

    function ConstructMixin:OnInitialized()

        self.startsBuilt = GetAndCheckBoolean(self.startsBuilt, "startsBuilt", false)

        if (self.startsBuilt and not self:GetIsBuilt()) then
            self:SetConstructionComplete()
        end
        
    end

end

function ConstructMixin:GetEffectParams(tableParams)

    tableParams[kEffectFilterBuilt] = self:GetIsBuilt()
        
end
