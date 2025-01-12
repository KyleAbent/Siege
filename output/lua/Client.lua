-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- Set the name of the VM for debugging
decoda_name = "Client"

kInGame = true -- Client.GetIsConnected() doesn't work until you're loaded in...

--require("jit").off() -- disable lua-JIT for debugging.

Script.Load("lua/PreLoadMod.lua")

Script.Load("lua/OptionSavingManager.lua")
Script.Load("lua/ClientResources.lua")
Script.Load("lua/Shared.lua")
Script.Load("lua/GUIAssets.lua")
Script.Load("lua/Effect.lua")
Script.Load("lua/AmbientSound.lua")
Script.Load("lua/GhostModelUI.lua")
Script.Load("lua/Render.lua")
Script.Load("lua/MapEntityLoader.lua")
Script.Load("lua/Chat.lua")
Script.Load("lua/DeathMessage_Client.lua")
Script.Load("lua/DSPEffects.lua")
Script.Load("lua/Scoreboard.lua")
Script.Load("lua/AlienBuy_Client.lua")
Script.Load("lua/MarineBuy_Client.lua")
Script.Load("lua/Tracer_Client.lua")
Script.Load("lua/GUIManager.lua")

Script.Load("lua/thunderdome/ThunderdomeWrapper.lua")
Script.Load("lua/TournamentMode.lua")

Script.Load("lua/menu2/GUIMainMenuInGame.lua") -- load the in-game version of the main menu.
Script.Load("lua/MainMenu.lua")

Script.Load("lua/AdvancedOptions.lua")

Script.Load("lua/Utility.lua")
Script.Load("lua/ScoreDisplay.lua")

Script.Load("lua/GUIDebugText.lua")
Script.Load("lua/GUI/Debug/GUIBuildTimes.lua")
Script.Load("lua/TrailCinematic.lua")
Script.Load("lua/MenuManager.lua")
Script.Load("lua/BindingsDialog.lua")
Script.Load("lua/ConsoleBindings.lua")
Script.Load("lua/ServerAdmin.lua")
Script.Load("lua/ClientUI.lua")
Script.Load("lua/Voting.lua")
Script.Load("lua/Badges_Client.lua")

Script.Load("lua/Hud/HelpScreen/HelpScreen.lua")

Script.Load("lua/ConsoleCommands_Client.lua")
Script.Load("lua/NetworkMessages_Client.lua")

Script.Load("lua/HiveVision.lua")

Script.Load("lua/JitConfig.lua")

Script.Load("lua/Analytics.lua")

-- Precache the common surface shaders.
PrecacheAsset("shaders/Model.surface_shader")
PrecacheAsset("shaders/Emissive.surface_shader")
PrecacheAsset("shaders/Model_emissive.surface_shader")
PrecacheAsset("shaders/Model_alpha.surface_shader")
PrecacheAsset("shaders/ViewModel.surface_shader")
PrecacheAsset("shaders/ViewModel_emissive.surface_shader")
PrecacheAsset("shaders/Decal.surface_shader")
PrecacheAsset("shaders/Decal_emissive.surface_shader")

--For one-off menu backgrounds, due to how Cinematic "pre" caching works
--Note: please ONLY add precahce calls here for items _specific_ to INTERNAL assets in Menu Background cinematics
PrecacheAsset("models/props/undercity/undercity_skybox_searchlight.model")


Client.locationList = { }
Client.propList = { }
Client.lightList = { }
Client.glowingProps = { }
Client.skyBoxList = { }
Client.ambientSoundList = { }
Client.tracersList = { }
Client.fogAreaModifierList = { }
Client.rules = { }
Client.cinematics = { }
Client.trailCinematics = { }
-- cinematics which are queued for destruction next frame
Client.destroyTrailCinematics = { }
Client.worldMessages = { }
Client.timeLimitedDecals = { }

Client.timeOfLastPowerPoints = nil

Client.kAmbientVolume = (Clamp(Client.GetOptionInteger("ambientVolume", 100), 20, 100) / 100)

local startLoadingTime = Shared.GetSystemTimeReal()
local currentLoadingTime = Shared.GetSystemTimeReal()

Client.serverHidden = false
function Client.GetServerIsHidden()
    return Client.serverHidden
end

Client.localClientIndex = nil
function Client.GetLocalClientIndex()
    return Client.localClientIndex
end

local gOutlinePlayers = true
function Client.GetOutlinePlayers()
    return gOutlinePlayers
end

function Client.ToggleOutlinePlayers()
     gOutlinePlayers = not gOutlinePlayers
end

local toggleOutlineLastFrame = false
function Client.OnProcessGameInput(input)

    if Client.GetLocalClientTeamNumber() == kSpectatorIndex then

        local toggleOutlinePressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not toggleOutlineLastFrame and toggleOutlinePressed then
            Client.ToggleOutlinePlayers()          
        end
        toggleOutlineLastFrame = toggleOutlinePressed
    
    end
    
end

--
--This function will return the team number the local client is on
--regardless of any spectating the local client may be doing.
--
Client.localClientTeamNumber = kTeamInvalid
function Client.GetLocalClientTeamNumber()
    return Client.localClientTeamNumber
end

local function InitializeRenderCamera()
    gRenderCamera = Client.CreateRenderCamera()
    gRenderCamera:SetRenderSetup("renderer/Deferred.render_setup")
    gRenderCamera:SetUsesTAA(true) -- render camera _can_ be used with TAA (won't if option isn't set)
    gRenderCamera:SetRenderMask( kDefaultRenderMask )
    --RenderMask must be set in order for multi-cam scenes to not overlap
end

function GetRenderCameraCoords()
    if gRenderCamera then
        return gRenderCamera:GetCoords()
    end

    return Coords.GetIdentity()
end

-- Client tech tree
local gTechTree = TechTree()
gTechTree:Initialize() 

function GetTechTree()
    return gTechTree
end

function ClearTechTree()
    gTechTree:Initialize()
end

function SetLocalPlayerIsOverhead(isOverhead)

    Client.SetGroupIsVisible(kCommanderInvisibleGroupName, not isOverhead)
    Client.SetGroupIsVisible(kCommanderInvisibleVentsGroupName, not isOverhead)
    Client.SetGroupIsVisible(kCommanderInvisibleNonCollisionGroupName, not isOverhead)

    if gSeasonalCommanderInvisibleGroupName then
        Client.SetGroupIsVisible(gSeasonalCommanderInvisibleGroupName, not isOverhead)
    end

    for c = 1, #Client.cinematics do
    
        local cinematic = Client.cinematics[c]
        if cinematic.commanderInvisible then
            cinematic:SetIsVisible(not isOverhead)
        end
        
    end

    MapParticlesOption_UpdateBlockableCinamaticsCommanderInvisible(isOverhead)
    
end

