-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ConsoleCommands_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/bots/DebugGUI/GBDMainWindow.lua") -- Bot Debugging UI

gDebugHelpWidget = nil

local function OnCommandFilterHelp(enabled, widgetName)

    if Shared.GetCheatsEnabled() then

        if enabled == "false" then
            gDebugHelpWidget = nil
            Print("Disabled Help Widget Filter")
            return
        elseif enabled == "true" then

            if not widgetName then
                Print("Cannot filter help widget, missing name!")
                gDebugHelpWidget = nil
                return
            end

            gDebugHelpWidget = widgetName
            Print("Only letting in help widgets will classname: %s", gDebugHelpWidget)

        end

    else

        Print("Cheats are not enabled. Disabling filter just in case.")
        gDebugHelpWidget = nil

    end

end
Event.Hook("Console_filterhelp", OnCommandFilterHelp)

gBotDebugWindow = nil
gBotDebugWindowEnabled = false
local function OnToggleBotDebugging()

    if GetBotDebuggingAllowed() then
        gBotDebugWindowEnabled = not gBotDebugWindowEnabled
    else
        Log("Bot-Debug command requires Cheats or Tests")
        return
    end

    if gBotDebugWindowEnabled then
        gBotDebugWindow = CreateGUIObject("botDebuggingWindow", GBDMainWindow, nil)
        
    else
        if gBotDebugWindow ~= nil then
            Client.SendNetworkMessage("ClientBotDebugTarget", {targetId = Entity.invalidId}, true)
            gBotDebugWindow:Destroy()
            gBotDebugWindow = nil
        end
    end

end
Event.Hook("Console_bot_debug", OnToggleBotDebugging)

local gShowingUncollideables = false
local kMaterialName = PrecacheAsset("cinematics/vfx_materials/placement_invalid.material")
local gRedMaterial
function OnCommandDebugCyst()
    
    local value = not gShowingUncollideables

    if value and not gRedMaterial then
    
        gRedMaterial = Client.CreateRenderMaterial()
        gRedMaterial:SetMaterial(kMaterialName)
        gRedMaterial:SetParameter("edge", 0)
        
    end
    
    SetShowDebugTrace(value)

    if Client.propList ~= nil then
    
        for _, models in ipairs(Client.propList) do
        
            if models[1] and not models[2] then
            
                if value then
                    models[1]:AddMaterial(gRedMaterial)
                else
                    models[1]:RemoveMaterial(gRedMaterial)
                end
            
            end
            
        end

        local blockablePropList = MapParticlesOption_GetBlockablePropsTable()
        for _, models in ipairs(blockablePropList) do

            if models[1] and not models[2] then

                if value then
                    models[1]:AddMaterial(gRedMaterial)
                else
                    models[1]:RemoveMaterial(gRedMaterial)
                end

            end

        end

    end
    
    if value then
        Shared.Message("Debug cyst enabled.")
    else
        Shared.Message("Debug cyst disabled.")
    end

end
Event.Hook("Console_debugcyst", OnCommandDebugCyst)

function OnCommandArmoryTest()

    if Shared.GetCheatsEnabled() then
        Shared.ConsoleCommand("spawn armory 1")
        Shared.ConsoleCommand("autobuild") -- Switch autobuild on and off to build it (yeah, it will also build other un-built things on the map)
        Shared.ConsoleCommand("autobuild")
    else
        Print("Cheats must be enabled to use the 'armorytest' command.")
    end
end
Event.Hook("Console_armorytest", OnCommandArmoryTest)

function OnCommandSoundGeometry(enabled)

    enabled = enabled ~= "false"
    Shared.Message("Sound geometry occlusion enabled: " .. tostring(enabled))
    Client.SetSoundGeometryEnabled(enabled)
    
end

function OnCommandEffectDebug(className)

    Print("OnCommandEffectDebug(\"%s\")", ToString(className))
    if Shared.GetDevMode() then
    
        if className and className ~= "" then
            gEffectDebugClass = className
        elseif gEffectDebugClass ~= nil then
            gEffectDebugClass = nil
        else
            gEffectDebugClass = ""
        end
    end
    
end

local locationDisplayedOnScreen = false
function OnCommandLocate(displayOnScreen)

    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
    
        local origin = player:GetOrigin()
        Shared.Message(string.format("Player is located at %f %f %f", origin.x, origin.y, origin.z))
        
    end
    
    locationDisplayedOnScreen = displayOnScreen == "true"
    
end

