-- ======= Copyright (c), Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ScenarioHandler.lua
--
--    Created by:   Mats Olsson (mats.olsson@matsotech.se)
--    Modified by:  Brock Gillespie (brock@naturalselection2.com)
--
--
-- The scenario handler is used to save and load fixed sets of entities. It is intended to be used
-- used for various testing purposes (mostly performance, but also balance and bug testing)
-- 
-- Saving:    scenesave "name"  -  Mapname is auto-included in the save file path
-- Loading:   sceneload "name"  -  Mapname is auto-included in the file path loading attempt
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScenarioHandler_Commands.lua")



class "ScenarioHandler"

ScenarioHandler.kStartTag = "--- SCENARIO START ---"
ScenarioHandler.kEndTag = "--- SCENARIO END ---"

local kSceneFileExtension = ".scn"

ScenarioHandler.kLoadPath = { "config://scenarios/${map}", }

function ScenarioHandler:Init()
    
    -- Will go through all entities and the first one to match will use the given entity handler
    -- Some specialized entity handlers for those that need extra care when loading.
    -- Just in case a player is evolving; we skip embryos. Eggs are also problematic, so we skip them.
    self.handlers = 
    {
        TeamStartHandler():Init("TeamData"),

        CystHandler():Init("Cyst",kAlienTeamType),
        
        PowerPointHandler():Init("PowerPoint", kMarineTeamType),

        OrientedEntityHandler():Init("MAC", kMarineTeamType),
        OrientedEntityHandler():Init("Drifter", kAlienTeamType),
        OrientedEntityHandler():Init("ARC",kMarineTeamType),
        OrientedEntityHandler():Init("Jetpack",kMarineTeamType),
        OrientedEntityHandler():Init("Exosuit",kMarineTeamType),    

        --FIXME All of below needs to exclude Rifle held by Clients
        OrientedEntityHandler():Init("Welder",kMarineTeamType),
        OrientedEntityHandler():Init("Rifle",kMarineTeamType),
        OrientedEntityHandler():Init("Shotgun",kMarineTeamType),
        OrientedEntityHandler():Init("Flamethrower",kMarineTeamType),
        OrientedEntityHandler():Init("GrenadeLauncher",kMarineTeamType),
        OrientedEntityHandler():Init("HeavyMachineGun",kMarineTeamType),
        OrientedEntityHandler():Init("LayMines",kMarineTeamType),   --Inventory item
        OrientedEntityHandler():Init("Mine",kMarineTeamType),   --Deployed mines
                
        OrientedEntityHandler():Init("CommandStation",kMarineTeamType),
        OrientedEntityHandler():Init("InfantryPortal",kMarineTeamType),
        OrientedEntityHandler():Init("ArmsLab",kMarineTeamType),
        OrientedEntityHandler():Init("Armory",kMarineTeamType),
        OrientedEntityHandler():Init("Sentry",kMarineTeamType),
        OrientedEntityHandler():Init("SentryBattery",kMarineTeamType),
        OrientedEntityHandler():Init("PrototypeLab",kMarineTeamType),
        OrientedEntityHandler():Init("RoboticsFactory",kMarineTeamType),
        OrientedEntityHandler():Init("Observatory",kMarineTeamType),
        OrientedEntityHandler():Init("Extractor",kMarineTeamType),
        OrientedEntityHandler():Init("PhaseGate",kMarineTeamType),
        
        OrientedEntityHandler():Init("Hive",kAlienTeamType),
        OrientedEntityHandler():Init("Whip",kAlienTeamType),
        OrientedEntityHandler():Init("Crag",kAlienTeamType),
        OrientedEntityHandler():Init("Shade",kAlienTeamType),
        OrientedEntityHandler():Init("Shift",kAlienTeamType),
        OrientedEntityHandler():Init("Veil",kAlienTeamType),
        OrientedEntityHandler():Init("Spur",kAlienTeamType),
        OrientedEntityHandler():Init("Shell",kAlienTeamType),
        OrientedEntityHandler():Init("Clog",kAlienTeamType),    --FIXME This will NOT force update of Clog attachments states! (e.g. Hydra attached to a clog, etc.)
        OrientedEntityHandler():Init("Hydra",kAlienTeamType),
    --TODO Correctly handle Gorge toys
        --OrientedEntityHandler():Init("Web",kAlienTeamType),
        --OrientedEntityHandler():Init("BileMine",kAlienTeamType),
        OrientedEntityHandler():Init("Harvester",kAlienTeamType),
        OrientedEntityHandler():Init("Contamination",kAlienTeamType),
        TunnelEntranceHandler():Init("TunnelEntrance",kAlienTeamType),  --FIXME This MUST deal with Entrace linking, and Tunnel ent creation...probably

        IgnoreEntityHandler():Init("Embryo"),
        --IgnoreEntityHandler():Init("Egg", true), 
        --Add Lifeform Egg-Types
    }

    return self