--
--Destroys all of the objects created during the level load by the
--OnMapLoadEntity function.
--
function DestroyLevelObjects()

    -- Remove all of the props.
    if Client.propList ~= nil then
        for index, models in ipairs(Client.propList) do
            Client.DestroyRenderModel(models[1])
            Shared.DestroyCollisionObject(models[2])
        end
        Client.propList = { }
    end

    MapParticlesOption_RemoveBlockableProps()
    
    -- Remove the lights.
    if Client.lightList ~= nil then
        for index, light in ipairs(Client.lightList) do
            Client.DestroyRenderLight(light)
        end
        Client.lightList = { }
    end
    
    -- Remove the billboards.
    if Client.billboardList ~= nil then  
        for index, billboard in ipairs(Client.billboardList) do
            Client.DestroyRenderBillboard(billboard)
        end
        Client.billboardList = { }
    end
    
    -- Remove the decals.
    if Client.decalList ~= nil then  
        for index, decal in ipairs(Client.decalList) do
            Client.DestroyRenderDecal(decal)
        end
        Client.decalList = { }
    end

    -- Remove the reflection probes.
    if Client.reflectionProbeList ~= nil then
    
        for index, reflectionProbe in ipairs(Client.reflectionProbeList) do
            Client.DestroyRenderReflectionProbe(reflectionProbe)
        end
        Client.reflectionProbeList = { }
        
    end
    
    -- Remove the fog volumes.
    if Client.fogMeshVolumeList ~= nil then
    
        for index, fogVolume in ipairs(Client.fogMeshVolumeList) do
            Client.DestroyRenderFogMeshVolume(fogVolume)
        end
        Client.fogMeshVolumeList = { }
        
    end
    
    -- Remove fog spheres.
    if Client.fogSphereVolumeList ~= nil then
    
        for index, fogSphere in ipairs(Client.fogSphereVolumeList) do
            Client.DestroyRenderFogSphereVolume(fogSphere)
        end
        Client.fogSphereVolumeList = { }
        
    end
    
    -- Remove the wetmap volumes.
    if Client.wetMapVolumeList ~= nil then
    
        for index, wetMapVolume in ipairs(Client.wetMapVolumeList) do
            Client.DestroyRenderWetMapVolume(wetMapVolume)
        end
        Client.wetMapVolumeList = { }
        
    end
    
    -- Remove the cinematics.
    if Client.cinematics ~= nil then
    
        for index, cinematic in ipairs(Client.cinematics) do
            Client.DestroyCinematic(cinematic)
        end

        Client.cinematics = { }
    end

    MapParticlesOption_RemoveBlockableMapCinematics()
    
    -- Remove the skyboxes.
    Client.skyBoxList = { }
    
    -- Remove tracers.
    for i=1, #Client.tracersList do
        Client.tracersList[i]:OnDestroy()
    end
    Client.tracersList = { }
    
    -- Remove ambient sounds.
    for a = 1, #Client.ambientSoundList do
        Client.ambientSoundList[a]:OnDestroy()
    end
    Client.ambientSoundList = { }
    
    Client.rules = { }
    
end

function ExitPressed()

    if not Shared.GetIsRunningPrediction() then
    
        -- Close buy menu if open, otherwise show in-game menu
        if MainMenu_GetIsOpened() then
            --MainMenu_ReturnToGame()
        else
        
            if not Client.GetLocalPlayer():CloseMenu() then
                GetMainMenu():Open()
            end
            
        end
        
    end
    
end

local blockableMapCinematics = set
{
    "cinematics/environment/biodome/flying_papers.cinematic",
    "cinematics/environment/biodome/leaves_folliage_01.cinematic",
    "cinematics/environment/biodome/mosquitos_glow.cinematic",
    "cinematics/environment/biodome/sand_storm.cinematic",
    "cinematics/environment/biodome/sprinklers_top_long.cinematic",
    "cinematics/environment/biodome/sprinklers_top_long_narrow.cinematic",
    "cinematics/environment/biodome/waterfall_basemist.cinematic",
    "cinematics/environment/descent/descent_club_holo_ball.cinematic",
    "cinematics/environment/descent/descent_droid.cinematic",
    "cinematics/environment/descent/descent_energyflow_lightflash.cinematic",
    "cinematics/environment/dust_motes.cinematic",
    "cinematics/environment/eclipse/search_light.cinematic",
    "cinematics/environment/eclipse/skyline.cinematic",
    "cinematics/environment/eclipse/skyline_endless.cinematic",
    "cinematics/environment/emergency_light_flash.cinematic",
    "cinematics/environment/fire_light_flicker.cinematic",
    "cinematics/environment/fire_small.cinematic",
    "cinematics/environment/fire_small_sidebarrel.cinematic",
    "cinematics/environment/fire_tiny.cinematic",
    "cinematics/environment/halo_aqua_large.cinematic",
    "cinematics/environment/halo_blue_large.cinematic",
    "cinematics/environment/halo_orange_large.cinematic",
    "cinematics/environment/lightrays_blue.cinematic",
    "cinematics/environment/lightrays_orange.cinematic",
    "cinematics/environment/light_c12_ambientflicker.cinematic",
    "cinematics/environment/light_c12_downflicker.cinematic",
    "cinematics/environment/light_repair_downflicker.cinematic",
    "cinematics/environment/sparks.cinematic",
    "cinematics/environment/sparks_loop_3s.cinematic",
    "cinematics/environment/steam.cinematic",
    "cinematics/environment/steamjet_ceiling.cinematic",
    "cinematics/environment/steamjet_ceiling_burst_4s.cinematic",
    "cinematics/environment/steamjet_large_soft.cinematic",
    "cinematics/environment/steamjet_wall.cinematic",
    "cinematics/environment/steam_ambiant.cinematic",
    "cinematics/environment/steam_rise.cinematic",
    "cinematics/environment/tram_skybox_tram1.cinematic",
    "cinematics/environment/tram_skybox_tram2.cinematic",
    "cinematics/environment/tram_skybox_tram3.cinematic",
    "cinematics/environment/waterfall_basemist.cinematic",
    "cinematics/environment/waterfall_emerge.cinematic",
    "cinematics/environment/waterfall_fine.cinematic",
    "cinematics/environment/waterfall_large_basemist.cinematic",
    "cinematics/environment/water_bubbles_01.cinematic",
    "cinematics/environment/water_drip.cinematic",
    "cinematics/environment/water_drips_rapid.cinematic",
}

local blockableCinematicsCache = { }
local blockableCinematicsValuesCache = { }

function CreateCinematic(className, groupName, values)

    local coords = values.angles:GetCoords(values.origin)

    local zone = RenderScene.Zone_Default

    if className == "skybox" then
        zone = RenderScene.Zone_SkyBox
    end

    local cinematic = Client.CreateCinematic(zone)

    cinematic:SetCinematic(values.cinematicName)
    cinematic:SetCoords(coords)

    local repeatStyle = Cinematic.Repeat_None

    -- 0 is Repeat_None but Repeat_None is not supported here because it would
    -- cause the cinematic to kill itself but the cinematic would not be
    -- removed from the Client.cinematics list which would cause errors.
    if values.repeatStyle == 0 then
        repeatStyle = Cinematic.Repeat_Loop
    elseif values.repeatStyle == 1 then
        repeatStyle = Cinematic.Repeat_Loop
    elseif values.repeatStyle == 2 then
        repeatStyle = Cinematic.Repeat_Endless
    end

    if className == "skybox" then

        table.insert(Client.skyBoxList, cinematic)

        -- Becuase we're going to hold onto the skybox, make sure it
        -- uses the endless repeat style so that it doesn't delete itself
        repeatStyle = Cinematic.Repeat_Endless

    end

    cinematic:SetRepeatStyle(repeatStyle)

    cinematic.commanderInvisible = values.commanderInvisible
    cinematic.className = className
    cinematic.coords = coords

    -- Add block-able map cinematics to a separate list.
    if className == "cinematic" and blockableMapCinematics[values.cinematicName] then

        table.insert(blockableCinematicsCache, cinematic) -- Save cinematic instances for easy deletion later.

        if not Client.fullyLoaded then -- Save creation values for block-able cinematics so we can re-create them at runtime if needed.
            table.insert(blockableCinematicsValuesCache, {className = className, groupName = groupName, values = values})
        end
    else
        table.insert(Client.cinematics, cinematic)
    end

end

local viewModelCinematics = set
{
    "cinematics/marine/gl/muzzle_flash.cinematic",
    "cinematics/marine/gl/shell.cinematic", --- Unused
    "cinematics/marine/minigun/muzzle_flash.cinematic",
    "cinematics/marine/minigun/muzzle_flash_left.cinematic",
    "cinematics/marine/minigun/muzzle_flash_loop.cinematic", -- Unused
    "cinematics/marine/pistol/muzzle_flash.cinematic",
    "cinematics/marine/pistol/shell.cinematic", -- Bullet casings
    "cinematics/marine/railgun/muzzle_flash.cinematic",
    "cinematics/marine/railgun/steam_1p_left.cinematic", -- Steam after firing railgun.
    "cinematics/marine/railgun/steam_1p_right.cinematic", -- Steam after firing railgun.
    "cinematics/marine/rifle/muzzle_flash.cinematic", -- Controlled by weapon upgrades
    "cinematics/marine/rifle/muzzle_flash2.cinematic",
    "cinematics/marine/rifle/muzzle_flash3.cinematic",
    "cinematics/marine/rifle/shell.cinematic",
    "cinematics/marine/rifle/shell_looping_1p.cinematic",
    "cinematics/marine/shotgun/muzzle_flash.cinematic",
    "cinematics/marine/shotgun/shell.cinematic",
    "cinematics/marine/hmg/muzzle_flash.cinematic",
    "cinematics/marine/hmg/shell_looping_1p.cinematic",
}

