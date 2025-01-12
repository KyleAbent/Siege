-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/AIBlackboard.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

if not Server then return end

Script.Load("lua/IterableDict.lua")
Script.Load("lua/UnorderedSet.lua")

local kTrackableMapEntities = set
{
    "TechPoint",
    "ResourcePoint",
    "PowerPoint",
    "Location"
}

local function GetShouldEntityBeTracked(ent)
    PROFILE("GetShouldEntityBeTracked")
    -- Doesn't include things like SporeCloud, as those don't require "visibility". Will just be a on-the-spot check.
    local isValidTarget = HasMixin(ent, "Live") and HasMixin(ent, "Team")
    local isValidMapEnt = ent and kTrackableMapEntities[ent:GetClassName()]
    return isValidTarget or isValidMapEnt
end

local function GetTeamCanSeeEntity(teamIndex, ent)
    PROFILE("GetTeamCanSeeEntity")
    
    local targetEntTeamIndex = HasMixin(ent, "Team") and ent:GetTeamNumber() or nil
    if not targetEntTeamIndex then 
        return true
    else
        return 
            teamIndex == targetEntTeamIndex or
            not HasMixin(ent, "LOS") or ent:GetIsSighted() or
            (HasMixin(ent, "ParasiteAble") and ent:GetIsParasited())
    end
    
end

local kBlackboardInstances = {}
function GetAIBlackboardForTeam(teamIndex)
    PROFILE("GetAIBlackboardForTeam")
    assert(teamIndex == kTeam1Index or teamIndex == kTeam2Index, "Invalid team index for AIBlackboard. Must be kTeam1Index or kTeam2Index")
    
    if not kBlackboardInstances[teamIndex] then
        kBlackboardInstances[teamIndex] = AIBlackboard()
        kBlackboardInstances[teamIndex]:Initialize(teamIndex)
    end
    return kBlackboardInstances[teamIndex]
end

function UpdateAIBlackboardsForEntity(entity)
    PROFILE("UpdateAIBlackboardsForEntity")
    assert(entity and GetShouldEntityBeTracked(entity))
    
    local className = entity:GetClassName()
    local isMapEntity = className and kTrackableMapEntities[className]
    local entTeamIndex = HasMixin(entity, "Team") and entity:GetTeamNumber() or nil

    if isMapEntity then
        GetAIBlackboardForTeam(kTeam1Index):AddEntity(entity)
        GetAIBlackboardForTeam(kTeam2Index):AddEntity(entity)
    elseif entTeamIndex then
        GetAIBlackboardForTeam(entTeamIndex):AddEntity(entity)
        local enemyTeamNumber = GetEnemyTeamNumber(entTeamIndex)
        if GetTeamCanSeeEntity(enemyTeamNumber) then
            GetAIBlackboardForTeam(enemyTeamNumber):AddEntity(entity)
        else
            GetAIBlackboardForTeam(enemyTeamNumber):RemoveEntity(entity)
        end
    end
    
end

class "AIBlackboard"

function AIBlackboard:Initialize(teamIndex)
    PROFILE("AIBlackboard:Initialize")
    assert(teamIndex == kTeam1Index or teamIndex == kTeam2Index, "Invalid team number for AIBlackboard. Must be kTeam1Index or kTeam2Index")
    
    self.teamIndex = teamIndex
    self.visibleEntsByClass = IterableDict()
    
end 

function AIBlackboard:AddEntity(ent)
    PROFILE("AIBlackboard:AddEntity")
    
    local entClassname = ent:GetClassName()
    if not self.visibleEntsByClass[entClassname] then
        self.visibleEntsByClass[entClassname] = UnorderedSet()
    end

    self.visibleEntsByClass[entClassname]:Add(ent:GetId())
    
end

function AIBlackboard:RemoveEntity(ent)
    PROFILE("AIBlackboard:RemoveEntity")
    
    local entClassname = ent:GetClassName()
    local classDict = self.visibleEntsByClass[entClassname]
    if classDict then
        classDict:RemoveElement(ent:GetId())
    end
    
end

function AIBlackboard:GetVisibleEntitesByClass(className)
    PROFILE("AIBlackboard:GetVisibleEntitesByClass")
    return self.visibleEntsByClass[className] or {}
end 