end


function ScenarioHandler:LookupHandler(cname)
    
    for _,handler in ipairs(self.handlers) do
        if handler:Matches(cname) then
            return handler
        end
    end
    
    return nil
    
end

--
-- Save the current scenario
-- This just dumps formatted strings for all structures and non-building-owned Cysts that allows
-- the Load() method to easily reconstruct them
-- The data is written to the server log. The user should just cut out the chunk of the log containing the
-- scenario and put in on a webserver
--
function ScenarioHandler:Save(sceneName)
    assert(sceneName, "Error: No SceneName specified")

    local sceneData = ""

    Shared.Message(ScenarioHandler.kStartTag)
    sceneData = ScenarioHandler.kStartTag .. "\n"

    Shared.Message(string.format("TeamData|1|%s", GetGamerules():GetTeam1():GetInitialTechPoint():GetLocationName()))
    Shared.Message(string.format("TeamData|2|%s", GetGamerules():GetTeam2():GetInitialTechPoint():GetLocationName()))

    sceneData = sceneData .. string.format("TeamData|1|%s", GetGamerules():GetTeam1():GetInitialTechPoint():GetLocationName()) .. "\n"
    sceneData = sceneData .. string.format("TeamData|2|%s", GetGamerules():GetTeam2():GetInitialTechPoint():GetLocationName()) .. "\n"

    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("Entity")) do

        --Skip all objects that are currently parented to a Player (e.g. Weapons, etc.)
        if entity.GetParent then
            local parent = entity:GetParent()
            if parent and parent:isa("Player") then
                goto CONT
            end
        end

        local cname = entity:GetClassName()
        local handler = self:LookupHandler(cname)

        local accepted = handler and handler:Accept(entity)

        if accepted then
            sceneData = sceneData .. string.format("%s|%s", cname, handler:Save(entity)) .. "\n"
            Shared.Message( string.format("%s|%s", cname, handler:Save(entity)) )
        end

        ::CONT::
    end

    --TODO Add full TechTree state storing...somehow
    ----Note: for above to be done, we'd need a per-team formating block to denote structure and start-end ...kinda like XML
    ---   ???? Just do pure-json str?

    sceneData = sceneData .. ScenarioHandler.kEndTag .. "\n"

    Shared.Message(ScenarioHandler.kEndTag)

    local mapName = Shared.GetMapName()
    local fileName = "config://scenarios/" .. mapName .. "/" .. sceneName .. kSceneFileExtension

    local openedFile = io.open(fileName, "w+")
    if openedFile then
        openedFile:write( sceneData )
        io.close(openedFile)
    end
end


--
-- Load the given scenario. If url is non-nil, look for it in that directory
-- otherwise look for it by going through the root-path
--
function ScenarioHandler:LoadScenario(name)
    ScenarioLoader():Load(self, ScenarioHandler.kLoadPath, name)
end

function ScenarioHandler:Load(data)

    -- with random start added, we can't trust that anything already existing can be in the right place,
    -- so we destroy all entities that belongs to saveable classes and then recreate the whole scenario.
    self:DestroySaveableEntities()
    self:LoadSaveableEntities(data)
end

function ScenarioHandler:DestroySaveableEntities()
    local entityList = Shared.GetEntitiesWithClassname("Entity")
    for index, entity in ientitylist(entityList) do
        if entity:isa("Infestation") then
            DestroyEntity(entity)
        else
            local handler = self:LookupHandler(entity:GetClassName())
            if handler then
                handler:Destroy(entity)
            end
        end
    end
end