-- These cinematics will be replaced by a more minimal one when encountered.
local replacedCinematics = set
{
    "cinematics/alien/cyst/enzymecloud_large.cinematic",
    "cinematics/alien/fade/blink_in_silent.cinematic",
    "cinematics/alien/fade/blink_out_silent.cinematic",
    "cinematics/alien/mucousmembrane.cinematic",
    "cinematics/alien/nutrientmist.cinematic",
    "cinematics/alien/nutrientmist_hive.cinematic",
    "cinematics/alien/nutrientmist_onos.cinematic", -- Unused
    "cinematics/alien/nutrientmist_structure.cinematic",
    "cinematics/alien/tracer_residue.cinematic",
    "cinematics/common/resnode.cinematic",
    "cinematics/marine/infantryportal/spin.cinematic",
    "cinematics/marine/minigun/muzzle_flash.cinematic",
    "cinematics/marine/minigun/muzzle_flash_left.cinematic",
    "cinematics/marine/rifle/muzzle_flash.cinematic",
    "cinematics/marine/rifle/muzzle_flash2.cinematic",
    "cinematics/marine/rifle/muzzle_flash3.cinematic",
    "cinematics/marine/spawn_item.cinematic",
    "cinematics/marine/structures/hurt.cinematic",
    "cinematics/marine/structures/hurt_severe.cinematic",
    "cinematics/marine/structures/hurt_small.cinematic",
    "cinematics/marine/structures/hurt_small_severe.cinematic",
    "cinematics/materials/metal/ricochet.cinematic", -- Unused (Map dependent?)
    "cinematics/materials/metal/ricochetHeavy.cinematic", -- Unused (Map dependent?)
    "cinematics/materials/rock/ricochet.cinematic", -- Unused (Map dependent?)
    "cinematics/materials/rock/ricochetHeavy.cinematic", -- Unused (Map dependent?)
    "cinematics/materials/thin_metal/ricochet.cinematic", -- Unused (Map dependent?)
    "cinematics/materials/thin_metal/ricochetHeavy.cinematic", -- Unused (Map dependent?)
}

-- These cinematics will be replaced by a blank cinematic when encountered.
local blockedCinematics = set
{
    "cinematics/alien/commander_arrow.cinematic", -- Hive help arrows. Hints need to be on.
    "cinematics/alien/cyst/enzymecloud_splash.cinematic",
    "cinematics/alien/death_1p_alien.cinematic", -- Blood on death screen.
    "cinematics/alien/fade/blink_view.cinematic", -- No attach point. Effectively unused.
    "cinematics/alien/fade/shadowstep.cinematic", -- Unused
    "cinematics/alien/fade/shadowstep_silent.cinematic", -- Unused
    "cinematics/alien/fade/trail_dark_1.cinematic",
    "cinematics/alien/fade/trail_dark_2.cinematic",
    "cinematics/alien/fade/trail_light_1.cinematic", -- Unused
    "cinematics/alien/fade/trail_light_2.cinematic", -- Unused
    "cinematics/alien/tunnel/entrance_use_1p.cinematic",
    "cinematics/death_1p.cinematic", -- Marine blood on death screen.
    "cinematics/marine/commander_arrow.cinematic", -- Command station help arrows. Hints need to be on.
    "cinematics/marine/exo/hurt_severe_view.cinematic",
    "cinematics/marine/exo/hurt_view.cinematic",
    "cinematics/marine/flamethrower/burning_surface.cinematic",
    "cinematics/marine/flamethrower/burning_vertical_surface.cinematic",
    "cinematics/marine/flamethrower/burn_big.cinematic",
    "cinematics/marine/flamethrower/burn_huge.cinematic",
    "cinematics/marine/flamethrower/burn_med.cinematic",
    "cinematics/marine/flamethrower/burn_small.cinematic",
    "cinematics/marine/flamethrower/burn_small_continuous.cinematic", -- Unused
    "cinematics/marine/flamethrower/burn_tiny.cinematic", -- Unused
    "cinematics/marine/flamethrower/canister_explosion.cinematic", -- Unused
    "cinematics/marine/flamethrower/flame.cinematic",
    "cinematics/marine/flamethrower/flameout.cinematic",
    "cinematics/marine/flamethrower/flame_1p.cinematic",
    "cinematics/marine/flamethrower/flame_impact3.cinematic",
    "cinematics/marine/flamethrower/flame_residue_1p_part1.cinematic",
    "cinematics/marine/flamethrower/flame_residue_1p_part2.cinematic",
    "cinematics/marine/flamethrower/flame_residue_1p_part3.cinematic",
    "cinematics/marine/flamethrower/flame_trail_1p_part2.cinematic",
    "cinematics/marine/flamethrower/flame_trail_1p_part3.cinematic",
    "cinematics/marine/flamethrower/flame_trail_full.cinematic", -- Unused
    "cinematics/marine/flamethrower/flame_trail_half.cinematic", -- Unused
    "cinematics/marine/flamethrower/flame_trail_light.cinematic", -- Unused
    "cinematics/marine/flamethrower/flame_trail_part2.cinematic",
    "cinematics/marine/flamethrower/flame_trail_part3.cinematic",
    "cinematics/marine/flamethrower/flame_trail_short.cinematic", -- Unused
    "cinematics/marine/flamethrower/impact.cinematic", -- Unused
    "cinematics/marine/flamethrower/pilot.cinematic",
    "cinematics/marine/flamethrower/scorched.cinematic", -- Unused
    "cinematics/marine/ghoststructure_destroy.cinematic",
    "cinematics/marine/heavy/land.cinematic",
    "cinematics/marine/infantryportal/death.cinematic",
    "cinematics/marine/jetpack/impact.cinematic",
    "cinematics/marine/jetpack/trail_2.cinematic", -- Trails are hard to see, but they're the smoke trail not the fire thrusters.
    "cinematics/marine/jetpack/trail_2.cinematic",
    "cinematics/marine/jetpack/trail_2.cinematic",
    "cinematics/marine/jetpack/trail_3.cinematic",
    "cinematics/marine/minigun/mm_left_shell.cinematic",
    "cinematics/marine/minigun/mm_shell.cinematic",
    "cinematics/marine/minigun/overheat.cinematic",
    "cinematics/marine/sentry/death.cinematic",
    "cinematics/marine/structures/death_large.cinematic",
    "cinematics/marine/structures/death_small.cinematic",
}

local function GetMinimalCinematicName(cinematicName)
    local minimalCinematicName = string.gsub(cinematicName, "cinematics/", "cinematics/minimal/")
    return minimalCinematicName
end

-- Precache all the new cinematics
PrecacheAsset("cinematics/minimal/blank.cinematic")
for cinematic,_ in pairs(replacedCinematics) do
    PrecacheAsset(GetMinimalCinematicName(cinematic))
end

function FilterCinematicName(cinematicName)

    if not cinematicName then return nil end

    -- Hiding viewmodel will hide some cinematics before the minimal particles stuff gets a chance.
    if Client.kHideViewModel and viewModelCinematics[cinematicName] then
        cinematicName = "cinematics/minimal/blank.cinematic"
    end

    if Client.kMinimalParticles then

        if replacedCinematics[cinematicName] then
            cinematicName = GetMinimalCinematicName(cinematicName)
        elseif blockedCinematics[cinematicName] then
            cinematicName = "cinematics/minimal/blank.cinematic"
            -- Easier than doing this in like 10 folders
        elseif string.find(cinematicName, "ricochetMinigun.cinematic") then
            cinematicName = string.gsub(cinematicName, "ricochetMinigun.cinematic", "ricochet.cinematic")
        end

    end

    return cinematicName

end

function MapParticlesOption_GetBlockableCinematicsTable()
    return blockableCinematicsCache
