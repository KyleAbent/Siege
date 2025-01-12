-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Location.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- Represents a named location in a map, so players can see where they are.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Trigger.lua")

PrecacheAsset("materials/power/powered_decal.surface_shader")
local kPoweredDecalMaterial = PrecacheAsset("materials/power/powered_decal.material")
-- local kUnpoweredDecalMaterial = PrecacheAsset("materials/power/unpowered_decal.material")

class 'Location' (Trigger)

Location.kMapName = "location"

local networkVars =
{
    showOnMinimap = "boolean",
}

Shared.PrecacheString("")

function Location:OnInitialized()

    Trigger.OnInitialized(self)
    
    -- Precache name so we can use string index in entities
    Shared.PrecacheString(self.name)
    
    -- Default to show.
    if self.showOnMinimap == nil then
        self.showOnMinimap = true
    end
    
    self:SetTriggerCollisionEnabled(true)
    
    self:SetPropagate(Entity.Propagate_Always)
    
end

function Location:Reset()

end    

function Location:OnDestroy()

    Trigger.OnDestroy(self)
    
    if Client then
        self:HidePowerStatus()
    end

end

function Location:GetShowOnMinimap()
    return self.showOnMinimap
end

if Server then

    function Location:OnTriggerEntered(entity, triggerEnt)
        ASSERT(self == triggerEnt)
        if entity.SetLocationName then
            --Log("%s enter loc %s ('%s') from '%s'", entity, self, self:GetName(), entity:GetLocationName())
            -- only if we have no location do we set the location here
            -- otherwise we wait until we exit the location to set it
            if not entity:GetLocationEntity() then
                entity:SetLocationName(triggerEnt:GetName())
                entity:SetLocationEntity(self)

                if entity:isa("Player") then
                    local client = entity:GetClient()
                    if client and client:GetIsVirtual() then
                        local brain = client.bot.brain
                        if brain and brain.GetIsExploring then
                            brain:AddVisitedLocation(triggerEnt:GetName())
                        end
                    end
                end
            end
        end
    end
    
    function Location:OnTriggerExited(entity, triggerEnt)
        ASSERT(self == triggerEnt)
        if entity.SetLocationName then
            local enteredLoc = GetLocationForPoint(entity:GetOrigin(), self)
            local name = enteredLoc and enteredLoc:GetName() or ""
            --Log("%s exited location %s('%s'), entered '%s'", entity, self, self:GetName(), name)

            -- If it's a new location group and not a "copy" then update it's staleness.
            if entity:GetLocationName() ~= name then

                if entity:isa("Player") then
                    local client = entity:GetClient()
                    if client and client:GetIsVirtual() then
                        local brain = client.bot.brain
                        if brain and brain.GetIsExploring then
                            local exitedLocation = triggerEnt:GetName()
                            if name ~= exitedLocation and brain:GetLocationVisited(name) then -- For when bots might backtrack when attacking etc
                                brain:ClearVisitedLocation(exitedLocation)
                            else
                                brain:AddVisitedLocation(name)
                            end
                        end
                    end
                end

            end

            entity:SetLocationName(name)
            entity:SetLocationEntity(enteredLoc)
        end

    end
end