function ScenarioHandler:LoadSaveableEntities(data) 
    local startTagFound, endTagFound = false, false
    data = string.gsub(data, "\r", "") -- remove any carrage returns (WINDOOOOOWS!)
    local lines = data:gmatch("[^\n]+")
    -- load in two stages; use the second stage to resolve references to other entities
    local createdEntities = {}
    for line in lines do
        if line == ScenarioHandler.kStartTag then
            startTagFound = true
        elseif line == ScenarioHandler.kEndTag then
            endTagFound = true
            break
        else 
            if startTagFound then
                local args = line:gmatch("[^|]+")
                local cname = args()
                local handler = self:LookupHandler(cname)
                if handler then 
                    local created = handler:Load(args, cname)
                    if created then
                        table.insert(createdEntities, created)
                    end
                end
            end
        end
    end
    -- Resolve stage
    for _,entity in ipairs(createdEntities) do
        local handler = self:LookupHandler(entity:GetClassName())
        handler:Resolve(entity)
        Log("Loaded %s", entity)
    end
    
    -- update the infestations masks as otherwise whips will unroot and stuff will take damage
    UpdateInfestationMasks()
    
    Shared.Message("END LOAD")
end



--
-- Loading scenarios is a bit complex, as we may try loading from websites in the path, and doing
-- Shared.SendHTTPRequest() is done in its own thread.
--
-- So this class takes care of searching through all the roots for the given file
--
class "ScenarioLoader"

function ScenarioLoader:Load(handler, path, name)
    self.handler = handler
    self.path = path
    self.pathIndex = 0    
    self.name = name 
    self:LoadNext()
end

function ScenarioLoader:LoadNext()
    self.pathIndex = self.pathIndex + 1
    if self.pathIndex > #self.path then
        Log("Unable to find scenario %s", self.name)
    else
        self:LookIn(self.path[self.pathIndex], self.name)
    end
end

--
-- Look in the given root for the named scenario. Returns a table containing
-- "path" and "data" if a scenario file is found.
--
function ScenarioLoader:LookIn(root, name)
    -- substitute any "${map}" with the current base mapname (ie, without any ns2_ prefix)
    local mapname = Shared.GetMapName()
    -- strip any "ns2_"  from the mapname
    mapname = string.gsub(mapname, "ns2_", "")
    -- all scenarios must be in .scn files - strip it away if the user wrote it
    name = string.gsub(name, ".scn", "")
    local path = string.gsub(root, "${map}", mapname) .. "/" .. name .. ".scn"
    if string.find(path, "http:") == 1 then
        -- load from the web
        local loadFunction = function(data)
            self:LoadData(path, data)
        end
        Shared.SendHTTPRequest(path, "GET", loadFunction)
    else
        local file = io.open(path)
        local data
        if file then
            data = file:read("*all")
            io.close(file)
        end
        self:LoadData(path,data)
    end
end

function ScenarioLoader:LoadData(path, data)
    if data and string.find(data, ScenarioHandler.kStartTag) then
        Log("LOAD from %s\n", path)
        self.handler:Load(data)
    else
        Log("Unable to load %s", path)
        self:LoadNext()
    end
end



class "ScenarioEntityHandler"

function ScenarioEntityHandler:Init(name, teamType)
    self.handlerClassName = name
    self.teamType = teamType
    return self
end


function ScenarioEntityHandler:Matches(entityClassName)
    return classisa(entityClassName, self.handlerClassName)
end

function ScenarioEntityHandler:GetTeamType(entityClassName)
    if self.teamType then
        return self.teamType
    end
    --otherwise, get the teamType from check GetIsAlienStructure
    local cls = _G[entityClassName]
    if cls.GetIsAlienStructure then
        return cls.GetIsAlienStructure() and kAlienTeamType or kMarineTeamType
    end
    Log("Unable to find team for %s", entityClassName)
    return nil 
end

-- return true if this entity should be accepted for saving
function ScenarioEntityHandler:Accept(entity)
    -- we need to be able to get a teamtype for it
    return self:GetTeamType(entity:GetClassName()) ~= nil
end

function ScenarioEntityHandler:Resolve(entity)
    -- default do nothing
end

function ScenarioEntityHandler:WriteVector(vec)
    return string.format("%f,%f,%f", vec.x, vec.y, vec.z)
end

function ScenarioEntityHandler:ReadVector(text)
    local p = text:gmatch("[^, ]+")
    local x,y,z = tonumber(p()),tonumber(p()),tonumber(p())
    return Vector(x,y,z)
end

function ScenarioEntityHandler:ReadNumber(text)
    return tonumber(text)
end

function ScenarioEntityHandler:WriteAngles(angles)
    return string.format("%f,%f,%f", angles.pitch, angles.yaw, angles.roll)
end

function ScenarioEntityHandler:ReadAngles(text)
    local p = text:gmatch("[^, ]+")
    local pitch,yaw,roll = tonumber(p()),tonumber(p()),tonumber(p())
    return Angles(pitch,yaw,roll)