end


function MapParticlesOption_UpdateBlockableCinamaticsCommanderInvisible(isOverhead)
    for _, cinematic in ipairs(blockableCinematicsCache) do
        if cinematic.commanderInvisible then
            cinematic:SetIsVisible(not isOverhead)
        end
    end
end

function MapParticlesOption_RecreateBlockableMapCinematics()

    if #blockableCinematicsCache == 0 then

        for _, cinematic in ipairs(blockableCinematicsValuesCache) do
            CreateCinematic(cinematic.className, cinematic.groupName, cinematic.values)
        end
    end
end

function MapParticlesOption_RemoveBlockableMapCinematics()

    for _, cinematic in ipairs(blockableCinematicsCache) do
        Client.DestroyCinematic(cinematic)
    end

    blockableCinematicsCache = {}
end


if Shared.GetThunderdomeEnabled() then
    Log("CLIENT - THUNDERDOME ENABLED!")
end

--
--Called as the map is being loaded to create the entities. If no group, groupName will be "".
--
function OnMapLoadEntity(className, groupName, values)

    if ThunderdomeEntityRemove(className, values) then
        Log("INFO: skipping loading of '%s' in Thunderdome-Mode", className)
        return
    end

    --Parse the map entity, checking if it needs to be changed out
    className, values = ThunderdomeEntitySwap( className, values )

    local season = GetSeason()
    -- set custom round start music if defined
    if className == "ns2_gamerules" then
    
        if values.roundStartMusic ~= nil and string.len(values.roundStartMusic) > 0 then
            gRoundStartMusic = values.roundStartMusic
        end
    
    -- Create render objects.
    elseif className == "color_grading" then
    
        -- Disabled because it's crashing, needs full refactor to working Renderer2 pipeline
        Print("color_grading map entity ignored (disabled)")
        --[[
        local renderColorGrading = Client.CreateRenderColorGrading()
        
        renderColorGrading:SetOrigin( values.origin )
        renderColorGrading:SetBalance( values.balance )
        renderColorGrading:SetBrightness( values.brightness )
        renderColorGrading:SetContrast( values.contrast )
        renderColorGrading:SetRadius( values.distance )
        renderColorGrading:SetGroup(groupName)
        --]]
        
    elseif className == "fog_controls" then
    
        Client.globalFogControls = values
        Client.SetZoneFogDepthScale(RenderScene.Zone_ViewModel, 1.0 / values.view_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_ViewModel, values.view_zone_color)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_SkyBox, 1.0 / values.skybox_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_SkyBox, values.skybox_zone_color)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_Default, 1.0 / values.default_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_Default, values.default_zone_color)
        
    elseif className == "fog_area_modifier" then
    
        assert(values.start_blend_radius > values.end_blend_radius, "Error: fog_area_modifier must have a larger start blend radius than end blend radius")
        table.insert(Client.fogAreaModifierList, values)
        
    elseif className == "minimap_extents" then
    
        if not Client.rules.numberMiniMapExtents then
            Client.rules.numberMiniMapExtents = 0
        end
        
        if values.useLegacyOverview ~= false then
            -- This map's overview was generated with the pre-build-320 overview.exe, meaning we have to use
            -- old code for blips to continue to map correctly to the overview image.  If nil, it simply
            -- indicates it's an old version of the level that has not been saved with a >=320 editor setup.
            -- The author can also set this value to true if they wish to keep the old overview.
            -- When opening an old map, the value "useLegacyOverview" will default to false if it is not found.
            Client.legacyMinimap = true
        end
        
        Client.rules.numberMiniMapExtents = Client.rules.numberMiniMapExtents + 1
        Client.minimapExtentScale = values.scale
        Client.minimapExtentOrigin = values.origin
        
    -- Only create the client side cinematic if it isn't waiting for a signal to start.
    -- Otherwise the server will create the cinematic.
    elseif className == "skybox" or (className == "cinematic" and (values.startsOnMessage == "" or values.startsOnMessage == nil)) then
    
        if IsGroupActiveInSeason(groupName, season) then
            CreateCinematic(className, groupName, values)
        end
    
    elseif className == "ambient_sound" then
    
        if IsGroupActiveInSeason(groupName, season) then
            local entity = AmbientSound()
            LoadEntityFromValues(entity, values)
            Client.PrecacheLocalSound(entity.eventName)
            table.insert(Client.ambientSoundList, entity)
            table.insert(Client.cachedAmbientSoundList, {className = className, groupName = groupName, values = values})
        end
        
    elseif className == Reverb.kMapName then
    
        local entity = Reverb()
        LoadEntityFromValues(entity, values)
        entity:OnLoad()
        
    elseif className == "pathing_settings" then
        ParsePathingSettings(values)
    
    elseif className == "location" then
    
        local coords = values.angles:GetCoords(values.origin)
        coords.xAxis = coords.xAxis * values.scale.x * 0.2395
        coords.yAxis = coords.yAxis * values.scale.y * 0.2395
        coords.zAxis = coords.zAxis * values.scale.z * 0.2395
        coords = coords:GetInverse()
        
        if not Client.locationList[values.name] then
            Client.locationList[values.name] = {}
        end
        
        table.insert(Client.locationList[values.name], coords)
    
    else
    
        -- $AS FIXME: We are special caasing techPoints for pathing right now :/
        if (className == "tech_point") then
            local coords = values.angles:GetCoords(values.origin)
            if not Pathing.GetLevelHasPathingMesh() then
                Pathing.CreatePathingObject(TechPoint.kModelName, coords, true)
                Pathing.AddFillPoint(values.origin)
            end
            
            -- Store a list of techpoint locations
            ConcedeSequence.AddTPLocation(coords.origin)
        end
        
        -- Allow the MapEntityLoader to load it if all else fails.
        LoadMapEntity(className, groupName, values)
        
    end
    
end

-- TODO: Change this to setting the alpha instead of visibility when supported
function SetCommanderPropState(isComm)

    for index, propPair in ipairs(Client.propList) do
        local prop = propPair[1]
        if prop.commAlpha < 1 then
            prop:SetIsVisible(not isComm)
        end
    end

    -- Blockable props are not included in the Client.propList
    MapParticlesOption_UpdateCommanderProps(isComm)

end

local function UpdateAmbientSounds(deltaTime)
    
    PROFILE("Client:UpdateAmbientSounds")

    local ambientSoundList = Client.ambientSoundList
    for index = 1,#ambientSoundList do
        local ambientSound = ambientSoundList[index]
        ambientSound:OnUpdate(deltaTime)
    end
    
end

local function UpdateTrailCinematics(deltaTime)

    PROFILE("Client:UpdateTrailCinematics")

    for i = 1, #Client.destroyTrailCinematics do
        local destroyCinematic = Client.destroyTrailCinematics[i]
        Client.DestroyTrailCinematic(destroyCinematic)
    end

    for i = 1, #Client.trailCinematics do
        local trailCinematic = Client.trailCinematics[i]
        trailCinematic:Update(deltaTime)
    end

end

local function UpdateWorldMessages()

    PROFILE("Client:UpdateWorldMessages")

    local removeEntries = { }
    
    for _, message in ipairs(Client.worldMessages) do
    
        if (Client.GetTime() - message.creationTime) >= message.lifeTime then
            table.insert(removeEntries, message)
        else
            message.animationFraction = (Client.GetTime() - message.creationTime) / message.lifeTime
        end
        
    end
    
    for _, removeMessage in ipairs(removeEntries) do
        table.removevalue(Client.worldMessages, removeMessage)
    end
    
end

local function UpdateDecals(deltaTime)
    PROFILE("Client:UpdateDecals")

    local reUseDecals = { }

    for i = 1, #Client.timeLimitedDecals do
    
        local decalEntry = Client.timeLimitedDecals[i]
        if decalEntry[2] > Shared.GetTime() then
            table.insert(reUseDecals, decalEntry)
        else
            Client.DestroyRenderDecal(decalEntry[1])
        end
    
    end
    
    Client.timeLimitedDecals = reUseDecals


end

Client._playingDangerMusic = false
Client.IsPlayingDangerMusic = function()
    return Client._playingDangerMusic
