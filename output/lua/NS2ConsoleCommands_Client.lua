-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ConsoleCommands_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Only loaded when game rules are set and propagated to client.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommanderTutorialUtility.lua")

local kOriginCinematic = PrecacheAsset("cinematics/locateorigin.cinematic")
local originCinematic
local propNames

local function OnCommandResetCommanderTutorial()
    CommanderTutorial_ResetAll()
end

Event.Hook("Console_resetcommandertutorial", OnCommandResetCommanderTutorial)

local function OnCommandSelectAndGoto(selectAndGotoMessage)
    PROFILE("ConsoleCommands_Client:OnCommandSelectAndGoto")
    local player = Client.GetLocalPlayer()
    if player and player:isa("Commander") then
    
        local entityId = ParseSelectAndGotoMessage(selectAndGotoMessage)        
        local entity = Shared.GetEntity(entityId)
        if entity ~= nil then
        
            DeselectAllUnits(player:GetTeamNumber(), false, false)
            entity:SetSelected(player:GetTeamNumber(), true, false, false)
            player:SetWorldScrollPosition(entity:GetOrigin().x, entity:GetOrigin().z)
            
        else
            Print("OnCommandSelectAndGoto() - Couldn't goto position of entity %d", entityId)
        end
        
    end
    
end

local function OnCommandSelect(selectMessage)
    PROFILE("ConsoleCommands_Client:OnCommandSelect")
    local player = Client.GetLocalPlayer()
    if player and player:isa("Commander") then
    
        local entityId = ParseSelectAndGotoMessage(selectMessage)        
        local entity = Shared.GetEntity(entityId)
        if entity ~= nil then
        
            DeselectAllUnits(player:GetTeamNumber(), false, false)
            entity:SetSelected(player:GetTeamNumber(), true, false, false)
            
        end
        
    end
    
end

local function OnCommandTraceReticle()
    if Shared.GetCheatsEnabled() then
        Print("Toggling tracereticle cheat.")        
        Client.GetLocalPlayer():ToggleTraceReticle()
    end
end

local function OnCommandTestSentry()

    local player = Client.GetLocalPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        -- Look for nearest sentry and have it show us what it sees
        local sentries = GetEntitiesForTeamWithinRange("Sentry", player:GetTeamNumber(), player:GetOrigin(), 20)    
        for _, sentry in ipairs(sentries) do
            
            local targets = GetEntitiesWithMixinWithinRange("Live", sentry:GetOrigin(), Sentry.kRange)
            for _, target in ipairs(targets) do
            
                if sentry ~= target then
                    GetCanSeeEntity(sentry, target)
                end

            end
        end
        
    end
    
end

local function OnCommandRandomDebug()

    if Shared.GetCheatsEnabled() then
        local newState = not gRandomDebugEnabled
        gRandomDebugEnabled = newState
    end
    
end

local function OnCommandLocation(_)

    local player = Client.GetLocalPlayer()

    local locationName = player:GetLocationName()
    locationName = locationName == "" and "nowhere" or locationName
    Log("You(%s) are in \"%s\", position %s.", player, locationName, player:GetOrigin())
    
end

local function OnCommandChangeGCSettingClient(settingName, newValue)

    if Shared.GetCheatsEnabled() then
    
        if settingName == "setpause" or settingName == "setstepmul" then
            Shared.Message("Changing client GC setting " .. settingName .. " to " .. tostring(newValue))
            collectgarbage(settingName, newValue)
        else
            Shared.Message(settingName .. " is not a valid setting")
        end
        
    end
    
end

local function OnCommandClientEntities(entityType)

    if Shared.GetCheatsEnabled() or Shared.GetTestsEnabled() then
        DumpEntityCounts(entityType)
    end
    
end

local gHealthringsDisabled = false
local function OnCommandHealthRings(state)

    local enabled = state == "true"
    local disabled = state == "false"
    
    if disabled then
        gHealthringsDisabled = true
    elseif enabled then
        gHealthringsDisabled = false
    end    

end

function GetShowHealthRings()
    return not gHealthringsDisabled
end

local function OnCommandResetHelp(helpName)

    if not helpName then
        Client.RemoveOption("help/")
    else
        Client.RemoveOption("help/" .. string.lower(helpName))
    end
    Print("Widget help reset.")
    
end

local function OnConsoleMusic(name)

    if Shared.GetCheatsEnabled() then
        Client.PlayMusic("sound/NS2.fev/" .. name)
    end
    
end

local function OnCommandDebugCommander(vm)

    if Shared.GetCheatsEnabled() then    
        BuildUtility_SetDebug(vm)        
    end
    
end