end

--TODO Need some serialized json (or similar) that encodes Entity specific properties (e.g. isBuilt, healthFraction, etc.)
----Ideally, a Mixin parser could be used to read/write this data into JSON format.

--
-- destroy the given entity before loading other entities in
--
-- In its own class just in case there is something extra that needs to be
-- done for particular classes
--
function ScenarioEntityHandler:Destroy(entity)
    DestroyEntity(entity)
    if entity.ClearAttached then
        -- for some reason, ClearAttached is NOT called from OnDestroy, only from OnKill. May be a bug?
        entity:ClearAttached()
    end
end

--
-- Oriented entity handlers have an origin and an angles
--
class "OrientedEntityHandler" (ScenarioEntityHandler)

function OrientedEntityHandler:Save(entity)
    -- re-offset the extra spawn height added to it... otherwise our hives will stick up in the roof, and all other things will float
    -- 5cm off the ground..
    local spawnOffset = LookupTechData(entity:GetTechId(), kTechDataSpawnHeightOffset, 0.05)    --FIXME This needs per-type set (weapons fall through floor, etc.)
    local origin = entity:GetOrigin() - Vector(0, spawnOffset, 0)
    return self:WriteVector(origin) .. "|" .. self:WriteAngles(entity:GetAngles()) --.. "|" .. self:WriteTypeExtra(entity)
end

function OrientedEntityHandler:Load(args, classname)
    local origin = self:ReadVector(args())
    local angles = self:ReadAngles(args())
    --local extra = self:ReadExtras(args()) --FIXME We NEED to be able to store ent-type specific properties in order to Ensure "valid" (i.e. As Placed) states
    --If above fixme isn't dealt with, then Blueprints in scenes will never be an option, or health values, or Exosuit types (Gun vs Rail), etc, etc.
    --[[
    McG: I think to do this, we'll have to use Mixin lookup tables, and "reflection" per class definition (BLEH).
    Otherwise, we'll never know if an object has health, or build %, etc.
    Also, in addition to Mixin parsers, we'll need special-case ones, per Class-type (i.e. Exosuit types, or Tunnel Enter/Exit nodes and state, etc.)
    --]]

    -- Log("For %s(%s), team %s at %s, %s", classname, kTechId[classname], self:GetTeamType(classname), origin, angles)
    local entity = self:Create(classname, origin)
    
    if entity then
        entity:SetAngles(angles)
    end
    
    --TODO Add Mixin parser/handlers (of 'extras' data)

    --TODO Add special-case (e.g. Tunnel Entrance vs Exits, or Exosuit types, etc.)
    
    return entity
end

function OrientedEntityHandler:Resolve(entity)      --FIXME This should be a bit more stateful ...e.g. being able to save/load marine blueprints would be quite handy
    ScenarioEntityHandler.Resolve(self, entity)

    -- if we can complete the construction, do so
    if HasMixin(entity, "Construct") then
        entity:SetConstructionComplete()
    end
    
    if HasMixin(entity, "Infestation") then
        entity:SetInfestationFullyGrown()
    end
    
    -- fix to spread out the target acquisition for sentries; randomize lastTargetAcquisitionTime
    if entity:isa("Sentry") then
        -- buildtime means that we need to add a hefty offset to timeOLT
        entity.timeOfLastTargetAcquisition = Shared.GetTime() + 5 + math.random()
    end

    if entity:isa("Drifter") or entity:isa("MAC") then
        -- *sigh* - positioning an entity in its first OnUpdate? Really?
        entity.justSpawned = false
    end
    
end

function OrientedEntityHandler:Create(entityClassName, position)
    local techId = entityClassName == "TunnelEntrance" and kTechId["Tunnel"] or kTechId[entityClassName]    --FIXME Tunnels have Entrance and Exit IDs...ffs
    return CreateEntityForTeam( techId, position, self:GetTeamType(entityClassName), nil )
end 


--
-- Special case PowerPoints - need to setup powerState, so we save them normally but never
-- create them; instead looking them up by the position
--
class "PowerPointHandler" (OrientedEntityHandler)

function PowerPointHandler:Create(entityClassName, position)
    -- Sometimes the map changes, so
    for _,pp in ipairs(GetEntitiesWithinRange("PowerPoint", position, 8)) do
        return pp
    end
    Log("Unable to find any PowerPoint near %s", position)
    return nil
end 