local nearestCommandChairsDisplayedOnScreen = false
local function OnCommandNearestCCs(display)

    local allow = Shared.GetTestsEnabled()
    nearestCommandChairsDisplayedOnScreen = allow and (display == "true") or false
end

local displayPlayerViewAngles = false
local function OnCommandViewAngles(display)

    local allow = Shared.GetTestsEnabled()
    displayPlayerViewAngles = allow and (display == "true") or false
end

local displayPlayerLookCoords = false
local function OnCommandLookCoords(display)

    local allow = Shared.GetTestsEnabled()
    displayPlayerLookCoords = allow and (display == "true") or false
end

local distanceDisplayedOnScreen = false
local function OnCommandDistance()

    if Shared.GetCheatsEnabled() or Shared.GetTestsEnabled() then
        distanceDisplayedOnScreen = not distanceDisplayedOnScreen
    end
    
end

local animationInputsDisplayedOnScreen
local function OnCommandAnimInputs(entId)

    if Shared.GetCheatsEnabled() then
        Log("Showing animation inputs for %s", entId)
        animationInputsDisplayedOnScreen = tonumber(entId)
    end
    
end


local function OnCommandSetSoundVolume(volume)

    local widget = GetOptionsMenu():GetOptionWidget("soundVolume")

    if widget then

        if volume == nil then
            Print("Sound volume is (0-100): %s", widget:GetValue())
        else
            local nVolume = tonumber(volume)
            if nVolume then
                nVolume = Clamp(nVolume, widget:GetMinValue(), widget:GetMaxValue())
                widget:SetValue(nVolume)
                Print("Set sound volume to %s", nVolume)
            end
        end
    else
        Print("Could not find option widget for soundVolume")
    end
    
end

function OnCommandSetMusicVolume(volume)

    local widget = GetOptionsMenu():GetOptionWidget("musicVolume")

    if widget then

        if volume == nil then
            Print("Music volume is (0-100): %s", widget:GetValue())
        else
            local nVolume = tonumber(volume)
            if nVolume then
                nVolume = Clamp(nVolume, widget:GetMinValue(), widget:GetMaxValue())
                widget:SetValue(nVolume)
                Print("Set music volume to %s", nVolume)
            end
        end
    else
        Print("Could not find option widget for musicVolume")
    end
end

function OnCommandSetVoiceVolume(volume)

    local widget = GetOptionsMenu():GetOptionWidget("voiceVolume")

    if widget then

        if volume == nil then
            Print("Voice volume is (0-100): %s", widget:GetValue())
        else
            local nVolume = tonumber(volume)
            if nVolume then
                nVolume = Clamp(nVolume, widget:GetMinValue(), widget:GetMaxValue())
                widget:SetValue(nVolume)
                Print("Set voice volume to %s", nVolume)
            end
        end
    else
        Print("Could not find option widget for voiceVolume")
    end
end

function OnCommandSetMouseSensitivity(sensitivity)
    local widget = GetOptionsMenu():GetOptionWidget("mouseSensitivity")

    if widget then

        if sensitivity == nil then
            Print("Mouse sensitivity is: %s", widget:GetValue())
        else
            local nSensitivity = tonumber(sensitivity)
            if nSensitivity then
                nSensitivity = Clamp(nSensitivity, widget:GetMinValue(), widget:GetMaxValue())
                widget:SetValue(nSensitivity)
                Print("Set mouse sensitivity to %s", nSensitivity)
            end
        end
    else
        Print("Could not find option widget for mouseSensitivity")
    end
end

-- Save this setting if we set it via a console command
function OnCommandSetName(...)
    
    local overrideEnabled = Client.GetOptionBoolean(kNicknameOverrideKey, false)
    if not overrideEnabled then
        Print( "Use 'sname <name>' to change your Steam Name")
        return
    end
        
    local name = StringConcatArgs(...)
    SetNickName(name)
    
end

function OnCommandSetSteamName(...)
    local overrideEnabled = Client.GetOptionBoolean(kNicknameOverrideKey, false)
    if overrideEnabled then
		Print( "Use 'name <name>' to change your NS2 in-game alias, or disable 'Use Alternate Nickname' in the option menu")
		return
	end

	local name = StringConcatArgs(...)
	name = string.UTF8SanitizeForNS2( TrimName(name) )
	
	if name == "" or not string.IsValidNickname(name) then
		Print( "You have to enter a valid nickname or use the Options Menu!")
		return
	end
	
	-- Allow this to change their actual steam name
	-- the in-game representation will be set via a OnPersonaChanged event
	Client.SetUserName( name )
