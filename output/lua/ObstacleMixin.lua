-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ObstacleMixin.lua
--
-- Created by: Dushan Leska (dushan@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/PathingUtility.lua")

ObstacleMixin = CreateMixin(ObstacleMixin)
ObstacleMixin.type = "Obstacle"

gAllObstacles = { }

ObstacleMixin.expectedMixins =
{
    Extents = "Required for obstacle radius."
}

ObstacleMixin.optionalCallbacks =
{
    GetResetsPathing = "Pathing entities will recalculate their path when this obstacle is added / removed."
}

local PathingUtility_GetIsPathingMeshInitialized = GetIsPathingMeshInitialized

-- technically it would be most correct to reset all entities in the world
-- but practically, entities which implemented GetResetsPathing are of temporary nature and used for blocking,
-- and unless units travel <range> faster than those temporary entities lifetime, there is no reason to change this
local function InformEntitiesInRange(self, range)

    for _, pathEnt in ipairs(GetEntitiesWithMixinWithinRange("Pathing", self:GetOrigin(), range)) do
        pathEnt:OnObstacleChanged()
    end

end

function RemoveAllObstacles()
    for _, obstacle in ipairs(gAllObstacles) do
        obstacle:RemoveFromMesh()
    end
end

function ObstacleMixin:__initmixin()
    
    PROFILE("ObstacleMixin:__initmixin")
    
    self.obstacleId = -1
end

-- most classes call SetModel(modelName) in OnCreate or at least in OnInitialized, so the correct extents
-- will already be set once ObstacleMixin:OnInitialized is being called
function ObstacleMixin:OnInitialized()
    self:AddToMesh()
end

function ObstacleMixin:OnDestroy()
    self:RemoveFromMesh()
end

-- obstacle mixin requires extents mixin, so this will be called after extents have been updated correctly
function ObstacleMixin:OnModelChanged()

    self:RemoveFromMesh()
    self:AddToMesh()

end

function ObstacleMixin:AddToMesh()

    if PathingUtility_GetIsPathingMeshInitialized() then

        if self.obstacleId ~= -1 then
            Pathing.RemoveObstacle(self.obstacleId)
            table.removevalue(gAllObstacles, self)
        end

        local position, radius, height = self:_GetPathingInfo()
        self.obstacleId = Pathing.AddObstacle(position, radius, height)

        if self.obstacleId ~= -1 then

            table.insert(gAllObstacles, self)
            if self.GetResetsPathing and self:GetResetsPathing() then
                InformEntitiesInRange(self, 25)
            end

        end

    end

end

function ObstacleMixin:RemoveFromMesh()

    if self.obstacleId ~= -1 then

        Pathing.RemoveObstacle(self.obstacleId)
        self.obstacleId = -1
        table.removevalue(gAllObstacles, self)

        if self.GetResetsPathing and self:GetResetsPathing() then
            InformEntitiesInRange(self, 25)
        end

    end
end

function ObstacleMixin:GetObstacleId()
    return self.obstacleId
end

function ObstacleMixin:_GetPathingInfo()

    local position = self:GetOrigin() + Vector(0, -100, 0)
    local radius = LookupTechData(self:GetTechId(), kTechDataObstacleRadius, 1.0)
    local height = 1000.0

    return position, radius, height

end

local kDebugObstacleRadius = false

if Client then

    function ObstacleMixin:OnUpdateRender()

        if not kDebugObstacleRadius then return end

        --TODO Refactor data-lookup out od OnUpdateRender, BIG data dip for a func called per-rendered-frame
        local radius = LookupTechData(self:GetTechId(), kTechDataObstacleRadius, nil)
        local color = Color(0, 1, 0)
        if not radius then
            color = Color(1, 0, 0)
            radius = 1
        end

        DebugCircle(self:GetOrigin(), radius, Vector(0, 1, 0), 0, color.r, color.g, color.b, 1, true)

    end

    Event.Hook("Console_debug_obstacles", function()

        if not Shared.GetTestsEnabled() then
            Log("Tests must be enabled! Disabled just in case.")
            kDebugObstacleRadius = false
            return
        end

        kDebugObstacleRadius = not kDebugObstacleRadius
        Log("Obstacle Radius Debugging Enabled. (Red means it's using default)")

    end)

end