end


local optionsSent = false

local oldGameState = 0
local function CheckGameState()

  local entityList = Shared.GetEntitiesWithClassname("GameInfo")

  if entityList:GetSize() > 0 then

    local state = entityList:GetEntityAtIndex(0):GetState()
    
    if state ~= oldGameState then
      if state == kGameState.Started then
        ProfileLib.AddMarker("RoundStart")
      end
    
      oldGameState = state
    end
  end
end

function OnUpdateClient(deltaTime)
  
    Client.SetDebugText("Client.OnUpdateClient entry")

    PROFILE("Client:OnUpdateClient")
    
    UpdateTrailCinematics(deltaTime)
    UpdateDecals(deltaTime)
    UpdateWorldMessages()
    
    local player = Client.GetLocalPlayer()
    if player then

        --OnUpdateClientSeason() -- Can activate this to hide seasonal stuff after the game has started
        
        UpdateAmbientSounds(deltaTime)
        
        UpdateDSPEffects()
        
        UpdateTracers(deltaTime)
        
        --UpdateDangerEffects(player)
    end
    
    UpdatePowerPointLights()
    
    if not optionsSent then

        Client.UpdateInventory()
        optionsSent = true
        
    end

    CheckGameState()

    Client.SetDebugText("Client.OnUpdateClient exit")

end

function OnNotifyGUIItemDestroyed(destroyedItem)
    GetGUIManager():NotifyGUIItemDestroyed(destroyedItem)
end

local kAlwaysShowDoerTracers = set
{
    "LerkBite",
    "Railgun",
    "Hydra"
}

function CreateTracer(startPoint, endPoint, velocity, doer, effectName, residueEffectName)

    local shouldDoTracer =
            (not Shared.GetIsRunningPrediction() and Player.kTracersEnabled) or -- Tracers enabled
            (not doer or not doer.GetClassName) or -- Safety Check
            (not Player.kTracersEnabled and doer and doer.GetClassName and kAlwaysShowDoerTracers[doer:GetClassName()]) -- Tracers disabled except for a few.

    if shouldDoTracer then

        if not effectName then
        
            if doer.GetTracerEffectName then
                effectName = doer:GetTracerEffectName()
            else
                effectName = kDefaultTracerEffectName
            end
        
        end
        
        if not residueEffectName then
            
            if doer.GetTracerResidueEffectName then
                residueEffectName = doer:GetTracerResidueEffectName()
            end
            
        end

        local tracer = BuildTracer(startPoint, endPoint, velocity, effectName, FilterCinematicName(residueEffectName))
        if tracer then
            table.insert(Client.tracersList, tracer)
        end
    end
    
end

local function RemoveTracerFast(tbl, idx)
    if idx == #tbl then
        -- Remove from list if its the last one...
        tbl[idx] = nil
    else
        -- otherwise swap the one at the end of the list into its place, and take 1 off the end.
        tbl[idx] = tbl[#tbl] -- replace with end
        tbl[#tbl] = nil -- remove the copy from the end.
    end
end

function UpdateTracers(deltaTime)

    PROFILE("Client:UpdateTracers")
    
    for i=#Client.tracersList, 1, -1 do
        local tracer = Client.tracersList[i]
        if tracer:GetTimeToDie() then
            RemoveTracerFast(Client.tracersList, i)
            tracer:OnDestroy()
        else
            tracer:OnUpdate(deltaTime)
        end
    end

end

Event.Hook("Console_dump_tracer_info", function()
    
    Log("Dumping info for %s tracers", #Client.tracersList)
    for i=1, #Client.tracersList do
        local tracer = Client.tracersList[i]
        Log("tracer %s", i)
        Log("    effectName = %s", tracer.effectName)
        Log("    residueEffectName = %s", tracer.residueEffectName)
        Log("    tracerVelocity = %s", tracer.tracerVelocity)
        Log("    startPoint = %s", tracer.startPoint)
        Log("    lifetime = %s", tracer.lifetime)
        Log("    timePassed = %s", tracer.timePassed)
    end
    
end)

--
--Shows or hides the skybox(es) based on the specified state.
--
function SetSkyboxDrawState(skyBoxVisible)

    for index, skyBox in ipairs(Client.skyBoxList) do
        skyBox:SetIsVisible( skyBoxVisible )
    end

end


local function OnMapPreLoad()
    
    -- Clear our list of render objects, lights, props
    Client.propList = { }

    Client.lightList = { }

    Client.skyBoxList = { }

    Client.ambientSoundList = { }
    Client.cachedAmbientSoundList = { }

    Client.tracersList = { }
    
    Client.rules = { }
    Client.DestroyReverbs()
    Client.ResetSoundSystem()
    
end

local function CheckRules()

    --Client side check for game requirements (listen server)
    --Required to prevent scripting errors on the client that can lead to false positives
    if Client.rules.numberMiniMapExtents == nil then
        Shared.Message('ERROR: minimap_extent entity is missing from the level.')
        Client.minimapExtentScale = Vector(100,100,100)
        Client.minimapExtentOrigin = Vector(0,0,0)
    elseif Client.rules.numberMiniMapExtents > 1 then
        Shared.Message('WARNING: There are too many minimap_extents, There should only be one placed in the level.')
    end

end

--
--Callback handler for when the map is finished loading.
--
local function OnMapPostLoad()

    -- Set sound falloff defaults
    Client.SetMinMaxSoundDistance(7, 100)

    local injectEntityList = GetThunderdomeInjectEntities()
    if injectEntityList and #injectEntityList > 0 then
        Log("Have injectable entity list, parsing...")
        for i = 1, #injectEntityList do
            Log("%s", injectEntityList[i])
            local ieCls = injectEntityList[i].class
            local ieVals = injectEntityList[i].props
            Log("INJECTING Entity[ '%s' ] with data: %s", ieCls, ieVals)
            OnMapLoadEntity( ieCls, nil, ieVals )
        end
    end

    InitializePathing()
    CreateDSPs()
    Scoreboard_Clear()
    CheckRules()
    
    ConcedeSequence.CalculateAllTechpointCameraMoves()

end

--
--Returns the horizontal field of view adjusted so that regardless of the resolution,
--the vertical fov is a constant. standardAspect specifies the aspect ratio the game
--is designed to be played at.
--
function GetScreenAdjustedFov(horizontalFov, standardAspect)
        
    local actualAspect   = Client.GetScreenWidth() / Client.GetScreenHeight()
    
    local verticalFov    = 2.0 * math.atan(math.tan(horizontalFov * 0.5) / standardAspect)
    horizontalFov = 2.0 * math.atan(math.tan(verticalFov * 0.5) * actualAspect)

    return horizontalFov    

end

local function UpdateFogAreaModifiers(fromOrigin)

    local globalFogControls = Client.globalFogControls
    if globalFogControls then
    
        local viewZoneScale = globalFogControls.view_zone_scale
        local viewZoneColor = globalFogControls.view_zone_color
        
        local skyboxZoneScale = globalFogControls.skybox_zone_scale
        local skyboxZoneColor = globalFogControls.skybox_zone_color
        
        local defaultZoneScale = globalFogControls.default_zone_scale
        local defaultZoneColor = globalFogControls.default_zone_color
        
        for f = 1, #Client.fogAreaModifierList do
        
            local fogAreaModifier = Client.fogAreaModifierList[f]
            
            -- Check if the passed in origin is within the range of this fog area modifier.
            local distSq = (fogAreaModifier.origin - fromOrigin):GetLengthSquared()
            local startBlendRadiusSq = fogAreaModifier.start_blend_radius
            startBlendRadiusSq = startBlendRadiusSq * startBlendRadiusSq
            if distSq <= startBlendRadiusSq then
            
                local endBlendRadiusSq = fogAreaModifier.end_blend_radius
                endBlendRadiusSq = endBlendRadiusSq * endBlendRadiusSq
                local blendDistanceSq = startBlendRadiusSq - endBlendRadiusSq
                local distPercent = 1 - (math.max(distSq - endBlendRadiusSq, 0) / blendDistanceSq)
                 
                viewZoneScale = LerpNumber(viewZoneScale, fogAreaModifier.view_zone_scale, distPercent)
                viewZoneColor = LerpColor(viewZoneColor, fogAreaModifier.view_zone_color, distPercent)
                
                skyboxZoneScale = LerpNumber(skyboxZoneScale, fogAreaModifier.skybox_zone_scale, distPercent)
                skyboxZoneColor = LerpColor(skyboxZoneColor, fogAreaModifier.skybox_zone_color, distPercent)
                
                defaultZoneScale = LerpNumber(defaultZoneScale, fogAreaModifier.default_zone_scale, distPercent)
                defaultZoneColor = LerpColor(defaultZoneColor, fogAreaModifier.default_zone_color, distPercent)
                
                -- This only works with 1 fog area modifier currently.
                break
                
            end
            
        end
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_ViewModel, 1.0 / viewZoneScale)
        Client.SetZoneFogColor(RenderScene.Zone_ViewModel, viewZoneColor)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_SkyBox, 1.0 / skyboxZoneScale)
        Client.SetZoneFogColor(RenderScene.Zone_SkyBox, skyboxZoneColor)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_Default, 1.0 / defaultZoneScale)
        Client.SetZoneFogColor(RenderScene.Zone_Default, defaultZoneColor)
        
    end
    
