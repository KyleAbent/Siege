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





------------------------------------------------------


--------------------------------
end//CreateCommands