-- used for marine commander to show/hide power status in a location
if Client then

    function Location:ShowPowerStatus(powered)

        if not self.powerDecal then
            self.materialLoaded = nil  
        end

        if powered then
        
            if self.materialLoaded ~= "powered" then
            
                if self.powerDecal then
                    Client.DestroyRenderDecal(self.powerDecal)
                    Client.DestroyRenderMaterial(self.powerMaterial)
                end
                
                self.powerDecal = Client.CreateRenderDecal()

                local material = Client.CreateRenderMaterial()
                material:SetMaterial(kPoweredDecalMaterial)
        
                self.powerDecal:SetMaterial(material)
                self.materialLoaded = "powered"
                self.powerMaterial = material
                
            end

        else
            
            if self.powerDecal then
                Client.DestroyRenderDecal(self.powerDecal)
                Client.DestroyRenderMaterial(self.powerMaterial)
                self.powerDecal = nil
                self.powerMaterial = nil
                self.materialLoaded = nil
            end
            
            --[[
            
            if self.materialLoaded ~= "unpowered" then
            
                if self.powerDecal then
                    Client.DestroyRenderDecal(self.powerDecal)
                end
                
                self.powerDecal = Client.CreateRenderDecal()
        
                self.powerDecal:SetMaterial(kUnpoweredDecalMaterial) 
                self.materialLoaded = "unpowered"
            
            end
            
            --]]
            
        end
        
    end

    function Location:HidePowerStatus()

        if self.powerDecal then
            Client.DestroyRenderDecal(self.powerDecal)
            Client.DestroyRenderMaterial(self.powerMaterial)
            self.powerDecal = nil
            self.powerMaterial = nil
        end

    end
    
    function Location:OnUpdateRender()
    
        PROFILE("Location:OnUpdateRender")
        
        local player = Client.GetLocalPlayer()      

        local showPowerStatus = player and player.GetShowPowerIndicator and player:GetShowPowerIndicator()
        local powerPoint

        if showPowerStatus then
            powerPoint = GetPowerPointForLocation(self.name)
            showPowerStatus = powerPoint ~= nil   
        end  
        
        if showPowerStatus then
                
            self:ShowPowerStatus(powerPoint:GetIsPowering())
            if self.powerDecal then
            
                -- TODO: Doesn't need to be updated every frame, only setup on creation.
            
                local coords = self:GetCoords()
                local extents = self.scale * 0.2395
                extents.y = 10
                coords.origin.y = powerPoint:GetOrigin().y - 2
                
                -- Get the origin in the object space of the decal.
                local osOrigin = coords:GetInverse():TransformPoint( powerPoint:GetOrigin() )
                self.powerMaterial:SetParameter("osOrigin", osOrigin)

                self.powerDecal:SetCoords(coords)
                self.powerDecal:SetExtents(extents)
                
            end
            
        else
            self:HidePowerStatus()
        end   
        
    end
    
end

Shared.LinkClassToMap("Location", Location.kMapName, networkVars)


if Client then

local dbg_kLocationGates = {}
local dbg_kEnabledLocationDraw = false


local function TryNudgeFindPoint(point, dist, scans, step)
    assert(point)

    --type check and range clamp
    dist = ( not dist ) and 2 or math.abs(dist)
    scans = ( not scans ) and 1 or math.abs(scans)
    step = ( not step ) and 0 or math.abs(step)

    if not dist then
        dist = 2
    else
        dist = math.abs(dist)
    end

    local samples = {}
    for i = 1, scans do
        local stepDist = dist + step * i

        local nudges =  --CUUUUuuuuubbbbess!
        {
            --NSEW,Up,Down
            Vector(0,0,stepDist),
            Vector(0,0,-stepDist),
            Vector(-stepDist,0,0),
            Vector(stepDist,0,0),
            Vector(0,stepDist,0),
            Vector(0,-stepDist,0),
            
            Vector(-stepDist,stepDist,stepDist),   --Fwd-up-left
            Vector(stepDist,stepDist,stepDist),   --Fwd-up-right
            Vector(-stepDist,stepDist,-stepDist),   --back-up-left
            Vector(stepDist,stepDist,-stepDist),   --back-up-right

            Vector(-stepDist,-stepDist,stepDist),   --Fwd-down-left
            Vector(stepDist,-stepDist,stepDist),   --Fwd-down-right
            Vector(-stepDist,-stepDist,-stepDist),   --back-down-left
            Vector(stepDist,-stepDist,-stepDist),   --back-down-right
        }

        for n = 1, #nudges do
            local samp = Vector(point + nudges[n])
            local v = Pathing.GetClosestPoint(samp)
            if v ~= samp then
                table.insert(samples, v)
            end
        end
    end

    if #samples > 0 then
        --sort by shortest distance to original Point
        table.sort(samples, function(a, b)
            if a and b then
                local aV = Vector(a - point)
                local bV = Vector(b - point)
                return bV:GetLength() > aV:GetLength()
            else
                return a
            end
        end)

        --Print("\n Nudge Samples for [%s]\n%s\n", ToString(point), ToString(samples))
        --[[
        Print("Distance Table:\n")
        for v = 1, #samples do
            Print("\t\t\t [%s]\n", Vector(samples[v] - point):GetLength() )
        end
        --]]

        return samples[1]   --nearest
    end
    
    return point    --fail-over