local function OnCommandDrawDecal(material, scale)

    if Shared.GetCheatsEnabled() then

        local player = Client.GetLocalPlayer()
        if player and material then
        
            -- trace to a surface and draw the decal
            local startPoint = player:GetEyePos()
            local endPoint = startPoint + player:GetViewCoords().zAxis * 100
            local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
            
            if trace.fraction ~= 1 then
            
                local coords = Coords.GetTranslation(trace.endPoint)
                coords.yAxis = trace.normal
                coords.zAxis = coords.yAxis:GetPerpendicular()
                coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
            
                scale = scale and tonumber(scale) or 1.5
                
                Client.CreateTimeLimitedDecal(material, coords, scale)
                Print("created decal %s", ToString(material))
            
            end
        
        else
            Print("usage: drawdecal <materialname> <scale>")        
        end
    
    end

end

local function OnConsoleMapInfo()

    if Client.originalLights ~= nil and Client.lowLightList ~= nil and Client.minimalLightList ~= nil then

        Shared.Message(ToString(#Client.lowLightList + #Client.originalLights + #Client.minimalLightList) .. " Total Lights")
        Shared.Message(ToString("\t" .. #Client.originalLights) .. " High Quality Lights")
        Shared.Message(ToString("\t" .. #Client.lowLightList ) .. " Low Quality Lights")
        Shared.Message(ToString("\t" .. #Client.minimalLightList) .. " Minimal Quality Lights")
    end

    if Client.reflectionProbeList ~= nil then
        Shared.Message(ToString(#Client.reflectionProbeList) ..  " reflection probes")
    end
    if Client.fogMeshVolumeList ~= nil then
        Shared.Message(string.format("%d fog mesh volumes", #Client.fogMeshVolumeList))
    end
    if Client.wetMapVolumeList ~= nil then
        Shared.Message(string.format("%d wetmap volumes", #Client.wetMapVolumeList))
    end
    if Client.propList ~= nil then
        Shared.Message(ToString(#Client.propList + #MapParticlesOption_GetBlockablePropsTable()) ..  " props")
    end
    if Client.ambientSoundList ~= nil then
        Shared.Message(ToString(#Client.ambientSoundList) ..  " ambient sounds")
    end
    if Client.decalList ~= nil then
        Shared.Message(ToString(#Client.decalList) ..  " decals")
    end
    if Client.cinematics ~= nil then
        Shared.Message(ToString(#Client.cinematics + #MapParticlesOption_GetBlockableCinematicsTable()) ..  " cinematics")
    end
end

local function OnConsoleLocateOrigin(visible)
    local enabled = visible == "false" or visible == "0"
    
    if not originCinematic then
        originCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        originCinematic:SetCinematic(kOriginCinematic)
        originCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        local coords = Coords()
        originCinematic:SetCoords(coords)
        originCinematic:SetIsVisible(true)
    end
    
    if originCinematic and visible then
        Client.DestroyCinematic(originCinematic)
        originCinematic = nil
    end
end

local function OnCommandRemoveOption(option)

    if option then
        Client.RemoveOption(ToString(option))
        Shared.Message("Option " .. ToString(option) .. " removed!")
    end    
    
end

local function TogglePropNames()

    if propNames == nil then
        propNames = GetGUIManager():CreateGUIScript("GUIPropNames")
    end

    if propNames:GetIsVisible() then
        propNames:ClearPropNames()
    else
        propNames:DisplayPropNames()
    end
    
end

Event.Hook("Console_sysdev",
function(value)
    if value then
        Client.SetOptionString("system/dev", value)
    end
    Log("sysdev = '%s'", Client.GetOptionString("system/dev", ""))
end)


Event.Hook("Console_drawdecal", OnCommandDrawDecal)
Event.Hook("Console_tracereticle", OnCommandTraceReticle)
Event.Hook("Console_testsentry", OnCommandTestSentry)
Event.Hook("Console_random_debug", OnCommandRandomDebug)
Event.Hook("Console_location", OnCommandLocation)
Event.Hook("Console_changegcsettingclient", OnCommandChangeGCSettingClient)
Event.Hook("Console_cents", OnCommandClientEntities)
Event.Hook("Console_r_healthrings", OnCommandHealthRings)
Event.Hook("Console_reset_help", OnCommandResetHelp)
Event.Hook("Console_music", OnConsoleMusic)
Event.Hook("Console_mapinfo", OnConsoleMapInfo)
Event.Hook("Console_locateorigin", OnConsoleLocateOrigin)
Event.Hook("Console_removeoption", OnCommandRemoveOption)
Event.Hook("Console_propnames", TogglePropNames)

Event.Hook("Console_debugcommander", OnCommandDebugCommander)

Client.HookNetworkMessage("SelectAndGoto", OnCommandSelectAndGoto)
Client.HookNetworkMessage("ComSelect", OnCommandSelect)

local function OnConsoleSelectHallucinations()

    local player = Client.GetLocalPlayer()
    if player and player:isa("AlienCommander") then    
        SelectAllHallucinations(player)    
    end

end

Event.Hook("Console_selecthallucinations", OnConsoleSelectHallucinations)