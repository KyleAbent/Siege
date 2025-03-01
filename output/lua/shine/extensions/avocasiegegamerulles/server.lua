--Kyle 'Avoca' Abent

Plugin.Version = "1.0"
------------------------------------------------------------
function Plugin:Initialise()
self.Enabled = true
self:CreateCommands()
kgameStartTime = 0
return true
end

------------------------------------------------------------
function Plugin:OnNotifyAlienCommander(who) 
  local commander = who:GetTeam():GetCommander()
    if commander ~= nil then
        local client = commander:GetClient()
         self:NotifyOne(client, "To Build a Hive on this AlienTechPoint, Select the AlienTechPoint then click the AlienTechPointHive TechButton to build", true)
         self:NotifyOne(client, "AlienTechPoint doesn't allow traditional Hive Building by Drag and Drop due to technical difficulties :P.", true)
    end
end
Shine.Hook.SetupClassHook( "AlienTechPoint", "NotifyAlienCommander", "OnNotifyAlienCommander", "PassivePost" ) 
------------------------------------------------------------

function Plugin:NotifyOne( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[Siege 2022]",  0, 255, 0, String, Format, ... )
end
function Plugin:NotifyHiveLifeInsurance( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[Hive Life Insurance ]",  0, 255, 0, String, Format, ... )
end
function Plugin:NotifyGorilla( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[GorillaGlue]",  0, 255, 0, String, Format, ... )
end
------------------------------------------------------------
function Plugin:NotifyTimer( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[Timer]",  0, 255, 0, String, Format, ... )
end
------------------------------------------------------------
function Plugin:NotifyGiveRes( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[GiveRes]",  255, 0, 0, String, Format, ... )
end
------------------------------------------------------------
function Plugin:NotifyGeneric( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[Admin Abuse]",  0, 255, 0, String, Format, ... )
end
------------------------------------------------------------
function Plugin:NotifyAutoComm( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[AutoComm]",  255, 0, 0, String, Format, ... )
end
------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
function Plugin:CreateCommands()

local function Pres( Client, Targets, Number )
    for i = 1, #Targets do
        local Player = Targets[ i ]:GetControllingPlayer()
        if not Player:isa("ReadyRoomTeam")  and Player:isa("Alien") or Player:isa("Marine") then
            Player:SetResources(Number)
           	Shine:CommandNotify( Client, "set %s's resources to %s", true,
			Player:GetName() or "<unknown>", Number )  
        end
     end
end

local PresCommand = self:BindCommand( "sh_pres", "pres", Pres)
PresCommand:AddParam{ Type = "clients" }
PresCommand:AddParam{ Type = "number" }
PresCommand:Help( "sh_pres <player> <number> sets player's pres to the number desired." )
------------------------------------------------------------

local function  AddScore( Client, Targets, Number )
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
            if HasMixin(Player, "Scoring") then
            Player:AddScore(Number, 0, false)
           	 Shine:CommandNotify( Client, "%s's score increased by %s", true,
			 Player:GetName() or "<unknown>", Number )  
             end
     end
end

local AddScoreCommand = self:BindCommand( "sh_addscore", "addscore", AddScore)
AddScoreCommand:AddParam{ Type = "clients" }
AddScoreCommand:AddParam{ Type = "number" }
AddScoreCommand:Help( "sh_addscore <player> <number> adds number to players score" )
------------------------------------------------------------

local function RandomRR( Client )
        local rrPlayers = GetGamerules():GetTeam(kTeamReadyRoom):GetPlayers()
        for p = #rrPlayers, 1, -1 do
            JoinRandomTeam(rrPlayers[p])
        end
        Shine:CommandNotify( Client, "randomized the readyroom", true)  
end
local RandomRRCommand = self:BindCommand( "sh_randomrr", "randomrr", RandomRR )
RandomRRCommand:Help( "randomize's the ready room.") 
------------------------------------------------------------
local function Stalemate( Client )
local Gamerules = GetGamerules()
if not Gamerules then return end
Gamerules:DrawGame()
end 

local StalemateCommand = self:BindCommand( "sh_stalemate", "stalemate", Stalemate )
StalemateCommand:Help( "declares the round a draw." )
------------------------------------------------------------
local function Slap( Client, Targets, Number )
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
       if Player and Player:GetIsAlive() and not Player:isa("Commander") then
            self:NotifyGeneric( nil, "slapping %s for %s seconds", true, Player:GetName(), Number)
            self:CreateTimer( 13, 1, Number, 
            function () 
                if not Player:GetIsAlive()  and self:TimerExists(13) then self:DestroyTimer( 13 ) return end
                Player:SetVelocity(  Player:GetVelocity() + Vector(math.random(-900,900),math.random(-900,900),math.random(-900,900)  ) )
            end )
        end
    end
end
local SlapCommand = self:BindCommand( "sh_slap", "slap", Slap)
SlapCommand:Help ("sh_slap <player> <time> Slaps the player once per second random strength")
SlapCommand:AddParam{ Type = "clients" }
SlapCommand:AddParam{ Type = "number" }
------------------------------------------------------------
local function MakeExo( Client, Targets ) //make sure team 1 lol
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
        if Player:GetTeamNumber() == 1 and Player:isa("Marine") then
            Player:GiveExo(Player:GetOrigin())    
         end
     end
end
local MakeExoCommand = self:BindCommand( "sh_makeexo", "makeexo", MakeExo )
MakeExoCommand:AddParam{ Type = "clients" }
MakeExoCommand:Help( "<player> if marine then give exo" )
--------------------------------------------------------------------------------
local function Respawn( Client, Targets )
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
	        	Shine:CommandNotify( Client, "respawned %s.", true,
				Player:GetName() or "<unknown>" )  
         Player:GetTeam():ReplaceRespawnPlayer(Player)
                 Player:SetCameraDistance(0)
     end
end
local RespawnCommand = self:BindCommand( "sh_respawn", "respawn", Respawn )
RespawnCommand:AddParam{ Type = "clients" }
RespawnCommand:Help( "<player> respawns said player" )
------------------------------------------------------------
local function Destroy( Client, String  ) 
        local player = Client:GetControllingPlayer()
        for _, entity in ipairs( GetEntitiesWithMixinWithinRange( "Live", player:GetOrigin(), 8 ) ) do
            if string.find(entity:GetMapName(), String)  then
                  self:NotifyGeneric( nil, "destroyed %s in %s", true, entity:GetMapName(), entity:GetLocationName())
                  DestroyEntity(entity)
				  break
             end
         end
end
local DestroyCommand = self:BindCommand( "sh_destroy", "destroy", Destroy )
DestroyCommand:AddParam{ Type = "string" }
DestroyCommand:Help( "Destroy <string> Destroys entity with this name within 8 radius" )
------------------------------------------------------------
local function Give( Client, Targets, String, Number )
    for i = 1, #Targets do
        local Player = Targets[ i ]:GetControllingPlayer()
        if Player and Player:GetIsAlive() and String ~= "alien" and not (Player:isa("Alien") and String == "armory") and not (Player:isa"ReadyRoomTeam" and String == "CommandStation" or String == "Hive") and not Player:isa("Commander") then 
            local teamnum = Number and Number or Player:GetTeamNumber()
            local ent = CreateEntity(String, Player:GetOrigin(), teamnum)  
            if HasMixin(ent, "Construct") then 
             ent:SetConstructionComplete() 
            end
            Shine:CommandNotify( Client, "gave %s an %s", true,
            Player:GetName() or "<unknown>", String )  
        end
    end
end
local GiveCommand = self:BindCommand( "sh_give", "give", Give )
GiveCommand:AddParam{ Type = "clients" }
GiveCommand:AddParam{ Type = "string" }
GiveCommand:AddParam{ Type = "number", Optional = true }
GiveCommand:Help( "<player> Give item to player(s)" )
------------------------------------------------------------
local function OpenBreakableDoors()
           for index, breakabledoor in ientitylist(Shared.GetEntitiesWithClassname("BreakableDoor")) do
               if breakabledoor.health ~= 0 then breakabledoor.health = 0 end 
                end

end
local function Open( Client, String )
local Gamerules = GetGamerules()
     if String == "Front" or String == "front" then
       GetTimer().FrontTimer = 0
     elseif String == "Siege" or String == "siege" then
       GetTimer().SiegeTimer = 0
     elseif String == "Side" or String == "side" then
       GetTimer():OpenSideDoors()
       Shine.ScreenText.End(1) 
     elseif String == "Breakable" or String == "breakable" then
       OpenBreakableDoors()
    end  
  self:NotifyGeneric( nil, "Opened the %s doors", true, String)  
end 

local OpenCommand = self:BindCommand( "sh_open", "open", Open )
OpenCommand:AddParam{ Type = "string" }
OpenCommand:Help( "Opens <type> doors (Front/Siege) (not case sensitive) - timer will still display." )
------------------------------------------------------------
local function BringAll( Client )
    self:NotifyGeneric( nil, "Brought everyone to one locaiton/area", true)
        local Players = Shine.GetAllPlayers() //change to player for bots lol
              for i = 1, #Players do
              local Player = Players[ i ]
                  if Player and not Player:isa("Commander") and not Player:isa("Spectator") then
                       local where = FindFreeSpace(Client:GetControllingPlayer():GetOrigin())
                       Player:SetOrigin(where)
                  end
              end
end

local BringAllCommand = self:BindCommand( "sh_bringall", "bringall", BringAll )
BringAllCommand:Help( "sh_bringall - teleports everyone to the same spot" )
------------------------------------------------------------
//Intended to be Debugging command not for server with players :/ Root access?
local function Go( Client )
    Shared.ConsoleCommand("cheats 1") 
    Shared.ConsoleCommand("sh_forceroundstart") 
    for i = 1, 18 do
        Shared.ConsoleCommand("addbot") 
    end    
    Shared.ConsoleCommand("sh_autocomm") 
end

local BringAllCommand = self:BindCommand( "sh_go", "go", Go )
BringAllCommand:Help( "sh_go - cheats 1 and forceroundstart and add 18 bots" )



----------AutoComm Enable-------------

local function AutoComm( Client, Number )

        if not Number or Number == 1 then
            local bot = Server.CreateEntity(CommanderBot.kMapName)
            bot:Initialize(1, not passive)
            self:NotifyGeneric( nil, "Enabled AutoComm for Marines", true)
        end
        if not Number or Number == 2 then    
            local bot = Server.CreateEntity(CommanderBot.kMapName)
            bot:Initialize(2, not passive)  
            self:NotifyGeneric( nil, "Enabled AutoComm for Aliens", true)
       end
end

local AutoCommCommand = self:BindCommand( "sh_autocomm", "autocomm", AutoComm )
AutoCommCommand:Help( "sh_autocomm 1 or 2 or blank - Marines/Aliens AutoComm or both teams" )
AutoCommCommand:AddParam{ Type = "number", Optional = true }



-------


-- Helper functions to convert Vector and Angles objects to/from tables
local function CDataToTable(cdata)
    if type(cdata) ~= "cdata" then
        return cdata -- Return as is if not a cdata type
    end

    -- Handle Vector objects
    if cdata.x ~= nil and cdata.y ~= nil and cdata.z ~= nil then
        return {
            _type = "Vector",
            x = cdata.x,
            y = cdata.y,
            z = cdata.z
        }
    end

    -- Handle Angles objects - check if it has yaw, pitch, roll
    if cdata.yaw ~= nil or cdata.pitch ~= nil or cdata.roll ~= nil then
        return {
            _type = "Angles",
            yaw = cdata.yaw or 0,
            pitch = cdata.pitch or 0,
            roll = cdata.roll or 0
        }
    end

    -- If we can't identify the specific type, try to convert to a generic table
    local result = {}
    -- Add a marker so we know it was a cdata type
    result._type = "unknown_cdata"

    -- Try to dump whatever properties it might have
    -- This is a best-effort approach - not all cdata can be converted this way
    local success, err = pcall(function()
        -- Try to get any numeric indices
        for i = 0, 10 do  -- arbitrary limit
            pcall(function()
                if cdata[i] ~= nil then
                    result[i] = cdata[i]
                end
            end)
        end

        -- Try some common property names
        local common_props = {"x", "y", "z", "w", "r", "g", "b", "a",
                              "yaw", "pitch", "roll", "value", "id", "type"}
        for _, prop in ipairs(common_props) do
            pcall(function()
                if cdata[prop] ~= nil then
                    result[prop] = cdata[prop]
                end
            end)
        end
    end)

    -- If we couldn't extract any properties, use string representation as a fallback
    if not next(result) or not success then
        -- Convert to string representation as last resort
        result._string = tostring(cdata)
    end

    return result
end

local function TableToCData(tab)
    if type(tab) ~= "table" then
        return tab
    end

    -- Check if this was a Vector
    if tab._type == "Vector" or (tab.x ~= nil and tab.y ~= nil and tab.z ~= nil) then
        return Vector(tab.x, tab.y, tab.z)
    end

    -- Check if this was an Angles object
    if tab._type == "Angles" or (tab.yaw ~= nil or tab.pitch ~= nil or tab.roll ~= nil) then
        return Angles(tab.yaw or 0, tab.pitch or 0, tab.roll or 0)
    end

    -- For unknown types, just return the table
    return tab
end

local function SaveLayout(client, slotNumber)
    -- Get current map name to use in the filename
    local mapName = Shared.GetMapName()
    -- Initialize table to store structure data
    local layoutData = {
        powerPoints = {},
        structures = {},
        mapName = mapName
    }

    -- Use slot number or default to 1
    slotNumber = slotNumber or 1

    -- Save PowerPoint status
    for _, powerPoint in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do
        -- Skip if destroyed
        if powerPoint:GetIsAlive() then
            table.insert(layoutData.powerPoints, {
                location = CDataToTable(powerPoint:GetOrigin()),
                powerState = powerPoint:GetPowerState(),
                isSocketed = powerPoint:GetIsSocketed(),
                isBuilt = powerPoint:GetIsBuilt()
            })
        end
    end

    -- Get all structures with ConstructMixin except excluded types
    local excludedTypes = {
--         "CommandStation",
--         "Hive",
        "TechPoint",
        "ResourcePoint"
    }

    -- Function to check if entity should be excluded
    local function shouldExclude(entity)
        for _, excludedType in ipairs(excludedTypes) do
            if entity:isa(excludedType) then
                return true
            end
        end
        return false
    end

    -- Get all entities that have ConstructMixin
    for _, entity in ientitylist(Shared.GetEntitiesWithTag("Construct")) do
        if not shouldExclude(entity) and entity:GetIsBuilt() then
            -- Store basic info about the structure, converting CData to table
            table.insert(layoutData.structures, {
                className = entity:GetClassName(),
                location = CDataToTable(entity:GetOrigin()),
                angles = CDataToTable(entity:GetAngles()),
                teamNumber = entity:GetTeamNumber()
            })
        end
    end

    -- Create the filename using mapName and slotNumber
    local filename = string.format("config://shine/layouts/%s_%s.json", mapName, slotNumber)

    -- Save the layout data using Shine's JSON file API
    local success = Shine.SaveJSONFile(layoutData, filename)

    if success then
        Shared.Message("Layout saved to " .. filename)
        self:NotifyGeneric(nil, "Layout saved for map %s (slot %s)", true, mapName, slotNumber)
    else
        Shared.Message("Error saving layout to " .. filename)
        self:NotifyGeneric(nil, "Error saving layout!", true)
    end
end

local SaveLayoutCommand = self:BindCommand("sh_savelayout", "savelayout", SaveLayout)
SaveLayoutCommand:Help("Saves the current structure layout for the map")
SaveLayoutCommand:AddParam{ Type = "number", Optional = true }

local function LoadLayout(client, slotNumber)
    local mapName = Shared.GetMapName()
    -- Use slot number or default to 1
    slotNumber = slotNumber or 1

    -- Create the filename using mapName and slotNumber
    local filename = string.format("config://shine/layouts/%s_%s.json", mapName, slotNumber)

    -- Load the layout data using Shine's JSON file API
    local layoutData = Shine.LoadJSONFile(filename)

    if not layoutData then
        self:NotifyGeneric(nil, "No saved layout found for map %s (slot %s)", true, mapName, slotNumber)
        return
    end

    -- Verify this layout is for the current map
    if layoutData.mapName ~= mapName then
        self:NotifyGeneric(nil, "Layout file is for different map!", true)
        return
    end

    -- Make sure game is ready for entity creation
    local gameRules = GetGamerules()
    if not gameRules or not gameRules:GetGameStarted() then
        self:NotifyGeneric(nil, "Game must be started before loading a layout", true)
        return
    end

    -- Option to clear existing structures first (DISABLED by default)
    local shouldClearExisting = false  -- Set to true if you want to clear structures first
    if shouldClearExisting then
        self:NotifyGeneric(nil, "Clearing existing structures...", true)
        local clearedCount = 0
        for _, entity in ientitylist(Shared.GetEntitiesWithTag("Construct")) do
            -- Don't clear critical structures
            if not entity:isa("CommandStation") and not entity:isa("Hive") and
               not entity:isa("TechPoint") and not entity:isa("ResourcePoint") then
                DestroyEntity(entity)
                clearedCount = clearedCount + 1
            end
        end
        self:NotifyGeneric(nil, "Cleared %d existing structures", true, clearedCount)
    end

    -- Success counters for reporting
    local powerPointsCreated = 0
    local structuresCreated = 0
    local powerPointsFailed = 0
    local structuresFailed = 0

    -- First handle PowerPoints
    self:NotifyGeneric(nil, "Setting up power points...", true)
    for _, powerData in ipairs(layoutData.powerPoints or {}) do
        local powerLocation = TableToCData(powerData.location)

        -- Find existing PowerPoint at this location
        local powerPoint = nil
        for _, pp in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do
            if (pp:GetOrigin() - powerLocation):GetLength() < 1 then
                powerPoint = pp
                powerPointsCreated = powerPointsCreated + 1
                self:NotifyGeneric(nil, "Updated existing PowerPoint at location: %.2f, %.2f, %.2f",
                    true, powerLocation.x, powerLocation.y, powerLocation.z)
                break
            end
        end

        if powerPoint then
            -- Set its state
            if powerData.isSocketed and not powerPoint:GetIsSocketed() then
                powerPoint:SocketPowerNode()
            end
            if powerData.isBuilt and not powerPoint:GetIsBuilt() then
                powerPoint:SetConstructionComplete()
            end
        else
            powerPointsFailed = powerPointsFailed + 1
            self:NotifyGeneric(nil, "Could not find PowerPoint at: %.2f, %.2f, %.2f",
                true, powerLocation.x, powerLocation.y, powerLocation.z)
        end
    end

    -- Then spawn other structures
    self:NotifyGeneric(nil, "Creating structures...", true)
    for i, structData in ipairs(layoutData.structures or {}) do
        -- Create fresh Vector objects from the stored data
        local location = Vector(structData.location.x, structData.location.y, structData.location.z)
        local angles = Angles(structData.angles.yaw or 0, structData.angles.pitch or 0, structData.angles.roll or 0)

        -- Check if there's already an entity at this location
        local existingEntity = nil
        for _, entity in ientitylist(Shared.GetEntitiesWithClassname(structData.className)) do
            if (entity:GetOrigin() - location):GetLength() < 1 then
                existingEntity = entity
                break
            end
        end

        if existingEntity then
            -- Entity already exists, update it
            existingEntity:SetAngles(angles)
            structuresCreated = structuresCreated + 1
            self:NotifyGeneric(nil, "Updated existing %s at location: %.2f, %.2f, %.2f",
                true, structData.className, location.x, location.y, location.z)
        else
            -- Try to create a new entity at the exact location
            local entity = CreateEntity(structData.className, Vector(location.x, location.y, location.z), structData.teamNumber)

            if entity then
                entity:SetAngles(angles)
                -- If it has construct mixin, complete construction
                if HasMixin(entity, "Construct") then
                    entity:SetConstructionComplete()
                end
                structuresCreated = structuresCreated + 1
                self:NotifyGeneric(nil, "Created %s at location: %.2f, %.2f, %.2f",
                    true, structData.className, location.x, location.y, location.z)
            else
                structuresFailed = structuresFailed + 1
                self:NotifyGeneric(nil, "Failed to create %s at location: %.2f, %.2f, %.2f",
                    true, structData.className, location.x, location.y, location.z)

                -- Print additional diagnostic info
                Shared.Message(string.format("Creation failure diagnostic info:"))
                Shared.Message(string.format(" - Class: %s", structData.className))
                Shared.Message(string.format(" - Team: %s", structData.teamNumber))
                Shared.Message(string.format(" - Raw location: %s", tostring(location)))
            end
        end

        -- Pause briefly every few entities to avoid overwhelming the server
        if i % 5 == 0 then
            Shared.Message("Created/updated " .. i .. " structures so far...")
        end
    end

    -- Report results
    self:NotifyGeneric(nil, "Layout loaded: %d/%d power points, %d/%d structures created/updated",
        true, powerPointsCreated, powerPointsCreated + powerPointsFailed,
        structuresCreated, structuresCreated + structuresFailed)
end

local LoadLayoutCommand = self:BindCommand("sh_loadlayout", "loadlayout", LoadLayout)
LoadLayoutCommand:Help("Loads the saved structure layout for the current map")
LoadLayoutCommand:AddParam{ Type = "number", Optional = true }



------------------------------------------------------------






------------------------------------------------------


--------------------------------
end//CreateCommands