end

local gShowDebugTrace = false
function SetShowDebugTrace(value)
    gShowDebugTrace = value
end

local kDebugTraceGUISize = Vector(40, 40, 0)
local function UpdateDebugTrace()

    if not debugTraceGUI then
    
        debugTraceGUI = GUI.CreateItem()
        debugTraceGUI:SetSize(kDebugTraceGUISize)
        debugTraceGUI:SetAnchor(GUIItem.Middle, GUIItem.Center)
        debugTraceGUI:SetPosition(-kDebugTraceGUISize * 0.5)
        
    end

    debugTraceGUI:SetIsVisible(gShowDebugTrace)
    if gShowDebugTrace then
    
        local player = Client.GetLocalPlayer()
        if player then
            
            local viewCoords = player:GetViewCoords()
            local normalTrace = Shared.TraceRay(viewCoords.origin, viewCoords.origin + viewCoords.zAxis * 100, CollisionRep.Default, PhysicsMask.CystBuild, EntityFilterAll())
            
            local color = normalTrace.fraction == 1 and Color(1, 0, 0, 0.5) or Color(1,1,1,0.5)
            debugTraceGUI:SetColor(color)
        
        end
    
    end

end

local hudDetail = nil
function Client.SetHudDetail(value)
    hudDetail = value
end

function Client.GetHudDetail()
    if not hudDetail then
        hudDetail = Client.GetOptionInteger("hudmode", kHUDMode.Full)
    end
    return hudDetail
end

local fovAdjustment = nil
function Client.SetFOVAdjustment(adjustment)
    fovAdjustment = Clamp(adjustment, 0, 20)
end

function Client.GetFOVAdjustment()
    if not fovAdjustment then
        fovAdjustment = Client.GetOptionFloat("fov-adjustment", Client.GetOptionFloat("graphics/display/fov-adjustment", 0) * 20)
    end
    return fovAdjustment
end

-- Return effective fov for the player, including options adjustment and scaling for screen resolution
function Client.GetEffectiveFov(player)
    
    local adjustRadians
    if gAdjustRadians ~= nil then
        adjustRadians = gAdjustRadians
    else
        local adjustValue = Client.GetFOVAdjustment() / 20
        adjustRadians = math.rad((1-adjustValue)*kMinFOVAdjustmentDegrees + adjustValue*kMaxFOVAdjustmentDegrees)
        
        -- Don't adjust the FOV for the commander.
        if player:isa("Commander") then
            adjustRadians = 0
        end
    end
        
    return player:GetRenderFov() + adjustRadians
end

--
--Called once per frame to setup the camera for rendering the scene.
--
local function OnUpdateRender()
    
    Infestation_UpdateForPlayer()
    UpdateFogVisibility()
    
    if OnUpdateRenderOverride then
        local success = OnUpdateRenderOverride()
        if success then
            return
        end
    end
    
    if ConcedeSequence and ConcedeSequence.UpdateRenderOverride then
        local success = ConcedeSequence.UpdateRenderOverride()
        if success then
            return
        end
    end
    
    local camera = Camera()
    local cullingMode = RenderCamera.CullingMode_Occlusion
    
    local player = Client.GetLocalPlayer()
    -- If we have a player, use them to setup the camera.
    if player ~= nil then
    
        local coords = player:GetCameraViewCoords(true)
        
        --UpdateFogAreaModifiers(coords.origin)
        
        camera:SetCoords(coords)
        
        camera:SetFov(Client.GetEffectiveFov(player))
        
        -- In commander mode use frustum culling since the occlusion geometry
        -- isn't generally setup for viewing the level from the outside (and
        -- there is very little occlusion anyway)
        if player:GetIsOverhead() then
            cullingMode = RenderCamera.CullingMode_Frustum
        end
        
        local horizontalFov = GetScreenAdjustedFov( camera:GetFov(), 4 / 3 )
        
        local farPlane = player:GetCameraFarPlane()
        
        -- Occlusion culling doesn't use the far plane, so switch to frustum culling
        -- with close far planes
        if farPlane then
            cullingMode = RenderCamera.CullingMode_Frustum
        else
            farPlane = 1000.0
        end
        
        gRenderCamera:SetCoords(camera:GetCoords())
        gRenderCamera:SetFov(horizontalFov)
        gRenderCamera:SetNearPlane(0.03)
        gRenderCamera:SetFarPlane(farPlane)
        gRenderCamera:SetCullingMode(cullingMode)
        Client.SetRenderCamera(gRenderCamera)
        
        local isFirstPerson = true
        if player.GetIsThirdPerson then
            isFirstPerson = not player:GetIsThirdPerson()
        end
        Client.SetFirstPersonSound(isFirstPerson)
        
        local outlinePlayers = Client.GetOutlinePlayers() and Client.GetLocalClientTeamNumber() == kSpectatorIndex

        HiveVision_SetEnabled( GetIsAlienUnit(player) or outlinePlayers )
        HiveVision_SyncCamera( gRenderCamera, player:isa("Commander") or outlinePlayers )
        
        EquipmentOutline_SetEnabled( GetIsMarineUnit(player) or outlinePlayers )
        EquipmentOutline_SyncCamera( gRenderCamera, player:isa("Commander") or outlinePlayers )
        
        if OptionsDialogUI_GetAtmospherics() then
            if player:GetShowAtmosphericLight() then
                EnableAtmosphericDensity()
            else
                DisableAtmosphericDensity()
            end
        end

    else
    
        Client.SetRenderCamera(nil)
        Client.SetFirstPersonSound(false)
        HiveVision_SetEnabled( false )
        EquipmentOutline_SetEnabled( false )
        
    end
    
    UpdateDebugTrace()
    
end

Client.DamageNumberLifeTime = GetAdvancedOption("damagenumbertime")

