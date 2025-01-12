--=============================================================================
--
-- lua/Main.lua
--
-- Created by Max McGuire (max@unknownworlds.com)
-- Copyright 2012, Unknown Worlds Entertainment
--
-- This file is loaded when the game first starts up and displays the main menu.
--
--=============================================================================
decoda_name = "Main"

--require("jit").off() -- disable lua-JIT for debugging.

-- Ensure cinematic background is preloaded, otherwise we get pop-in.
Script.Load("lua/Utility.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/OptionSavingManager.lua")
Script.Load("lua/menu2/MenuBackgrounds.lua")
Script.Load("lua/ConsoleCommands_Shared.lua")

Script.Load("lua/ModLoader.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Render.lua")
Script.Load("lua/GUIManager.lua")

Script.Load("lua/thunderdome/ThunderdomeWrapper.lua")

Script.Load("lua/menu2/GUIMainMenu.lua")
Script.Load("lua/MainMenu.lua")

Script.Load("lua/AdvancedOptions.lua")

Script.Load("lua/menu/GUIVideoTutorialIntro.lua")

-- Don't ask...
math.randomseed(Shared.GetSystemTime())
for i = 1, 20 do math.random() end

local renderCamera = nil

PrecacheAsset("ui/newMenu/mainNavBarBack.dds")
PrecacheAsset("ui/newMenu/mainNavBarButtonLight.dds")
PrecacheAsset("ui/newMenu/logoHuge.dds")
PrecacheAsset('ui/menu/arrow_vert.dds')
PrecacheAsset('ui/menu/tabbackground.dds')
PrecacheAsset('cinematics/menu/dropship_thrusters_flight.cinematic')
PrecacheAsset('cinematics/menu/dropship_thrusters_down.cinematic')
PrecacheAsset('models/marine/Dropship/dropship_fx_thrusters_02.model')
PrecacheAsset('cinematics/vfx_materials/vfx_enzyme_loop_01_animated.material')
PrecacheAsset('cinematics/vfx_materials/vfx_fireball_03_animated.material')
PrecacheAsset('cinematics/vfx_materials/vfx_enzymeloop_01_animated.dds')
PrecacheAsset('cinematics/menu/dropship_thrusters_approach.cinematic')

-- Precache the common surface shaders.
PrecacheAsset("shaders/Model.surface_shader")
PrecacheAsset("shaders/Emissive.surface_shader")
PrecacheAsset("shaders/Model_emissive.surface_shader")
PrecacheAsset("shaders/Model_alpha.surface_shader")
PrecacheAsset("shaders/ViewModel.surface_shader")
PrecacheAsset("shaders/ViewModel_emissive.surface_shader")
PrecacheAsset("shaders/Decal.surface_shader")
PrecacheAsset("shaders/Decal_emissive.surface_shader")

local function InitializeRenderCamera()
    renderCamera = Client.CreateRenderCamera()
    renderCamera:SetRenderSetup("renderer/Deferred.render_setup")
    renderCamera:SetNearPlane(0.01)
    renderCamera:SetFarPlane(10000.0)
    --Required in order to not render any customize camera content, default of 0, will render everything.
    renderCamera:SetRenderMask( kDefaultRenderMask )
    renderCamera:SetUsesTAA(true) -- render camera _can_ be used with TAA (won't if option isn't set)
end

local function OnUpdateRender()

    local cullingMode = RenderCamera.CullingMode_Occlusion
    local camera = MenuManager.GetCinematicCamera()
    
    if camera ~= false then
        renderCamera:SetCoords(camera:GetCoords())
        renderCamera:SetFov(camera:GetFov())
        renderCamera:SetCullingMode(cullingMode)
        Client.SetRenderCamera(renderCamera)
        Client.SetFirstPersonSound(false)
    else
        Client.SetRenderCamera(nil)
        Client.SetFirstPersonSound(false)
    end
    
end


--Simple cache for any on-load messages sent from engine. Since this is now a delayed process
--(e.g. to allow Lobby data time to load/setup), we need this cached for when the TDMgr callback
--is triggered
local kOnLoadCompleteMessage = false
local kPrevLoadMessage = nil

--TDMgr event triggered event that only occurs AFTER TDMgr has completed its delayed-init routine(s)
--Note! This can be triggered multiple times during "normal" usage, so handling of load message is required
local function OnMenuLoadEndEvents()

    SLog("----|  OnMenuLoadEndEvents( %s )  |----", kOnLoadCompleteMessage)

    --pass message through to TD Mgr, to check for TD specific events, on false return, no TD specific events happen, proceed with 'normal' ones
    if not Thunderdome():OnLoadCompleteMessage(kOnLoadCompleteMessage) then

        if kOnLoadCompleteMessage ~= false and kOnLoadCompleteMessage ~= nil then
            
            -- If the message is an invalid password, prompt the user to try again, otherwise just do the standard popup.
            local kInvalidPasswordMessage = Locale.ResolveString("DISCONNECT_REASON_2")

            if kOnLoadCompleteMessage == kInvalidPasswordMessage and kPrevLoadMessage ~= kOnLoadCompleteMessage then
                PlayMenuSound("Notification")

                kPrevLoadMessage = kOnLoadCompleteMessage

                local serverBrowser = GetServerBrowser()
                local address = Client.GetOptionString(kLastServerConnected, "")
                local prevPassword = Client.GetOptionString(kLastServerPassword, "")
                
                if address ~= "" and serverBrowser ~= nil then
                
                    serverBrowser:_AttemptToJoinServer(
                    {
                        address = address,
                        prevPassword = prevPassword,
                    
                        -- The user has presumably already clicked through all the checks (eg unranked
                        -- warning, network settings warning, etc.)  No need to hit them with it again.
                        onlyPassword = true,
                    
                    })
            
                end
                
            else
                
                if kPrevLoadMessage == kOnLoadCompleteMessage then
                --ignore "duplicate" / already post scenarios. "Normal" messages should never appear multiple times
                    return 
                end
                
                if kPrevLoadMessage ~= kOnLoadCompleteMessage then
                    kPrevLoadMessage = kOnLoadCompleteMessage
                end
                
                if kOnLoadCompleteMessage == false then
                    PlayMenuSound("Notification")
                    GetMainMenu():DisplayPopupMessage(kOnLoadCompleteMessage, Locale.ResolveString("DISCONNECTED"))
                else
                --Handle all "normal" messages (consistency fail, auth-fail, etc, etc.)
                    PlayMenuSound("Notification")
                    GetMainMenu():DisplayPopupMessage(kOnLoadCompleteMessage)
                end
                
            end

        end

    end