end

local function OnCommandClearDebugLines()
    Shared.ClearDebugLines()
end

local function OnCommandGUIInfo()
    GUI.PrintItemInfoToLog()
end

local function OnCommandPlayMusic(name)
    Client.PlayMusic(name)
end

function OnCommandPathingFill()

    local player = Client.GetLocalPlayer()
    Pathing.FloodFill(player:GetOrigin())
    
end

local function OnCommandFindRef(className)

    if Shared.GetCheatsEnabled() then
    
        if className ~= nil then
            Debug.FindTypeReferences(className)        
        end
        
    end
    
end

local function OnCommandDebugSpeed()
    
    if not gSpeedDebug then
        gSpeedDebug = GetGUIManager():CreateGUIScriptSingle("GUISpeedDebug")
    else
    
        GetGUIManager():DestroyGUIScriptSingle("GUISpeedDebug")
        gSpeedDebug = nil
        
    end

end

local function OnCommandDebugFeedback()
    
    if not gFeedbackDebug then
        gFeedbackDebug = GetGUIManager():CreateGUIScriptSingle("GUIGameFeedback")
        gFeedbackDebug:SetIsVisible(true)
    else
    
        GetGUIManager():DestroyGUIScriptSingle("GUIGameFeedback")
        gFeedbackDebug = nil
        
    end

end

local kSayAllDelay = 3
local timeLastSayAll
function OnCommandSay(...)

    if not timeLastSayAll or timeLastSayAll + kSayAllDelay < Shared.GetTime() then

        local chatMessage = StringConcatArgs(...)
        chatMessage = string.UTF8Sub(chatMessage, 1, kMaxChatLength)
        if string.len(chatMessage) > 0 then
            Client.SendNetworkMessage("ChatClient", BuildChatClientMessage(false, chatMessage), true)
        end

        timeLastSayAll = Shared.GetTime()
    end

end
Event.Hook("Console_say", OnCommandSay)

local kSayTeamDelay = 3
local timeLastSayTeam
function OnCommandSayTeam(...)
    
    if not timeLastSayTeam or timeLastSayTeam + kSayTeamDelay < Shared.GetTime() then
        
        local chatMessage = StringConcatArgs(...)
        chatMessage = string.UTF8Sub(chatMessage, 1, kMaxChatLength)
        
        if string.len(chatMessage) > 0 then
            
            local player = Client.GetLocalPlayer()
            local playerName = player:GetName()
            local playerLocationId = player.locationId
            local playerTeamNumber = player:GetTeamNumber()
            local playerTeamType = player:GetTeamType()
            
            Client.SendNetworkMessage("ChatClient", BuildChatMessage(true, playerName, playerLocationId, playerTeamNumber, playerTeamType, chatMessage), true)		
        end
        
        timeLastSayTeam = Shared.GetTime()
    end
end

function OnCommandPrintVersion()
    Print("Steam App Build ID: %d", Client.GetSteamBuildId())
end

kDebugBuildTimes = false
kDebugBuildTimesInfo = {}
kDebugBuildTimesUI = nil
function ClearBuildTimesDebugInfo()
    kDebugBuildTimesInfo =
    {
        targetClassName = "",
        timeStarted = 0,
    }
end

function OnCommandBuildTimesDebugger()

    if Shared.GetCheatsEnabled() then

        kDebugBuildTimes = not kDebugBuildTimes
        Log("Build Times Debugger: %s", kDebugBuildTimes)
        ClearBuildTimesDebugInfo()
        if kDebugBuildTimes and not kDebugBuildTimesUI then
            kDebugBuildTimesUI = CreateGUIObject("buildTimesDebugger", GUIBuildTimes)
        elseif not kDebugBuildTimes and kDebugBuildTimesUI then
            kDebugBuildTimesUI:Destroy()
            kDebugBuildTimesUI = nil
        end

    else
        Log("Cheats must be enabled!")
    end
    
end