function Client.AddWorldMessage(messageType, message, position, entityId)

    -- Only add damage messages if we have it enabled
    if messageType ~= kWorldTextMessageType.Damage or Client.GetOptionBoolean( "drawDamage", true ) then

        -- If we already have a message for this entity id, update existing message instead of adding new one
        local time = Client.GetTime()

        local updatedExisting = false

        if messageType == kWorldTextMessageType.Damage then

            for _, currentWorldMessage in ipairs(Client.worldMessages) do

                if currentWorldMessage.messageType == messageType and
                        currentWorldMessage.entityId == entityId and entityId ~= nil and entityId ~= Entity.invalidId then

                    currentWorldMessage.creationTime = time
                    currentWorldMessage.position = position
                    currentWorldMessage.previousNumber = tonumber(currentWorldMessage.message)

                    -- Display only whole numbers, and save the decimal part to add later as it gets >= 1
                    local newWholePart = math.floor(message)
                    local newDecimalPart = message - math.floor(message)

                    currentWorldMessage.message = currentWorldMessage.message + newWholePart
                    currentWorldMessage.decimalBuffer = currentWorldMessage.decimalBuffer + newDecimalPart

                    if currentWorldMessage.decimalBuffer >= 1.0 then

                        local extraWholePart = math.floor(currentWorldMessage.decimalBuffer)
                        currentWorldMessage.message = currentWorldMessage.message + extraWholePart
                        currentWorldMessage.decimalBuffer = currentWorldMessage.decimalBuffer - extraWholePart

                    end

                    currentWorldMessage.minimumAnimationFraction = kWorldDamageRepeatAnimationScalar

                    updatedExisting = true
                    break

                end

            end

        end

        if not updatedExisting then

            local worldMessage = {}

            worldMessage.messageType = messageType

            -- Only Damage message types add to existing messages.
            -- Others only have string messages.
            if kWorldTextDamageTypes[messageType] then

                worldMessage.message = math.floor(message)
                worldMessage.decimalBuffer = (message - worldMessage.message)
            else

                worldMessage.message = message
                worldMessage.decimalBuffer = 0
            end

            worldMessage.position = position
            worldMessage.creationTime = time
            worldMessage.entityId = entityId
            worldMessage.animationFraction = 0

            if messageType == kWorldTextMessageType.CommanderError then

                worldMessage.lifeTime = kCommanderErrorMessageLifeTime

                local commander = Client.GetLocalPlayer()
                if commander then
                    commander:TriggerInvalidSound()
                end

            elseif kWorldTextDamageTypes[messageType] then

                worldMessage.lifeTime = Client.DamageNumberLifeTime

            else

                worldMessage.lifeTime = kWorldMessageLifeTime

            end

            table.insert(Client.worldMessages, worldMessage)

        end

    end

end

function Client.GetWorldMessages()
    return Client.worldMessages
end

function Client.CreateTrailCinematic(renderZone)

    local trailCinematic = TrailCinematic()
    trailCinematic:Initialize(renderZone)
    table.insert(Client.trailCinematics, trailCinematic)
    return trailCinematic
    
end

function Client.ResetTrailCinematic(trailCinematic)
    return trailCinematic:Destroy()    
end

function Client.DestroyTrailCinematic(trailCinematic, nextFrame)

    if nextFrame then
    
        table.insert(Client.destroyTrailCinematics, trailCinematic)
        return true
        
    end
    
    local success = trailCinematic:Destroy()
    return success and table.removevalue(Client.trailCinematics, trailCinematic)
    
end

local function OnClientConnected()
    --Log("   Client.lua  -  OnClientConnected()")
    if Shared.GetThunderdomeEnabled() then
    --Always force client full-update event when alt-tabbed, for timing events and connect message
        Client.SetLocalThunderdomeMode(true)
    end
end

--
--Called when the client is disconnected from the server.
--
local function OnClientDisconnected(reason)

    -- Clean up the render objects we created during the level load.
    DestroyLevelObjects()
    
    ClientUI.DestroyUIScripts()
    
    -- Hack to avoid script error if load hasn't completed yet.
    if Client.SetOptionString then
        Client.SetOptionString("lastServerMapName", "")
    end
    
end

local function SendAddBotCommands()

    ------------------------------------------
    --  If bots were requested via the main menu, add them now
    ------------------------------------------

    assert(kListenServerStartedViaMenuOptionKey) -- should have loaded w/ menu.
    assert(kStartServer_AddBotsKey) -- should have loaded w/ menu.
    
    -- Only load bots if the option is set, AND this listen server was started via the Start Server
    -- menu (instead of the map console command, for example).
    local startedFromMenu = Client.GetOptionBoolean(kListenServerStartedViaMenuOptionKey, false)
    Client.SetOptionBoolean(kListenServerStartedViaMenuOptionKey, false)
    
    if not startedFromMenu then
        return
    end
    
    local addBotsOption = Client.GetOptionBoolean(kStartServer_AddBotsKey, false)
    if not addBotsOption then
        return
    end
    
    local botCount = Client.GetOptionInteger(kStartServer_PlayerLimitKey, kStartServer_DefaultPlayerLimit)
    Shared.ConsoleCommand(string.format("sv_maxbots %d true", botCount))
    
    -- Add commander bots.
    Shared.ConsoleCommand("addbot 1 1 com")
    Shared.ConsoleCommand("addbot 1 2 com")
    botCount = botCount - 2
    
    -- Add regular bots.
    local marineBotCount = math.floor(botCount * 0.5)
    Shared.ConsoleCommand(string.format("addbots %d 1", marineBotCount))
    botCount = botCount - marineBotCount
    Shared.ConsoleCommand(string.format("addbots %d 2", botCount))
    
end


local function OnLoadComplete()
    
    Client.fullyLoaded = true
    
    -- Successfully connected, clear the password used.
    Client.SetOptionString(kLastServerPassword, "")

    Client.kWayPointsEnabled = GetAdvancedOption("wps")
    Client.kHintsEnabled = Client.GetOptionBoolean("showHints", true)
    
    CreateMainMenu()
    
    Render_SyncRenderOptions()
    Input_SyncInputOptions()
    HitSounds_SyncOptions()
    OptionsDialogUI_SyncSoundVolumes()
    
    HiveVision_Initialize()
    EquipmentOutline_Initialize()
    
    UpdatePlayerNicknameFromOptions()
    Lights_UpdateLightMode()
    PrecacheLightsAndProps()

    SendAddBotCommands()
    
    SendPlayerVariantUpdate()
    SendPlayerCallingCardUpdate()
    
    ------------------------------------------
    --  Stuff for first-time optimization dialog
    ------------------------------------------

    if Client.GetOptionBoolean("immediateDisconnect", false) then
        Client.SetOptionBoolean("immediateDisconnect", false)
        Shared.ConsoleCommand("disconnect")
    end

    ------------------------------------------
    --  Stuff for sandbox mode
    ------------------------------------------
    if Client.GetOptionBoolean("sandboxMode", false) then
        Client.SetOptionBoolean("sandboxMode", false)
        Shared.ConsoleCommand("cheats 1")
        Shared.ConsoleCommand("autobuild")
        Shared.ConsoleCommand("alltech")
        Shared.ConsoleCommand("fastevolve")
        Shared.ConsoleCommand("allfree")
        Shared.ConsoleCommand("sandbox")
    end
    
    PreLoadGUIScripts()
    
    currentLoadingTime = Shared.GetSystemTimeReal() - startLoadingTime
    Print("Loading took " .. ToString(currentLoadingTime) .. " seconds")

    --tell the server if we played the tutorial or not
    if Client.GetAchievement("First_0_1") then
        Client.SendNetworkMessage( "PlayedTutorial", {}, true)
    end

    Client.kMapParticlesEnabled = GetAdvancedOption("mapparticles")
    MapParticlesOption_Update()

    ApplySensitivityOptions()
    ApplyFOVOptions()
    MinimalParticlesOption_Update()

    GetGUIManager():CreateGUIScript("GUIDeathStats")
    GetGUIManager():CreateGUIScript("GUIGameEndStats")

    GUISetUserScale(GetAdvancedOption("uiscale"))
end

local function TimeoutDecals(materialName, origin, distance)

    local squaredDistance = distance * distance
    for i = 1, #Client.timeLimitedDecals do
    
        local decalEntry = Client.timeLimitedDecals[i]
        
        if (decalEntry[1]:GetCoords().origin - origin):GetLengthSquared() < squaredDistance then
            decalEntry[2] = Shared.GetTime() + 1
            decalEntry[3]:SetParameter("endTime", Shared.GetTime() + 1)
        end
    
    end

end

-- Called whenever the option lifetime changes.
function Client.UpdateTimeLimitedDecals()
    
    local lifetimeOption = Client.GetDefaultDecalLifetime()
    
    for i=1, #Client.timeLimitedDecals do
        
        local decalEntry = Client.timeLimitedDecals[i]
        local oldEndTime = decalEntry[2]
        local renderMaterial = decalEntry[3]
        local usesOptionLifetime = decalEntry[5]
        local decalLifetime = decalEntry[6]
        if usesOptionLifetime then
            local startTime = oldEndTime - decalLifetime
            local newEndTime = startTime + lifetimeOption
            renderMaterial:SetParameter("endTime", newEndTime)
            decalEntry[2] = newEndTime
            decalEntry[6] = lifetimeOption
        end
        
    end
    