end

-------------------------------------------------

local _lastDebugUpdateTime = 0
local kDebugVisUpdateRate = 0.15


Event.Hook("Console_dbg_locgates", function()
    Print("\n-------------------------------------------------\n")
    Print("Generating Location gateways...")

    if not Shared.GetTestsEnabled() then
        Shared.ConsoleCommand("tests 1")
        Shared.ConsoleCommand("spectate")
        Shared.ConsoleCommand("nav_debug")
    end

    if dbg_kEnabledLocationDraw then
    --ensure disabled while rebilding data
        dbg_kEnabledLocationDraw = false
    end

    --reset on each call
    dbg_kLocationGates = {}
    dbg_kLocationGates["named_centroid"] = {}       --centroid of all unique Named Locations (by group) as aggregate
    dbg_kLocationGates["named_gates"] = {}          
    dbg_kLocationGates["named_origins"] = {}        --Origins of all Locations sharing X name

    local locations = GetLocations()
    assert(#locations > 0, "|ERROR|: No Location entities in map")

    local namedLocs = {}
    
    --Build unique name list, for sorting/lookup later
    for i = 1, #locations do
        if not table.icontains( namedLocs, locations[i]:GetName() ) then
            table.insert( namedLocs, locations[i]:GetName() )
        end
    end

    --We build a list that denotes the Center of all collective
    --Named location entity volumes. The ensures points for sampling
    --Location to Location are always within each _gameplay_ Location
    for i = 1, #namedLocs do
        local name = namedLocs[i]
        
        local locs = {}
        for t = 1, #locations do
            if locations[t]:GetName() == name then
                table.insert(locs, locations[t])
            end
        end

        local tmpCent = Vector(0,0,0)
        for c = 1, #locs do
            local org = locs[c]:GetOrigin()
            tmpCent.x = tmpCent.x + org.x
            tmpCent.y = 0.0    --tmpCent.y + org.y  --Note: some Location volumes have ABSURD heights, normalize them
            tmpCent.z = tmpCent.z + org.z
        end

        --Note: this is mean'd, so it will skew towards density
        local namedCenter = Vector(0,0,0)
        namedCenter.x = tmpCent.x / #locs
        namedCenter.y = tmpCent.y / #locs
        namedCenter.z = tmpCent.z / #locs

        --Note: this can potentially throw gameCenter into another Location
        local gameCenter = TryNudgeFindPoint(namedCenter, 0.1, 250, 0.15)  --transform to playable space, ideally. But this is not a gaurantee...
        if gameCenter == namedCenter then
            Print("\t\t |INFO|: Location[%s] centroid not clost to nav-mesh", name)
        end

        gameCenter.y = gameCenter.y + 0.25  --tiny offset to nudge above floors (usually)

        Print("\t [%s] centered at: (%s, %s, %s)", name, gameCenter.x, gameCenter.y, gameCenter.z)

        if not dbg_kLocationGates["named_centroid"][name] then
            dbg_kLocationGates["named_centroid"][name] = Vector(gameCenter) --copy to new memory
        end
    end

    local kGateYOffset = 0.75
    local function CreateGateway( label, point )    --TODO Add routine to either run traces, offset, center in X bounds...whatever
        assert(label)
        assert(point)
        if not dbg_kLocationGates["named_gates"][label] then
            dbg_kLocationGates["named_gates"][label] = {}
        end
        point.y = point.y + kGateYOffset
        table.insert( dbg_kLocationGates["named_gates"][label], point )
    end

    --Now that we have centroid for all named Locations (grouped), we can
    --process them in sets to find their intersection points, thus earmarking
    --the "gateways" between Locations

    for name, cent in pairs(dbg_kLocationGates["named_centroid"]) do        --MEH  ...damn pairs() ...iterdicts?

        local otherRoids = {}
        for otherName, otherCent in pairs(dbg_kLocationGates["named_centroid"]) do
            if otherName ~= name then
                table.insert(otherRoids, otherCent)
            end
        end

        table.sort( otherRoids, function(a, b)
            if a and b then
                local aV = Vector(a - cent)
                local bV = Vector(b - cent)
                return bV:GetLength() > aV:GetLength()
            else
                return a
            end
        end)

        --Let's ggooooo!
        for i = 1, #otherRoids do
            local path = PointArray()
            Pathing.GetPathPoints( cent, otherRoids[i], path )
            local locPath = {}
            for t = 2, #path do --skip first, same as start
                table.insert(locPath, path[t])
            end

            --Smooth path for more resolution
            SmoothPathPoints(locPath, 0.25, 320)    --TODO tune dist/steps (maybe by minmap extents size as scalar?)

            for p = 1, #locPath do     --?? Force to grid per point?
                local loc = GetLocationForPoint( locPath[p] )
                if not loc or not loc.GetName then
                    Print("\t\t |WARN|  Pathing point did not return a Location: [%s]", ToString(locPath[p]))
                end

                if loc and loc.GetName and loc:GetName() ~= name then
                --we _just_ crossed into a differently named Location, time to dazzle shit up and bail
                    CreateGateway( name, locPath[p] )
                    Print("\t Created Location Gateway Point at [%s]", ToString(locPath[p]))
                    goto GATEWAY_MARKED
                end
            end

            ::GATEWAY_MARKED::
        end

    end

--FIXME Below is a transformation step, but this turns it to a simple point in space, and effectively breaks 
--all associated with Location -> Gate. Need something that records Gate.Connection = { Name, Name }  ...ALWAYS only in pairs ofc (I think)
    --[[
    local tmpGates = {}

    local function FindPreferredCenter(p)
        local traceDist = 10
        local adjVec = Vector()
        
        --we don't need position in world, so much as center of gateway point (per Locations intersections)
        local traceUp = Shared.TraceRay( p, Vector(0, traceDist, 0), CollisionRep.Default, PhysicsMask.Movement, EntityFilterAll() )
        local traceDown = Shared.TraceRay( p, Vector(0, -traceDist, 0), CollisionRep.Default, PhysicsMask.Movement, EntityFilterAll() )
        local traceLeft = Shared.TraceRay( p, Vector(-traceDist, 0, 0), CollisionRep.Default, PhysicsMask.Movement, EntityFilterAll() )
        local traceRight = Shared.TraceRay( p, Vector(traceDist, 0, 0), CollisionRep.Default, PhysicsMask.Movement, EntityFilterAll() )

        VectorCopy(p, adjVec)
        if traceUp.fraction < 1 then
            adjVec = adjVec - traceUp.endPoint
        end
        if traceDown.fraction < 1 then
            adjVec = adjVec - traceDown.endPoint
        end
        if traceLeft.fraction < 1 then
            adjVec = adjVec - traceLeft.endPoint
        end
        if traceRight.fraction < 1 then
            adjVec = adjVec - traceRight.endPoint
        end
        
        return adjVec
    end

    for locName, gates in pairs(dbg_kLocationGates["named_gates"]) do
        for c = 1, #gates do    --pop
            tmpGates[locName] = Vector(0,0,0)
            VectorCopy( gates[c], tmpGates[locName] )
            break
        end
    end

    
    for locName, gates in pairs(dbg_kLocationGates["named_gates"]) do   --EHHHH...

        local tmpCent = Vector(0,0,0)
        for c = 1, #gates do
            tmpCent.x = tmpCent.x + gates[c].x
            tmpCent.y = tmpCent.y + gates[c].y
            tmpCent.z = tmpCent.z + gates[c].z
        end

        local cent = Vector(0,0,0)
        cent.x = tmpCent.x / #gates
        cent.y = tmpCent.y / #gates
        cent.z = tmpCent.z / #gates

        --make sure we're back "on-grid"
        local finalGate = TryNudgeFindPoint( cent, 0.2, 96, 0.1 )

        tmpGates[locName] = Vector(0,0,0)
        VectorCopy( finalGate, tmpGates[locName] )
    end
    

    --update main cache tables
    dbg_kLocationGates["named_gates"] = {}
    for name, gate in pairs(tmpGates) do
        dbg_kLocationGates["named_gates"][name] = Vector(0,0,0)
        VectorCopy( gate, dbg_kLocationGates["named_gates"][name] )
    end
    tmpGates = nil

    --TODO Not loop over gates, and perform refinement / placement step(s)
    --   Check for placement, center in "doorway" as much as possible
    for name, gate in pairs(dbg_kLocationGates["named_gates"]) do
        Print("\nFinalized Gateway Points:\n\t\t %s at [%s]", name, ToString(gate))
    end
    --]]

    Print("\n")
    if not dbg_kEnabledLocationDraw then
    --auto-enable debug visualization update
        Print("\n\t**  auto-enabled debug vis  **\n")
        _lastDebugUpdateTime = 0
        dbg_kEnabledLocationDraw = true
    end

end)

local kDebugVisDist = 28
local function UpdateLocationGatewaysDebugVis(deltaTime) --nice name, eh?  :|
    
    local time = Shared.GetTime()
    if _lastDebugUpdateTime + kDebugVisUpdateRate > time then
        return
    end

    local player = Client.GetLocalPlayer()

    if player then
    --since Debug draw is ABSURDLY slow...like really, really, REALLY fucking slow...
    --clamp all draws to a vis-dist

        local playerPos = player:GetOrigin()
        
        for name, cent in pairs(dbg_kLocationGates["named_centroid"]) do    --meh, IterDict?
            local lCoord = Coords()
            lCoord.origin = cent
            lCoord.xAxis = Vector(1,0,0)
            lCoord.yAxis = Vector(0,1,0)
            lCoord.zAxis = Vector(0,0,1)
            DebugDrawAxes( lCoord, lCoord.origin, 5, 0.125, 5)
        end
        

        for locLabel, gates in pairs(dbg_kLocationGates["named_gates"]) do    --meh, IterDict?
            for g = 1, #gates do    --TODO Add Location (from->to?) world-text
                if gates[g] then    --BLLLEEEHHH....
                    local camDist = Vector(playerPos - gates[g]):GetLength()
                    if camDist <= kDebugVisDist then
                        local gCoords = Coords()
                        gCoords.origin = gates[g]
                        gCoords.xAxis = Vector(1,0,0)
                        gCoords.yAxis = Vector(0,1,0)
                        gCoords.zAxis = Vector(0,0,1)
                        DrawCoords( gCoords, true )
                    end
                end
            end
        end


    --Note: only applies when gate-point reduction steps done, comment out otherwise
        --[[
        for locLabel, gate in pairs(dbg_kLocationGates["named_gates"]) do
            local gCoords = Coords()
            gCoords.origin = gate
            gCoords.xAxis = Vector(1,0,0)
            gCoords.yAxis = Vector(0,1,0)
            gCoords.zAxis = Vector(0,0,1)
            DrawCoords( gCoords, true )
        end
        --]]

    end

end

Event.Hook("UpdateClient", function(deltaTime)
    if dbg_kEnabledLocationDraw then
        UpdateLocationGatewaysDebugVis(deltaTime)
    end
end)


end --If-Client