-- save powerState
function PowerPointHandler:Save(entity)
    return string.format("%s|%s", OrientedEntityHandler.Save(self, entity), entity.powerState)
end

function PowerPointHandler:Load(args, classname)
    local pp = OrientedEntityHandler.Load(self, args, classname)
    if pp then
    local v = self:ReadNumber(args())
    pp:SetInternalPowerState(v)
    if v == PowerPoint.kPowerState.socketed then
        pp:SetConstructionComplete()
        end
    end
    return pp
end

function PowerPointHandler:Destroy(entity)
    -- do nothing - we don't create powerpoints
end

--
-- Special case TunnelEntrances - they need to save ownerClientId (with is a steam userid)
--
class "TunnelEntranceHandler" (OrientedEntityHandler)

function TunnelEntranceHandler:Save(tunneNode)  --can be entrance OR exit
    return string.format(
        "%s|%s|%s", 
        OrientedEntityHandler.Save(self, tunneNode), 
        tunneNode.ownerClientId
    )
end

function TunnelEntranceHandler:Load(args, classname)    --FIXME Need to read TechId Enter/Exit
    local tunnelEntrance = OrientedEntityHandler.Load(self, args, classname)
    tunnelEntrance.ownerClientId = self:ReadNumber(args())
    return tunnelEntrance
end

--
-- Special case Cysts. They have a parent and needs to initalize the track
--
class "CystHandler" (OrientedEntityHandler)

-- use the LOCATION of the parent to identify it across saves/loads
function CystHandler:Save(entity)
    local parent = Shared.GetEntity(entity.parentId)
    -- use 0,0,0 for unconnected cysts
    local parentLoc = parent and parent:GetOrigin() or Vector(0,0,0)
    return string.format("%s|%s", OrientedEntityHandler.Save(self, entity), self:WriteVector(parentLoc))
end

-- read off and save the parent id until the resolve phase
function CystHandler:Load(args, classname)
    local cyst = OrientedEntityHandler.Load(self, args, classname)
    cyst.savedParentLoc = self:ReadVector(args())
    return cyst
end

-- resolve the parent and make a track from it to us
function CystHandler:Resolve(cyst)
    OrientedEntityHandler.Resolve(self, cyst)

    local parent
    if cyst.savedParentLoc:GetLength() ~= 0 then
        local targets = GetEntitiesWithinRange("Entity", cyst.savedParentLoc, 0.01)
        local numTargets = #targets

        -- Filter out anything that's not a valid parent for a cyst (could be map blips, etc.)
        for i = 1, numTargets do
        
            local target = targets[i]
            if target:isa("Hive") or target:isa("Cyst") then
                parent = target
            end
            
        end
    end    
    if parent == nil then
        return
    end

    -- remove the variable
    cyst.savedParentLoc = nil
    
    local isReachable = CreateBetweenEntities(cyst, parent)
    if isReachable then
        cyst:SetCystParent(parent)
    end
    
end

class "IgnoreEntityHandler" (ScenarioEntityHandler) 

function IgnoreEntityHandler:Init(name, destroy)
    self.destroy = destroy
    return ScenarioEntityHandler.Init(self, name)
end

function IgnoreEntityHandler:Accept() 
    return false
end

function IgnoreEntityHandler:Destroy(entity)
    if self.destroy then
        ScenarioEntityHandler.Destroy(self, entity)
    end
end

class "TeamStartHandler" (ScenarioEntityHandler) 

function TeamStartHandler:Init(name)
    return ScenarioEntityHandler.Init(self, name)
end

function TeamStartHandler:Accept() 
    return false
end

function TeamStartHandler:Destroy(entity)
    -- ignore
end

function TeamStartHandler:Matches(entityClassName)
    return entityClassName == "TeamData"
end

function TeamStartHandler:Load(args, classname)
    local teamNum = self:ReadNumber(args())
    local locationName = args()
    local techPoint
    for _, entity in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
        local location = GetLocationForPoint(entity:GetOrigin())
        local locationNameEnt = location and location:GetName() or ""
        if locationNameEnt == locationName then
            techPoint = entity 
            break
        end
    end
    
    if not techPoint then
        Log("No techpoint found for location '%s'", locationName) 
    end

    local team =  teamNum == 1 and GetGamerules():GetTeam1() or GetGamerules():GetTeam2()
    team.initialTechPointId = techPoint:GetId()
    return nil -- we don't actually create an entity, so return nil
end

-- create the singleton instance
ScenarioHandler.instance = ScenarioHandler():Init()