end

local decalLifetime
function Client.GetDefaultDecalLifetime()
    
    if not decalLifetime then
        decalLifetime = Client.GetOptionFloat("graphics/decallifetime", 0.2) * kDecalMaxLifetime
    end
    
    return decalLifetime
    
end

function Client.SetDefaultDecalLifetime(lifetime)
    
    decalLifetime = lifetime
    Client.UpdateTimeLimitedDecals()
    
end

function Client.CreateTimeLimitedDecal(materialName, coords, scale, lifeTime)
    
    local usesOptionLifetime = false
    if not lifeTime then
        lifeTime = Client.GetDefaultDecalLifetime()
        usesOptionLifetime = true
    end
        
    if lifeTime ~= 0 then

        -- Create new decal
        local decal = Client.CreateRenderDecal()
        local material = Client.CreateRenderMaterial()
        material:SetMaterial(materialName)            
        decal:SetMaterial(material)
        decal:SetCoords(coords)
        
        -- Set uniform scale from parameter
        decal:SetExtents( Vector(scale, scale, scale) )
        material:SetParameter("scale", scale)
        
        local endTime = Shared.GetTime() + lifeTime
        material:SetParameter("endTime", endTime)
        
        -- timeout nearby decals using the same material, ignore too small decal
        if scale > 0.3 then
            TimeoutDecals(materialName, coords.origin, scale * 0.5)
        end
        
        table.insert(Client.timeLimitedDecals, {decal, endTime, material, materialName, usesOptionLifetime, lifeTime})

    end

end

function ApplyFOVOptions()

    local useTeamSpecificFov = Client.GetOptionBoolean("CHUD_FOVPerTeam", false)

    -- Default FOV option.
    local fov = Client.GetOptionFloat("fov-adjustment", Client.GetOptionFloat("graphics/display/fov-adjustment", 0) * 20)
    local player = Client.GetLocalPlayer()

    if useTeamSpecificFov and player then

        if player:isa("Alien") or player:isa("ReadyRoomEmbryo") then

            fov = Client.GetOptionFloat("CHUD_FOV_A", 0)

        elseif player:isa("Exo") or player:isa("Marine") or player:isa("ReadyRoomPlayer") then -- RRPlayer is base class of RREmbryo

            fov = Client.GetOptionFloat("CHUD_FOV_M", 0)

        end

    end

    Client.SetFOVAdjustment(fov)

end

function ApplySensitivityOptions()

    local sensitivity_perTeam = Client.GetOptionBoolean("CHUD_SensitivityPerTeam", false)
    local sensitivity_perLifeform = Client.GetOptionBoolean("CHUD_SensitivityPerLifeform", false)

    local sensitivity = -1
    local player = Client.GetLocalPlayer()

    if not player then
        return
    end

    if sensitivity_perTeam then

        if sensitivity_perLifeform then

            local eggTechId = kTechId.None
            if player:isa("Embryo") then
                eggTechId = player:GetGestationTechId()
            elseif player:isa("ReadyRoomEmbryo") then
                eggTechId = player:GetPreviousGestationTechId()
            end

            if player:isa("Marine") or player:isa("Exo") or (player:isa("ReadyRoomPlayer") and not player:isa("ReadyRoomEmbryo")) then
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_M", kDefaultSensitivity)
            elseif player:isa("Skulk") or eggTechId == kTechId.Skulk then
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_Skulk", kDefaultSensitivity)
            elseif player:isa("Gorge") or eggTechId == kTechId.Gorge then
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_Gorge", kDefaultSensitivity)
            elseif player:isa("Lerk") or eggTechId == kTechId.Lerk then
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_Lerk", kDefaultSensitivity)
            elseif player:isa("Fade") or eggTechId == kTechId.Fade then
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_Fade", kDefaultSensitivity)
            elseif player:isa("Onos") or eggTechId == kTechId.Onos then
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_Onos", kDefaultSensitivity)
            end

        else -- Just sensitivity per team.

            if player:isa("Alien") or player:isa("ReadyRoomEmbryo") then
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_A", kDefaultSensitivity)
            elseif player:isa("Exo") or player:isa("Marine") or player:isa("ReadyRoomPlayer") then -- RRPlayer is base class of RREmbryo, so we handle alien team first.
                sensitivity = Client.GetOptionFloat("CHUD_Sensitivity_M", kDefaultSensitivity)
            end

        end

    else -- Just regular mouse sensitivity. No special cases.
        sensitivity = Client.GetOptionFloat("input/mouse/sensitivity", kDefaultSensitivity)
    end

    if sensitivity > 0 then
        OptionsDialogUI_SetMouseSensitivity(sensitivity)
    end

end

local firstPersonSpectateUI
local function OnLocalPlayerChanged()

    local player = Client.GetLocalPlayer()

    -- Show and hide UI elements based on the type of player passed in.
    ClientUI.EvaluateUIVisibility(player)
    ClientResources.EvaluateResourceVisibility(player)
    
    HelpScreen_GetHelpScreen():OnLocalPlayerChanged()
    
    if player then
    
        player:OnInitLocalClient()
        
        if not Client.GetIsControllingPlayer() and not firstPersonSpectateUI then
            firstPersonSpectateUI = GetGUIManager():CreateGUIScript("GUIFirstPersonSpectate")
        elseif Client.GetIsControllingPlayer() and firstPersonSpectateUI then
        
            GetGUIManager():DestroyGUIScript(firstPersonSpectateUI)
            firstPersonSpectateUI = nil
            
        end

    end

    -- There are team and lifeform specific sensitivities, so they need to be reconfigured each time.
    ApplySensitivityOptions()

    -- Team specific FOV settings.
    ApplyFOVOptions()

    -- Apply ViewModel Option
    ViewModelOption_Update()

end
Event.Hook("LocalPlayerChanged", OnLocalPlayerChanged)

Event.Hook("ClientDisconnected", OnClientDisconnected)
Event.Hook("ClientConnected", OnClientConnected)
Event.Hook("UpdateRender", OnUpdateRender)
Event.Hook("MapLoadEntity", OnMapLoadEntity)
Event.Hook("MapPreLoad", OnMapPreLoad)
Event.Hook("MapPostLoad", OnMapPostLoad)
Event.Hook("UpdateClient", OnUpdateClient)
Event.Hook("NotifyGUIItemDestroyed", OnNotifyGUIItemDestroyed)
Event.Hook("LoadComplete", OnLoadComplete)

-- Debug command to test resolution scaling
-- Not super elegant, but provides easy test cases
local function swapres()
    if Shared.GetTestsEnabled() or Shared.GetCheatsEnabled() then
        local xres = Client.GetScreenWidth()
        local yres = Client.GetScreenHeight()
        
        if xres == 640 then
            xres = 3840
        elseif xres == 3840 then
            xres = 1920
        else
            xres = 640
        end
        
        if yres == 480 then
            yres = 2160
        elseif yres == 2160 then
            yres = 1080
        else
            yres = 480
        end
        
        Client.SetOptionInteger( kGraphicsXResolutionOptionsKey, xres)
        Client.SetOptionInteger( kGraphicsYResolutionOptionsKey, yres)
        Client.SetOptionString( kWindowModeOptionsKey, "fullscreen-windowed")
        Client.ReloadGraphicsOptions()
        Print(xres .. " " .. yres)
    else
        Shared.Message("This command requires cheats or tests enabled.")
    end
end
Event.Hook("Console_swapres", swapres)

Event.Hook("DebugState",
function()
    -- Leaving this here for future debugging convenience.
    local player = Client.GetLocalPlayer()
    if player then
        DebugPrint("active weapon id = %d", player.activeWeaponId )
    end
end)

Script.Load("lua/PostLoadMod.lua")

-- Initialize the camera at load time, so that the render setup will be
-- properly precached during the loading screen.
InitializeRenderCamera()

-- setup the time buffer for the killcam - 8 seconds long
--Client.SetTimeBuffer(8)