Event.Hook("Console_version", OnCommandPrintVersion)
Event.Hook("Console_tsay", OnCommandSayTeam)
Event.Hook("Console_soundgeometry", OnCommandSoundGeometry)
Event.Hook("Console_oneffectdebug", OnCommandEffectDebug)
Event.Hook("Console_locate", OnCommandLocate)
Event.Hook("Console_nearestcc", OnCommandNearestCCs)
Event.Hook("Console_viewangles", OnCommandViewAngles)
Event.Hook("Console_lookcoords", OnCommandLookCoords)
Event.Hook("Console_distance", OnCommandDistance)
Event.Hook("Console_animinputs", OnCommandAnimInputs)
Event.Hook("Console_name", OnCommandSetName)
Event.Hook("Console_sname", OnCommandSetSteamName)
Event.Hook("Console_cleardebuglines", OnCommandClearDebugLines)
Event.Hook("Console_guiinfo", OnCommandGUIInfo)
Event.Hook("Console_playmusic", OnCommandPlayMusic)

-- Options Console Commands
Event.Hook("Console_setsoundvolume", OnCommandSetSoundVolume)
Event.Hook("Console_sethudmap", OnCommandHUDMapEnabled)
-- Just a shortcut.
Event.Hook("Console_ssv", OnCommandSetSoundVolume)
Event.Hook("Console_setmusicvolume", OnCommandSetMusicVolume)
Event.Hook("Console_setvoicevolume", OnCommandSetVoiceVolume)
Event.Hook("Console_setvv", OnCommandSetVoiceVolume)
Event.Hook("Console_setsensitivity", OnCommandSetMouseSensitivity)
Event.Hook("Console_pathingfill", OnCommandPathingFill)

Event.Hook("Console_cfindref", OnCommandFindRef)
Event.Hook("Console_debugspeed", OnCommandDebugSpeed)
Event.Hook("Console_debugfeedback", OnCommandDebugFeedback)
Event.Hook("Console_debugbuildtimes", OnCommandBuildTimesDebugger)

Event.Hook("Console_dump_teambrain", function() Client.SendNetworkMessage("DumpTeamBrain", {}) end)

local function OnUpdateClient()
    Client.SetDebugText("ConsoleCommands.OnUpdateClient entry")
    if displayFPS then
        Client.ScreenMessage(string.format("FPS: %.0f", Client.GetFrameRate()))
    end
    
    local player = Client.GetLocalPlayer()
    if locationDisplayedOnScreen == true then
    
        local origin = player:GetOrigin()
        Client.ScreenMessage(string.format("%.2f %.2f %.2f", origin.x, origin.y, origin.z))
        
    end

    if nearestCommandChairsDisplayedOnScreen == true then

        local playerPos = player:GetOrigin()
        local nearestCS = GetNearest(playerPos, "CommandStation", kMarineTeamType)
        local nearestHive = GetNearest(playerPos, "Hive", kAlienTeamType)

        Client.ScreenMessage(string.format("Nearest Command Station: %.2f", nearestCS and playerPos:GetDistance(nearestCS:GetOrigin()) or -1))
        Client.ScreenMessage(string.format("Nearest Hive: %.2f", nearestHive and playerPos:GetDistance(nearestHive:GetOrigin()) or -1))

    end

    if displayPlayerViewAngles == true then

        if player then
            local viewAngles = player:GetViewAngles()
            Client.ScreenMessage(string.format("Pitch: %.2f", viewAngles.pitch))
            Client.ScreenMessage(string.format("Yaw: %.2f", viewAngles.yaw))
            Client.ScreenMessage(string.format("Roll: %.2f", viewAngles.roll))
        end

    end

    if displayPlayerLookCoords == true then
        if player then
            local lookAxis = player:GetViewCoords().zAxis
            Client.ScreenMessage(string.format("Look Axis - [x = %.2f, y = %.2f, z = %.2f]", lookAxis.x, lookAxis.y, lookAxis.z))
        end
    end
    
    if distanceDisplayedOnScreen == true then
    
        local startPoint = player:GetEyePos()
        local viewAngles = player:GetViewAngles()
        local fowardCoords = viewAngles:GetCoords()
        local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 10000), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))
        
        Client.ScreenMessage(string.format("%.2f", (trace.endPoint - startPoint):GetLength()))
        
        if trace.entity then
            Client.ScreenMessage(GetEntityInfo(trace.entity))
        end
        
    end
    
    if animationInputsDisplayedOnScreen ~= nil then
    
        local ent = Shared.GetEntity(animationInputsDisplayedOnScreen)
        if ent then
        
            for name, value in pairs(ent.animationInputValues) do
                Client.ScreenMessage(name .. " = " .. ToString(value))
            end
            
        end
        
    end
        
    Client.SetDebugText("ConsoleCommands.OnUpdateClient exit")
end
Event.Hook("UpdateClient", OnUpdateClient,"ConsoleCommands")