end
Thunderdome_AddListener( kThunderdomeEvents.OnMenuLoadEndEvents, OnMenuLoadEndEvents )


local function OnVideoEnded(message, watchedTime)

    SLog("  == OnVideoEnded( %s, %s ) ==", message, watchedTime)

    Client.SetOptionBoolean( "introViewed", true )
    Client.SetOptionBoolean( "system/introViewed", true )
    
    g_introVideoWatchTime = watchedTime
    
    MouseTracker_SetIsVisible(false)
    
    MenuManager.SetMenuCinematic(MenuBackgrounds.GetCurrentMenuBackgroundCinematicPath(), true)
    
    -- "Re-roll" the menu background for next time, in case it's set to random, we need to know
    -- which one to pre-load ahead of time.
    MenuBackgrounds.PickNextMenuBackgroundPath()
    
    CreateMainMenu()
    local menu = GetMainMenu()
    menu:PlayMusic(MenuData.GetCurrentMenuMusicSoundName())
    
    -- Show news feed if this is a new build.
    local currentBuildNumber = Shared.GetBuildNumber()
    local lastBuildNumber = Client.GetOptionInteger("lastLoadedBuild", 0)
    local navBar = GetNavBar()

    if navBar then
        if lastBuildNumber < currentBuildNumber then
            GetNavBar():SetIsBuildNew(true)
            GetScreenManager():DisplayScreen("NavBar")

            if currentBuildNumber == 340 then
                GetMissionScreen():SetUnread() -- New rewards screen
                GetPlayerScreen():SetUnread() -- New Calling Card customizer
            end

        end
    else
        Print("ERROR: Navbar does not exist when checking for new build!")
    end

    -- Remember the build number of when we last loaded the game
    Client.SetOptionInteger("lastLoadedBuild", Shared.GetBuildNumber())
    Client.SetOptionString(kLastServerPassword, "")

    kOnLoadCompleteMessage = message
    
end

local function OnResetIntro()
    Client.SetOptionBoolean("introViewed",false)
    Client.SetOptionBoolean("system/introViewed",false)
    Print("Intro first-viewing status reset")
end

local function OnLoadComplete(message)
    
    SLog("***  OnLoadComplete(%s)  ***", message)

    Render_SyncRenderOptions()
    OptionsDialogUI_SyncSoundVolumes()
    
    kRemoteConfig = {}      --McG-TODO: Trace and determine if still useful (I doubt it is)

    UpdatePlayerNicknameFromOptions()

    local introViewed = 
        Client.GetOptionBoolean("introViewed", false )
        or Client.GetOptionBoolean("system/introViewed", false )
    
    if introViewed then
        -- Skip intro video if they've already seen it
        OnVideoEnded(message, nil)
    else
        -- Play intro video if this is the first view
        GUIVideoTutorialIntro_Play(OnVideoEnded, message)
    end

    --Ensure all achievements and stats are stored on Steam backend before we modify them further.
    --Otherwise desync between local-state can occur
    Client.ForceUpdateAchievements() --ignore ret res

    OnCommandPrintVersion()
end

function OnCommandPrintVersion()
    Print("Steam App Build ID: %d", Client.GetSteamBuildId())
end

Event.Hook("Console_version", OnCommandPrintVersion)
Event.Hook("UpdateRender", OnUpdateRender)
Event.Hook("LoadComplete", OnLoadComplete)
Event.Hook("Console_resetintro", OnResetIntro)

-- Run bot-related unit tests. These are quick and silent.
Script.Load("lua/bots/UnitTests.lua")

-- Initialize the camera at load time, so that the render setup will be
-- properly precached during the loading screen.
InitializeRenderCamera()


--******TEMP******
Event.Hook("Console_dumpid",
function()
    Log("SteamID Conversion Dump:")
    local sId32 = Client.GetSteamId()
    Log("\t  sId32:      %s",sId32)
    local scId64 = Shared.ConvertSteamId32To64(sId32)
    Log("\t scId64:      %s",scId64)
    local scId32 = Shared.ConvertSteamId64To32(scId64)
    Log("\t scId32:      %s",scId32)
end)


Event.Hook("Console_dbg_clear_achievement", function(name)
    
    if not name then
        Log("Achievement name required")
        return
    end
    
    Client.ClearAchievement(name)
    Client.CommitPendingStats();
    Log("Cleared achievement '%s'", name)

end)