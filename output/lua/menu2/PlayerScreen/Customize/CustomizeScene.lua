-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/PlayerScreen/Customize/CustomizeScene.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
--    Primary object to manage, update, and adjust sub-objects contained withiin the Customize render scene.
--    This class is primarily utilized for maintaining the "state" of both the Customize Screen render scene
--    and the objects contained in it. It's also acts as an accessor from the GUI in order to either query
--    or update the (sub)states of the objects and the scene views.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--[[
TODO / NICE-TO-HAVES
- Need Customizable Model -> Camera point linking
-- Using above, grants means to have OnFocus / OnBlur like behavior/actions (e.g. Marine turns to face camera when viewing it)
--]]

--[[
Idle Animations
    EXO
    - Will need to be able to "offset" model Yaw with changes to body_yaw (e.g. Exo)
    -- If above can be done, then being able to do "counter-offset"  (i.e. opposite direction) could allow for pseudo Marine head movement

    MARINE
    - Should use body_pitch to make them look up from time to time, as idle state. When camera is on Armor view, should
      change body_pitch to "neutral" (looking forward, laterally).

    LERK
    - When focusing the Lerk, it should hop up ad hover-flap. When camera moves away from it, after a tiny delay, it lands.

    ALL Lifeforms
    - Should randomly (at min + rand) play, at intervals, their "Fidget" animation (if those are still available).
--]]

Script.Load("lua/Utility.lua")
Script.Load("lua/AnimatedModel.lua") --This is included for simple non-graph based models (e.g. Rifle)
Script.Load("lua/GraphDrivenModel.lua")
Script.Load("lua/tweener/Tweener.lua")

Script.Load("lua/menu2/PlayerScreen/Customize/CustomizeSceneCameras.lua")


--Local Constants
local kUpVec = Vector(0,1,0)

local kDefaultAspect = 16/9

--Camera/View debug data
local camModel = PrecacheAsset("models/system/editor/camera_origin.model") --for Debugging

local debugCameraPositionTeam1 = Vector( 0, 2.1, -2.63 )
local debugCameraTargetTeam1 = Vector( 0.04, 1.45, 7.75 )

local debugCameraPositionTeam2 = Vector( 0, -5.1, -3.6 )
local debugCameraTargetTeam2 = Vector( 0.0, -13.45, 17.75 )

local debugCameraFov_Team1 = math.rad( 96 )
local debugCameraFov_Team2 = math.rad( 98 )

local debugCamCoords_Team1 = Coords.GetLookAt( debugCameraPositionTeam1, debugCameraTargetTeam1, kUpVec )
local debugCamCoords_Team2 = Coords.GetLookAt( debugCameraPositionTeam2, debugCameraTargetTeam2, kUpVec )


local function GetCustomizeScreenAdjustedFov( horizontalFov, viewAspect )
    local horizontalFov = math.rad(horizontalFov)
    local verticalFov = 2.0 * math.atan(math.tan(horizontalFov * 0.5) / (4/3) )
    horizontalFov = 2.0 * math.atan(math.tan(verticalFov * 0.5) * viewAspect)
    return horizontalFov 
end


---@class CustomizeScene
class "CustomizeScene"

--After init, camera is set to this Coord
CustomizeScene.kDefaultView = gCustomizeSceneData.kViewLabels.DefaultMarineView

CustomizeScene.kBackgroundCinematic = PrecacheAsset("cinematics/menu/customize_scene.cinematic")
CustomizeScene.kRenderTarget = "*customize_screen_cinematic"

CustomizeScene.kCinematicRenderSetup = "renderer/customize.render_setup"
--CustomizeScene.kCinematicRenderSetup = "renderer/Deferred.render_setup"

CustomizeScene.kSceneRenderMask = kCustomizeSceneRenderMask

CustomizeScene.kCameraNearPlane = 0.01
CustomizeScene.kCameraFarPlane = 1500

CustomizeScene.kSelectableMaterialStartTime = math.random(0.1, math.random(math.random(0.2,1), math.random(1, 2)))
CustomizeScene.kHighlightMaterialStartTime = math.random(0.1, math.random(math.random(0.5,1), math.random(1.5, 3)))

local gCustomizeScene
function GetCustomizeScene()
    if not gCustomizeScene then
        gCustomizeScene = CustomizeScene()
    end
    return gCustomizeScene
end


local kArcSceneObjectIdx = -1   --Simple cache when ARC Scene Object is loaded, used for view-transitions later
local kCommandStationObjectIdx = -1
local kMinigunExoObjectIdx = -1


function CustomizeScene:Initialize( viewSize )  --TODO Add "downsample" factor
    assert(viewSize and viewSize:GetLength() > 0)
    assert( gCustomizeSceneData and type(gCustomizeSceneData) == "table")

    --RenderCamera for this scene
    self.renderCamera = nil

    --Cinematic Background (as result Level file too)
    self.cinematic = nil

    --The Current Active scene View label (not the destination if a transition is active)
    self.activeViewLabel = gCustomizeSceneData.kDefaultViewLabel
    self.previousViewLabel = self.activeViewLabel

    --Simple object to hold the active CameraTransition, not have thing means the Camera is idle
    self.transition = nil

    --"global" to control if the Scene updates or not
    self.isActive = false

    --Intended size of the Render Target (note this can be influenced by GUI scaling, etc)
    self.viewSize = Vector()
    VectorCopy(viewSize, self.viewSize)

    --aspect ratio of the customize scene render area, used for per-view FOV adjustments
    self.viewAspect = self.viewSize.x / self.viewSize.y

    --fullscreen aspect ratio of client, useful for selecting specific FOV settings for camera views
    self.screenAspect = Client.GetScreenWidth() / Client.GetScreenHeight()

    --Tracker for the last time CustomizeScene was in Active state and updated
    self.lastUpdateTime = 0

    --Container for expiring sub-routines for this overall update loop
    --Have OnStart(), OnUpdate(), and OnComplete() events with interval rates for Update and timeout value used with startTime
    self.sceneEvents = {}

    self:InitBackground()
    self:InitRenderCamera()

    --Lookup table to hold Key/Value pairs of "special" models. Used to quickly access
    --a particular scene object via its index. Keys for this table are defined in 'specialIndex'
    --value in the gCustomizeSceneData.kSceneObjects table.
    self.specialModelHandles = {}

    --Alias to denote which "chunk" of the scene (Marines or Aliens) scene is setup for right now
    --this is used to skip updating models if they're not in the active view.
    self.activeContentSection = kTeam1Index

    --Simple flag to denote something in the Scene has changed, and update(s) should be run
    self.sceneDirty = false

    --Callback holder for triggering actions to GUI when camera is in "activation range" of the target view-label
    self.viewNearDistanceActiveCallback = nil

    --Flag to denote if Customize scene's debug drawing is enabled
    self.debugVisEnabled = false

    --Lookup table to link Scene Object name to Cosmetic Variant-type of all active variant values (after init and on user-change)
    self.objectsActiveVariantsList = {}

    --Table numerically indexed with all AnimatedModel or GraphDrivenModel objects in the entire customize scene
    self.sceneObjects = {}

    --reference table, numerically indexed, of objects that cosmetic selection applied to
    self.customizableModels = {}

    self:InitSceneObjects()

    --numerically indexed table storing instances of all Cinematics in the customize scene (one-shot cinematics are not included in this)
    self.sceneCinematics = {}

    self:InitSceneCinematics()

    self:RefreshOwnedItems()

    self.activeShoulderPatchIndex = self:GetShoulderOwnedPadIdByPadIndex( Client.GetOptionInteger("shoulderPad", 1) )

    self:InitCustomizableModels()

    --List of special callback "event" functions, which are contextually limited (i.e. don't require update every tick)
    self.eventHandlers = {}

    --Scratch / temporary RenderModel that is only created when a Scene Object is zoomed. Only renders in ViewRenderZone
    self.zoomedModel = nil
    self.zoomedModelCoords = nil

end

function CustomizeScene:InitBackground()
    assert(self.kBackgroundCinematic)

    self.cinematic = Client.CreateCinematic(RenderScene.Zone_Default, true)
    self.cinematic:SetRepeatStyle( Cinematic.Repeat_Endless )
    self.cinematic:SetCinematic( self.kBackgroundCinematic, self.kSceneRenderMask )
    --Required to keep visible as active/visible until RenderCamera is initialized, for fetching its camera

    self.skyBox = Client.CreateCinematic( RenderScene.Zone_SkyBox )
    self.skyBox:SetCinematic( gCustomizeSceneData.kSkyBoxCinematic, self.kSceneRenderMask )
    self.skyBox:SetRepeatStyle( Cinematic.Repeat_Endless )
    local skyboxCoords = Coords.GetLookAt( Vector(0,0,0), Vector(0,0,1), kUpVec )
    self.skyBox:SetCoords( skyboxCoords )

end

function CustomizeScene:InitRenderCamera()
    assert(self.cinematic)

    self.renderCamera = Client.CreateRenderCamera()
    self.renderCamera:SetRenderSetup( self.kCinematicRenderSetup )
    self.renderCamera:SetType( RenderCamera.Type_Perspective )
    self.renderCamera:SetCullingMode( RenderCamera.CullingMode_Frustum )
    self.renderCamera:SetRenderMask( self.kSceneRenderMask )

    self.renderCamera:SetNearPlane( self.kCameraNearPlane )
    self.renderCamera:SetFarPlane( self.kCameraFarPlane )
    
    self.renderCamera:SetTargetTexture( self.kRenderTarget, false, self.viewSize.x, self.viewSize.y )
    self.renderCamera:SetUsesTAA( false )

    local defaultView = gCustomizeSceneData.kDefaultView
    local coords = Coords.GetLookAt( defaultView.origin, defaultView.target, kUpVec )
    local defaultViewFov = GetCustomizeCameraViewTargetFov( defaultView.fov, self.screenAspect )
    local adjFov = GetCustomizeScreenAdjustedFov( defaultViewFov, self.viewAspect )
    
    self.renderCamera:SetCoords( coords )
    self.renderCamera:SetFov( adjFov )

    --Setting camera visiblity will control if the entire scene is rendered or not
    self.renderCamera:SetIsVisible( self.isActive )

    Client.SetMainCameraExclusionRectEnabled( self.isActive )

end

--Called on resolution changes, target/active views is all that matter, in-motion, we don't care about
function CustomizeScene:UpdateViewSize( newViewSize )
    assert(newViewSize)
    self.viewSize = Vector()
    VectorCopy(newViewSize, self.viewSize)
    self.screenAspect = Client.GetScreenWidth() / Client.GetScreenHeight()
    self.viewAspect = self.viewSize.x / self.viewSize.y
    self.renderCamera:SetTargetTexture( self.kRenderTarget, false, self.viewSize.x, self.viewSize.y )
    local viewData = gCustomizeSceneData.kCameraViewPositions[self.activeViewLabel]
    local viewFov = GetCustomizeCameraViewTargetFov( viewData.fov, self.screenAspect )
    local adjFov = GetCustomizeScreenAdjustedFov( viewFov, self.viewAspect )
    self.renderCamera:SetFov( adjFov )
end

function CustomizeScene:InitSceneObjects()
    assert(gCustomizeSceneData.kSceneObjects and #gCustomizeSceneData.kSceneObjects > 0)
    
    for i = 1, #gCustomizeSceneData.kSceneObjects do
        local data = gCustomizeSceneData.kSceneObjects[i]
        local newObject = {}

        newObject.name = data.name
        newObject.contentGroup = data.team
        newObject.static = data.isStatic
        newObject.customizable = data.customizable and data.customizable or false

        newObject.lastUpdateTime = 0  --used if we need to stagger or halt updates to a given model (i.e. static objects or animation rates)

        if newObject.customizable then
        --Cache scene object index for easy reference later when changing skins
            table.insert( self.customizableModels, i )
            
            if not self.objectsActiveVariantsList[newObject.name] then
                self.objectsActiveVariantsList[newObject.name] = {}
            end

            self.objectsActiveVariantsList[newObject.name].activeVariantId = nil --set later
            self.objectsActiveVariantsList[newObject.name].cosmeticId = (data.cosmeticId ~= nil and data.cosmeticId or nil)
        end

        newObject.highlight = false

        if data.isStatic then
            newObject.model = self:InitAnimatedModel( data )
        else
            newObject.model = self:InitGraphModel( data )
        end

        --Additive material that's indicative of something is selectable/usable
        if newObject.customizable then
            local initStartTime = math.random(math.random(), math.random(1.5, 3))

            if data.team == kTeam1Index then
                newObject.model:AddMaterial( gCustomizeSceneData.kMarineTeamSelectableMaterial )
                newObject.model:SetNamedMaterialParameter("startTime", initStartTime, gCustomizeSceneData.kMarineTeamSelectableMaterial)
            elseif data.team == kTeam2Index then
                newObject.model:AddMaterial( gCustomizeSceneData.kAlienTeamSelectableMaterial )
                newObject.model:SetNamedMaterialParameter("startTime", initStartTime, gCustomizeSceneData.kAlienTeamSelectableMaterial)
            end
        end

        self.sceneObjects[i] = newObject

    end

end

function CustomizeScene:InitAnimatedModel( data, renderZoneOverride, zoomed )
    assert(data and data.modelFile)
    
    local model = AnimatedModel()
    model:OnInitialized( data.modelFile, (renderZoneOverride ~= nil and renderZoneOverride or RenderScene.Zone_Default) )

    local modelAngles = Angles()
    if not zoomed then
        modelAngles.pitch = math.rad(data.defaultPos.angles.x)
        modelAngles.yaw = math.rad(data.defaultPos.angles.y)
        modelAngles.roll = math.rad(data.defaultPos.angles.z)
    elseif zoomed then --TODO set in config-data, or global const
        modelAngles.pitch = 0
        modelAngles.yaw = 0
        modelAngles.roll = 0
    end

    local coords = modelAngles:GetCoords( data.defaultPos.origin )
    if zoomed then
        coords.origin = self.renderCamera:GetCoords():GetInverse():TransformPoint( coords.origin )
    end
    
    model:SetCoords( coords )
    model:InstanceMaterials()
    model:SetRenderMask( self.kSceneRenderMask )
    model:SetIsVisible( true )
    model:SetCastsShadows( true )

    if data.defaultAnim then
        assert(data.defaultAnim ~= "")

        model:SetAnimation( data.defaultAnim )
        model:SetQueuedAnimation( data.defaultAnim )
        model:SetStaticAnimation( ( data.isStatic and data.defaultAnim ) and data.isStatic or false )

        if data.poseParams and not zoomed then
            for p = 1, #data.poseParams do
                local param = data.poseParams[p]
                assert(param.name and param.value)
                model:SetPoseParam(param.name, param.value)
            end
        end

        if zoomed then
            if data.zoomedPoseParams then
                for p = 1, #data.zoomedPoseParams do
                    local param = data.zoomedPoseParams[p]
                    assert(param.name and param.value)
                    model:SetPoseParam(param.name, param.value)
                end
            end
        end
    end

    return model
end

function CustomizeScene:InitGraphModel( data, renderZoneOverride, zoomed )
    assert(data and data.graphFile)

    local model = GraphDrivenModel()

    model:Initialize( data.modelFile, data.graphFile, (renderZoneOverride ~= nil and renderZoneOverride or RenderScene.Zone_Default) )

    local modelAngles = Angles()
    if zoomed then
        --TODO set in config-data, or global const
        modelAngles.pitch = 0
        modelAngles.yaw = 0
        modelAngles.roll = 0
    else
        modelAngles.pitch = math.rad(data.defaultPos.angles.x)
        modelAngles.yaw = math.rad(data.defaultPos.angles.y)
        modelAngles.roll = math.rad(data.defaultPos.angles.z)
    end

    local origin = data.defaultPos.origin
    if zoomed then
        origin = self.renderCamera:GetCoords():GetInverse():TransformPoint(origin)
    end

    local coords = modelAngles:GetCoords( origin )

    model:SetCoords( coords )
    --model:SetAlwaysRender( true )
    model:SetRenderMask( self.kSceneRenderMask )
    model:InstanceMaterials()
    model:SetIsVisible( true )
    model:SetCastsShadows( true )

    if data.poseParams and not zoomed then
        for p = 1, #data.poseParams do
            model:SetPoseParam(data.poseParams[p].name, data.poseParams[p].value)
        end
    end

    if data.inputParams and not zoomed then
        for p = 1, #data.inputParams do
            model:SetAnimationInput(data.inputParams[p].name, data.inputParams[p].value)
        end
    end

    if zoomed then
        if data.zoomedInputParams then
            for p = 1, #data.zoomedInputParams do
                model:SetAnimationInput(data.zoomedInputParams[p].name, data.zoomedInputParams[p].value)
            end
        end

        if data.zoomedPoseParams then
            for p = 1, #data.zoomedPoseParams do
                model:SetPoseParam(data.zoomedPoseParams[p].name, data.zoomedPoseParams[p].value)
            end
        end
    end

    return model
end

function CustomizeScene:InitSceneCinematics()
    assert(gCustomizeSceneData.kSceneCinematics and #gCustomizeSceneData.kSceneCinematics > 0)

    --Special handler for Hive wisps
    self.hiveWispsMap = {}

    for c = 1, #gCustomizeSceneData.kSceneCinematics do

        local data = gCustomizeSceneData.kSceneCinematics[c]

        self.sceneCinematics[c] = {}

        self.sceneCinematics[c].cinematic = Client.CreateCinematic( RenderScene.Zone_Default )
        self.sceneCinematics[c].cinematic:SetCinematic( data.fileName, self.kSceneRenderMask )
        self.sceneCinematics[c].cinematic:SetRepeatStyle( data.playbackType )
        self.sceneCinematics[c].cinematic:SetCoords( data.coords )

        if data.initVisible ~= nil and type(data.initVisible) == "boolean" then
        --Optionally hide cinematic per definition, but default to visible
            self.sceneCinematics[c].cinematic:SetIsVisible(data.initVisible)
        else
            self.sceneCinematics[c].cinematic:SetIsVisible(true)
        end


        if data.fileName == gCustomizeSceneData.kHiveWisps_Toxin then
            self.hiveWispsMap[kAlienStructureVariants.Toxin] = c

        elseif data.fileName == gCustomizeSceneData.kHiveWisps_Shadow then
            self.hiveWispsMap[kAlienStructureVariants.Shadow] = c

        elseif data.fileName == gCustomizeSceneData.kHiveWisps_Kodiak then
            self.hiveWispsMap[kAlienStructureVariants.Kodiak] = c

        elseif data.fileName == gCustomizeSceneData.kHiveWisps_Reaper then
            self.hiveWispsMap[kAlienStructureVariants.Reaper] = c

        elseif data.fileName == gCustomizeSceneData.kHiveWisps_Nocturne then
            self.hiveWispsMap[kAlienStructureVariants.Nocturne] = c
        
        elseif data.fileName == gCustomizeSceneData.kHiveWisps_Abyss then
            self.hiveWispsMap[kAlienStructureVariants.Abyss] = c
        
        elseif data.fileName == gCustomizeSceneData.kHiveWisps_Unearthed then
            self.hiveWispsMap[kAlienStructureVariants.Unearthed] = c

        elseif data.fileName == gCustomizeSceneData.kHiveWisps_Auric then
            self.hiveWispsMap[kAlienStructureVariants.Auric] = c

        elseif data.fileName == gCustomizeSceneData.kHiveWisps then
            self.hiveWispsMap[kAlienStructureVariants.Default] = c
        end

    end

    --Extra One-Shot cinematics (i.e. playback controled via code, not cinematic loop itself)
    self.macFlyby = nil
    self.minMacPlayTime = gCustomizeSceneData.kMacFlybyMinInterval
    self.lastMacPlayTime = 0
    self.macPlayTimeInterval = gCustomizeSceneData.kMacFlybyMinInterval
end

function CustomizeScene:GetScenePointsToScreenPointList( scenePoints )
    assert(scenePoints, "Invalid type for scene points")
    assert(#scenePoints > 0, "Scene points list empty")
    local screenPoints = {}
    for i = 1, #scenePoints do
        screenPoints[i] = self:GetScenePointToScreenSpacePoint( scenePoints[i] )
    end
    return screenPoints
end

--Note: this is relative to the Customize Scene render camera, and NOT the ENTIRE screen
function CustomizeScene:GetScenePointToScreenSpacePoint( scenePoint )
    assert(scenePoint, "Invalid type for Scene Point")
    
    local p = self.renderCamera:GetCoords():GetInverse():TransformPoint(scenePoint)
    local fov = self.renderCamera:GetFov()

    local w = math.tan(fov * 0.5)
    local h = math.tan(fov * 0.5) / self.viewAspect

    p.x = p.x / w
    p.y = p.y / h

    p.x = p.x / p.z
    p.y = p.y / p.z

    local screenCoords = Vector( ((-p.x + 1) * 0.5) * self.viewSize.x, ((-p.y + 1) * 0.5) * self.viewSize.y, 0 )
    return screenCoords
end

function CustomizeScene:SetCameraPerspective( coords, fov )
    if not self.debugVisEnabled then
        self.renderCamera:SetCoords(coords)
        local adjFov = GetCustomizeScreenAdjustedFov( fov, self.viewAspect )
        self.renderCamera:SetFov( adjFov )
    end
end

function CustomizeScene:TransitionToView( targetView, isTeamChange )
    --Log("CustomizeScene:TransitionToView( %s, %s )", targetview, isTeamChange)
    if self.transition then
    --existing transition running, use it's data to feed new one

        local iCoords = self.transition:GetCoords()
        local iFov = self.transition:GetFov()
        local iT = self.transition:GetTargetData()

        self.transition = nil
        self.transition = CameraTransition()
        self.transition:Init( targetView, nil, iCoords.origin, iT.target, iFov, isTeamChange, self.screenAspect )

    else
    --New transition from camera at rest
        self.transition = CameraTransition()
        self.transition:Init( targetView, self.activeViewLabel, nil, nil, nil, isTeamChange, self.screenAspect )
    end

    self.transition:SetDistanceActivationCallback( self.DistanceActivationResult )

    self.previousViewLabel = self.activeViewLabel

    --FIXME Not always toggling (inconsistent), tends to occur with rapid view changes
    for i = 1, #self.customizableModels do

        local scenObjIdx = self.customizableModels[i]
        local sceneObject = self.sceneObjects[scenObjIdx]

        if GetIsDefaultView( targetView ) and not GetIsDefaultView(self.previousViewLabel) then
        --Always toggle on the selectable material, when returning to a default view
            
            local selectableMaterial = GetObjectSelectableMaterial( sceneObject.contentGroup )
            local selectableStartTime = math.random(0.1, math.random(math.random(0.5,1), math.random(1.5, 3)))

            sceneObject.model:AddMaterial( GetObjectSelectableMaterial( sceneObject.contentGroup ) )
            sceneObject.model:SetNamedMaterialParameter("startTime", selectableStartTime, selectableMaterial)

        elseif not GetIsDefaultView( targetView ) then
        --Always toggle off the selectable material, as it can appear in the background of some views
            sceneObject.model:RemoveMaterial( GetObjectSelectableMaterial( sceneObject.contentGroup ) )
        end
    end

end

local objectsPerViewList = 
{
    [gCustomizeSceneData.kViewLabels.Armory] = { "Rifle", "Axe", "Pistol", "Welder", "Shotgun", "GrenadeLauncher", "Flamethrower", "HeavyMachineGun" },
    [gCustomizeSceneData.kViewLabels.Marines] = { "MarineLeft", "MarineCenter", "MarineRight" },
    [gCustomizeSceneData.kViewLabels.ExoBay] = { "ExoMiniguns", "ExoRailguns" },
    [gCustomizeSceneData.kViewLabels.MarineStructures] = { "CommandStation", "Extractor", "Mac", "Arc" },

    [gCustomizeSceneData.kViewLabels.AlienLifeforms] = { "Skulk", "Gorge", "Lerk", "Fade", "Onos", "Babbler", "BabblerTwo", "BabblerThree", "Hydra", "Clog", "BabblerEgg" },
    [gCustomizeSceneData.kViewLabels.AlienStructures] = { "Hive", "Harvester", "Egg", "Cyst", "Drifter" },
    [gCustomizeSceneData.kViewLabels.AlienTunnels] = { "Tunnel" },
}

--Helper function to manage toggling highlight material on/off for all customizable models of a given camera view
function CustomizeScene:ToggleViewHighlight( viewLabel )
    assert(viewLabel and objectsPerViewList[viewLabel])

    local objectsNames = objectsPerViewList[viewLabel]

    for i = 1, #self.customizableModels do
        local scenObjIdx = self.customizableModels[i]

        if table.icontains( objectsNames, self.sceneObjects[scenObjIdx].name ) then

            local sceneobjectData = GetSceneObjectInitData( self.sceneObjects[scenObjIdx].name )
            
            if self.sceneObjects[scenObjIdx].highlight then
                self.sceneObjects[scenObjIdx].model:RemoveMaterial( GetObjectHighlightMaterial( self.sceneObjects[scenObjIdx].contentGroup ) )
                self.sceneObjects[scenObjIdx].highlight = false
            else
                self.sceneObjects[scenObjIdx].model:AddMaterial( GetObjectHighlightMaterial( self.sceneObjects[scenObjIdx].contentGroup ) )
                self.sceneObjects[scenObjIdx].highlight = true
            end
        end
    end
end


-- View Specific special functions, which are triggered from self:Update() - but filtered/active when view-transition is "done"

local lastArcYawVal = 0.0
local curArcYawDir = -1
local arcYawRate = 0.2
local arcMaxPanYaw = 33
local deployPanDelay = -1
local arcYawPanTime = 0
function CustomizeScene:UpdateMarineStructuresViewAnimations(time, deltaTime)

    local arc = self.sceneObjects[kArcSceneObjectIdx]
    if arc and arc.model then
        
        if arcYawPanTime == 0 then
            arcYawPanTime = time
            
            if deployPanDelay == -1 then
                local model = Shared.GetModel(arc.model.modelIndex)
                if model then
                    local animIdx = model:GetSequenceIndex("deploy")
                    deployPanDelay = model:GetSequenceLength(animIdx)
                end
            end
        end
        
        if arcYawPanTime > 0 and arcYawPanTime + deployPanDelay > time then
        --don't pan until deploy animation done playing
            return
        end

        local newYaw = 0
        
        if curArcYawDir == -1 then
            newYaw = lastArcYawVal - (deltaTime + arcYawRate)
        elseif curArcYawDir == 1 then
            newYaw = lastArcYawVal + (deltaTime + arcYawRate)
        end

        if newYaw <= -arcMaxPanYaw then
            curArcYawDir = 1
        elseif newYaw >= arcMaxPanYaw then
            curArcYawDir = -1
        end

        arc.model:SetPoseParam("arc_yaw", newYaw)
        lastArcYawVal = newYaw
    end

end

--[[
--!!! This may not be worth the hassle, as the pose would need a "reset" period, lest it be of the jank
function CustomizeScene:UpdateMarineExosViewAnimations(time, deltaTime)

    local exo = self.sceneObjects[kArcSceneObjectIdx]
    if exo and exo.model then

        --TODO Have Exo get guns level (smoothly)
        --TODO have exo slightly "look around"

    end

end
--]]

local kLifeformSceneIndicies = {-1, -1, -1, -1, -1}
local kActiveLifeformTauntIdx = 0
local lifeformTauntStopTime = -1
local lastLifeformIndex = -1    --cache prev, so no back-2-back repeats
function CustomizeScene:UpdateAlienLifeformsViewAnimations(time, deltaTime)

    if kActiveLifeformTauntIdx > 0 then
        local sObj = self.sceneObjects[kLifeformSceneIndicies[kActiveLifeformTauntIdx]]
        if sObj and lifeformTauntStopTime == -1 then            
            local model = Shared.GetModel(sObj.model.modelIndex)
            if model then
                local animIdx = model:GetSequenceIndex("taunt")
                local animTime = model:GetSequenceLength(animIdx)
                lifeformTauntStopTime = animTime + time + 0.1
            end
        end

        if lifeformTauntStopTime >= time and sObj then
            sObj.model:SetAnimationInput("move", "idle")
        end
    end
end

--Cache specific Object IDs for future possible usage
function CustomizeScene:PrimeLookupSceneObjectIndicies()

    if kArcSceneObjectIdx == -1 then
        local o, aIdx = self:GetSceneObject("Arc")
        if aIdx then
            kArcSceneObjectIdx = aIdx
        end
    end

    if kCommandStationObjectIdx == -1 then
        local o, ccIdx = self:GetSceneObject("CommandStation")
        if ccIdx then
            kCommandStationObjectIdx = ccIdx
        end
    end

    --TODO Add other index captures (i.e. Exo-mini for pan)

    if kLifeformSceneIndicies[1] == -1 then
        local o, sIdx = self:GetSceneObject("Skulk")
        if sIdx then
            kLifeformSceneIndicies[1] = sIdx
        end
    end

    if kLifeformSceneIndicies[2] == -1 then
        local o, gIdx = self:GetSceneObject("Gorge")
        if gIdx then
            kLifeformSceneIndicies[2] = gIdx
        end
    end

    if kLifeformSceneIndicies[3] == -1 then
        local o, lkIdx = self:GetSceneObject("Lerk")
        if lkIdx then
            kLifeformSceneIndicies[3] = lkIdx
        end
    end

    if kLifeformSceneIndicies[4] == -1 then
        local o, fdIdx = self:GetSceneObject("Fade")
        if fdIdx then
            kLifeformSceneIndicies[4] = fdIdx
        end
    end
    
    if kLifeformSceneIndicies[5] == -1 then
        local o, onIdx = self:GetSceneObject("Onos")
        if onIdx then
            kLifeformSceneIndicies[5] = onIdx
        end
    end
end

function CustomizeScene:DistanceActivationResult( viewLabelActivation )

    local scene = GetCustomizeScene()

    --Make sure the various scene-object indexes are set and cached for use in later functions
    scene:PrimeLookupSceneObjectIndicies()

    --Trigger the ARC model to perform its deploy animation as Camera focused on its view
    if viewLabelActivation == gCustomizeSceneData.kViewLabels.MarineStructures then
        if kArcSceneObjectIdx > -1 and scene.sceneObjects[kArcSceneObjectIdx].model then
            scene.sceneObjects[kArcSceneObjectIdx].model:SetAnimationInput("deployed", true)
        end

        if kCommandStationObjectIdx > -1 and scene.sceneObjects[kCommandStationObjectIdx].model then
            scene.sceneObjects[kCommandStationObjectIdx].model:SetAnimationInput("occupied", false)
        end
    else
        if kArcSceneObjectIdx > -1 and scene.sceneObjects[kArcSceneObjectIdx].model then
            scene.sceneObjects[kArcSceneObjectIdx].model:SetAnimationInput("deployed", false)
            scene.sceneObjects[kArcSceneObjectIdx].model:SetPoseParam("arc_yaw", 0.0)   --reset
            arcYawPanTime = 0
            lastArcYawVal = 0
        end

        if kCommandStationObjectIdx > -1 and scene.sceneObjects[kCommandStationObjectIdx].model then
            scene.sceneObjects[kCommandStationObjectIdx].model:SetAnimationInput("occupied", true)
        end
    end

    --Randomly, randomize a taunt animation when viewing Lifeforms (but not everytime)
    if viewLabelActivation == gCustomizeSceneData.kViewLabels.AlienLifeforms then

        local r = math.random(0,1)
        if r <= 0.6 and kActiveLifeformTauntIdx == 0 then
            local rIdx = math.random(1, #kLifeformSceneIndicies)
            if lastLifeformIndex > 0 and rIdx == lastLifeformIndex then
                repeat
                    rIdx = math.random(1, #kLifeformSceneIndicies)
                until(lastLifeformIndex ~= rIdx)
            end
            lastLifeformIndex = rIdx
            kActiveLifeformTauntIdx = rIdx
        end

        if kActiveLifeformTauntIdx > 0 then
            local lfIdx = kLifeformSceneIndicies[kActiveLifeformTauntIdx]
            if lfIdx > -1 and scene.sceneObjects[lfIdx].model then 
                scene.sceneObjects[lfIdx].model:SetAnimationInput("move", "taunt")
            end
        end

    else
        if kActiveLifeformTauntIdx > 0 then
            scene.sceneObjects[kLifeformSceneIndicies[kActiveLifeformTauntIdx]].model:SetAnimationInput("move", "idle")
            lifeformTauntStopTime = -1
            kActiveLifeformTauntIdx = 0
        end
    end

    GetCustomizeScreen():OnViewLabelActivation( viewLabelActivation )
end

--TODO Add tweening and other timed animation elements (model rotating to camera, etc)


local sceneObjectNamesList = 
{
    ["CommandStation"] = "command_station",
    ["Extractor"] = "extractor",
    ["MarineLeft"] = "marine",
    ["MarineCenter"] = "marine",
    ["MarineRight"] = "marine",
    ["ExoMiniguns"] = "exo_mm",
    ["ExoRailguns"] = "exo_rr",
    ["Arc"] = "ARC",
    ["Mac"] = "MAC",
    ["Rifle"] = "rifle",
    ["Axe"] = "axe",
    ["Welder"] = "welder",
    ["Pistol"] = "pistol",
    ["Shotgun"] = "shotgun",
    ["GrenadeLauncher"] = "grenadelauncher",
    ["Flamethrower"] = "flamethrower",
    ["HeavyMachineGun"] = "hmg",

    ["Skulk"] = "skulk",
    ["Gorge"] = "gorge",
    ["Lerk"] = "lerk",
    ["Fade"] = "fade",
    ["Onos"] = "onos",
    ["Hive"] = "hive",
    ["Harvester"] = "harvester",
    ["Egg"] = "egg",
    ["Cyst"] = "cyst",
    ["FillerCyst"] = "cyst",
    ["Drifter"] = "drifter",
    ["Hydra"] = "hydra",
    ["Clog"] = "clog",
    ["Babbler"] = "babbler",
    ["BabblerTwo"] = "babbler",
    ["BabblerThree"] = "babbler",
    ["BabblerEgg"] = "babbler_egg",
    ["Tunnel"] = "tunnel",
}
local function GetCosmeticType( sceneObjName, sex )
    assert(sceneObjName)
    return sceneObjectNamesList[sceneObjName] and sceneObjectNamesList[sceneObjName] or false
end

local sceneObjectVariantOptionsKeys =
{
    ["CommandStation"] = "marineStructuresVariant",
    ["Extractor"] = "extractorVariant",
    ["MarineLeft"] = "marineVariant",
    ["MarineCenter"] = "marineVariant",
    ["MarineRight"] = "marineVariant",
    ["ExoMiniguns"] = "exoVariant",
    ["ExoRailguns"] = "exoVariant",
    ["Arc"] = "arcVariant",
    ["Mac"] = "macVariant",
    ["Rifle"] = "rifleVariant",
    ["Axe"] = "axeVariant",
    ["Welder"] = "welderVariant",
    ["Pistol"] = "pistolVariant",
    ["Shotgun"] = "shotgunVariant",
    ["GrenadeLauncher"] = "grenadeLauncherVariant",
    ["Flamethrower"] = "flamethrowerVariant",
    ["HeavyMachineGun"] = "hmgVariant",

    ["Skulk"] = "skulkVariant",
    ["Gorge"] = "gorgeVariant",
    ["Lerk"] = "lerkVariant",
    ["Fade"] = "fadeVariant",
    ["Onos"] = "onosVariant",
    ["Hive"] = "alienStructuresVariant",
    ["Harvester"] = "harvesterVariant",
    ["Egg"] = "eggVariant",
    ["Cyst"] = "cystVariant",
    ["FillerCyst"] = "cystVariant",
    ["Drifter"] = "drifterVariant",
    ["DrifterEgg"] = "drifterVariant",
    ["Hydra"] = "hydraVariant",
    ["Clog"] = "clogVariant",
    ["Babbler"] = "babblerVariant",
    ["BabblerTwo"] = "babblerVariant",
    ["BabblerThree"] = "babblerVariant",
    ["BabblerEgg"] = "babblerEggVariant",
    ["Tunnel"] = "alienTunnelsVariant",
}
local function GetVariantKey( sceneName )
    assert(sceneName)
    return sceneObjectVariantOptionsKeys[sceneName] and sceneObjectVariantOptionsKeys[sceneName] or false
end


function CustomizeScene:GetSceneObject( objectName, index )
    assert(objectName or index)

    if objectName then
        for i = 1, #self.sceneObjects do
            if objectName == self.sceneObjects[i].name then
                sceneIndex = i
                return self.sceneObjects[i], i
            end
        end
    else
        if self.sceneObjects[index] then
            return self.sceneObjects[index], index
        end
    end

    return nil, false
end

function CustomizeScene:GetActiveShoulderPatchIndex()
    return self.activeShoulderPatchIndex
end

function CustomizeScene:GetAvailablePatchIndex(patchIndex)
    for i = 1, #self.avaiableCosmeticItems["shoulderPatches"] do
        if self.avaiableCosmeticItems["shoulderPatches"][i] == patchIndex then
            return i
        end
    end
end

function CustomizeScene:GetActiveShoulderPatchItemId()
    return kShoulderPad2ItemId[self.avaiableCosmeticItems["shoulderPatches"][self.activeShoulderPatchIndex]]
end

function CustomizeScene:GetShoulderOwnedPadIdByPadIndex( padIdx )
    if padIdx == 0 then
        return 1
    end
    for k,v in ipairs(self.avaiableCosmeticItems["shoulderPatches"]) do
        if padIdx == v then
            return k
        end
    end
    return false
end

--dumb list of scene objects to apply updated variant data to
local variantSelectObjectsChangelist =  --?? Move to scene data file?
{
    [gCustomizeSceneData.kSceneObjectReferences.Marine] = { "MarineRight", "MarineLeft" },
    [gCustomizeSceneData.kSceneObjectReferences.CommandStation] = { "CommandStation" },
    [gCustomizeSceneData.kSceneObjectReferences.Extractor] = { "Extractor" },
    [gCustomizeSceneData.kSceneObjectReferences.Mac] = { "Mac" },
    [gCustomizeSceneData.kSceneObjectReferences.Arc] = { "Arc" },

    [gCustomizeSceneData.kSceneObjectReferences.Exo] = { "ExoMiniguns", "ExoRailguns" },

    [gCustomizeSceneData.kSceneObjectReferences.Rifle] = { "Rifle" },
    [gCustomizeSceneData.kSceneObjectReferences.Axe] = { "Axe" },
    [gCustomizeSceneData.kSceneObjectReferences.Pistol] = { "Pistol" },
    [gCustomizeSceneData.kSceneObjectReferences.Welder] = { "Welder" },
    [gCustomizeSceneData.kSceneObjectReferences.Shotgun] = { "Shotgun" },
    [gCustomizeSceneData.kSceneObjectReferences.Flamethrower] = { "Flamethrower" },
    [gCustomizeSceneData.kSceneObjectReferences.GrenadeLauncher] = { "GrenadeLauncher" },
    [gCustomizeSceneData.kSceneObjectReferences.HeavyMachineGun] = { "HeavyMachineGun" },

    [gCustomizeSceneData.kSceneObjectReferences.Hive] = { "Hive", },
    [gCustomizeSceneData.kSceneObjectReferences.Harvester] = { "Harvester", },
    [gCustomizeSceneData.kSceneObjectReferences.Egg] = { "Egg" },
    [gCustomizeSceneData.kSceneObjectReferences.Cyst] = { "Cyst", "FillerCyst" },
    [gCustomizeSceneData.kSceneObjectReferences.Drifter] = { "Drifter" },

    [gCustomizeSceneData.kSceneObjectReferences.Tunnel] = { "Tunnel" },
    
    [gCustomizeSceneData.kSceneObjectReferences.Skulk] = { "Skulk" },
    [gCustomizeSceneData.kSceneObjectReferences.Gorge] = { "Gorge", }, 
    [gCustomizeSceneData.kSceneObjectReferences.Lerk] = { "Lerk" },
    [gCustomizeSceneData.kSceneObjectReferences.Fade] = { "Fade" },
    [gCustomizeSceneData.kSceneObjectReferences.Onos] = { "Onos" },

    [gCustomizeSceneData.kSceneObjectReferences.Babbler] = { "Babbler", "BabblerTwo", "BabblerThree" },
    [gCustomizeSceneData.kSceneObjectReferences.Clog] = { "Clog" },
    [gCustomizeSceneData.kSceneObjectReferences.BabblerEgg] = { "BabblerEgg" },
    [gCustomizeSceneData.kSceneObjectReferences.Hydra] = { "Hydra" },

}

local marinesList = { "MarineLeft", "MarineCenter", "MarineRight" }

function CustomizeScene:InitCustomizableModels()
    
    local options = GetAndSetVariantOptions()
    local marineRightIndex = -1

    for i = 1, #self.customizableModels do 

        local scenObjIdx = self.customizableModels[i]
        local sceneObject = self.sceneObjects[scenObjIdx]
        local sceneObjectData = GetSceneObjectInitData(sceneObject.name)

        if sceneObject.model then
            
            local marineType = string.lower(options.sexType)
            if sceneObject.name == "MarineCenter" then
                marineType = marineType == "male" and "female" or "male"
            end

            if sceneObject.name == "MarineRight" then
                marineRightIndex = scenObjIdx
                self.activeMarineGenderType = firstToUpper(marineType)
            end

            local cosmeticType = GetCosmeticType( sceneObject.name, marineType )
            local variantKey = GetVariantKey( sceneObject.name )
            local newModelFile
            
            if sceneObjectData.staticVariant then
                local tempOptions = {}
                table.copy(options, tempOptions)
                tempOptions[variantKey] = sceneObjectData.staticVariant
                newModelFile = GetCustomizableModelPath( cosmeticType, marineType, tempOptions )
            else
                if sceneObject.name == "MarineLeft" or sceneObject.name == "MarineRight" then
                    if table.icontains(kRoboticMarineVariantIds,  options.marineVariant) then
                        marineType = "bigmac"
                    end
                end
                newModelFile = GetCustomizableModelPath( cosmeticType, marineType, options )
            end

            if newModelFile and sceneObjectData then

                if newModelFile ~= sceneObjectData.modelFile and newModelFile ~= nil then
                    
                    self.sceneObjects[scenObjIdx].model:Destroy()
                    self.sceneObjects[scenObjIdx].model = nil

                    local tData = sceneObjectData
                    tData.modelFile = newModelFile
                    if sceneObjectData.isStatic then
                        self.sceneObjects[scenObjIdx].model = self:InitAnimatedModel( tData )
                    else
                        self.sceneObjects[scenObjIdx].model = self:InitGraphModel( tData )
                    end

                    --Additive material that's indicative of something is selectable/usable
                    if sceneObjectData.customizable then
                        local initStartTime = math.random(math.random(), math.random(2, 4))

                        if sceneObjectData.team == kTeam1Index then
                            self.sceneObjects[scenObjIdx].model:AddMaterial( gCustomizeSceneData.kMarineTeamSelectableMaterial )
                            self.sceneObjects[scenObjIdx].model:SetNamedMaterialParameter("startTime", initStartTime, gCustomizeSceneData.kMarineTeamSelectableMaterial )
                        elseif sceneObjectData.team == kTeam2Index then
                            self.sceneObjects[scenObjIdx].model:AddMaterial( gCustomizeSceneData.kAlienTeamSelectableMaterial )
                            self.sceneObjects[scenObjIdx].model:SetNamedMaterialParameter("startTime", initStartTime, gCustomizeSceneData.kAlienTeamSelectableMaterial )
                        end
                    end

                end
                
            end

            --Default to full-variant list id (conversion to only-available list handled below and on cycle)
            self.objectsActiveVariantsList[sceneObject.name].activeVariantId = options[variantKey]

            if sceneObjectData.cosmeticId then
            --Only objects with a cosmeticId trigger changes, so safe to skip others (like Babbler)
                local variants = gCustomizeSceneData.kSceneObjectVariantsMap[sceneObjectData.cosmeticId]
                --Log("....Fetching Owned Variants by VariantID for  [ %s ]", sceneObject.name)
                self.objectsActiveVariantsList[sceneObject.name].activeVariantId = GetOwnedVariantIndexByVariantId( self.avaiableCosmeticItems[variantKey], options[variantKey], variants )
            end

            --This scene object ONLY uses material swapping for switching skins (same model)
            --Required to run initially as model was just loaded
            if sceneObjectData.usesMaterialSwapping then
                local newMat, matIdx = GetCustomizableWorldMaterialData( cosmeticType, marineType, options )
                if newMat ~= nil and matIdx ~= -1 then
                --Note: this delays the apply of the mat-swap until the model's Update is called again (e.g. first time Customize Screen is active/visible)
                    if type(newMat) == "table" then
                    --special-case for models that require more than one material to be set to compose a skin
                        for i = 1, #newMat do
                        --Materials are zero indexed
                            local idx = newMat[i].idx
                            local mat = newMat[i].mat
                            self.sceneObjects[scenObjIdx].model:SetMaterialOverrideDelayed( mat, idx )
                            i = i + 1
                        end
                    else
                        self.sceneObjects[scenObjIdx].model:SetMaterialOverrideDelayed( newMat, matIdx )
                    end
                else
                    self.sceneObjects[scenObjIdx].model:ClearOverrideMaterials()
                end
            end

            if sceneObjectData.usesHybridSkins then
                local isMatSwapped = GetIsVariantMaterialSwapped( cosmeticType, marineType, options )
                if isMatSwapped then
                    local newMat, matIdx = GetCustomizableWorldMaterialData( cosmeticType, marineType, options )
                    if newMat ~= nil and matIdx ~= -1 then
                        if type(newMat) == "table" then
                            for i = 1, #newMat do
                                local idx = newMat[i].idx
                                local mat = newMat[i].mat
                                self.sceneObjects[scenObjIdx].model:SetMaterialOverrideDelayed( mat, idx )
                                i = i + 1
                            end
                        else
                            self.sceneObjects[scenObjIdx].model:SetMaterialOverrideDelayed( newMat, matIdx )
                        end
                    else
                        self.sceneObjects[scenObjIdx].model:ClearOverrideMaterials()
                    end
                else
                    self.sceneObjects[scenObjIdx].model:ClearOverrideMaterials()
                end
            end

            --Shoulder Patch
            if table.icontains(marinesList, sceneObject.name) then
                if sceneObject.name == "MarineLeft" then
                    self.marineLeftObjectIndex = scenObjIdx
                elseif sceneObject.name == "MarineCenter" then
                    self.marineCenterObjectIndex = scenObjIdx
                elseif sceneObject.name == "MarineRight" then
                    self.marineRightObjectIndex = scenObjIdx
                end

                self.sceneObjects[scenObjIdx].model:SetMaterialParameter("patchIndex", options.shoulderPadIndex - 2)
            end
        end
    end

end

--TODO Add means to set variant value for all items that "share" a common id...in other words, Sets/Collections (e.g. Default, Forge, Nocturne, etc, etc)

function CustomizeScene:CyclePatches( direction )
    --Log("CustomizeScene:CyclePatches( %s )", direction)
    assert(self.marineRightObjectIndex)
    assert(self.activeShoulderPatchIndex)
    assert(self.avaiableCosmeticItems["shoulderPatches"])
    assert(direction == nil or ( direction == 1 or direction == -1 ))

    if not direction then
        direction = 1
    end

    local nextIdx = self.activeShoulderPatchIndex + 1
    local prevIdx = self.activeShoulderPatchIndex - 1

    if nextIdx > #self.avaiableCosmeticItems["shoulderPatches"] then
        nextIdx = 1
    end

    if prevIdx < 1 then
        prevIdx = #self.avaiableCosmeticItems["shoulderPatches"]
    end
    local ownsVariant

    assert(self.avaiableCosmeticItems["shoulderPatches"][nextIdx])
    assert(self.avaiableCosmeticItems["shoulderPatches"][prevIdx])

    local newPadActualIdx = direction == 1 and
        self.avaiableCosmeticItems["shoulderPatches"][nextIdx]
        or self.avaiableCosmeticItems["shoulderPatches"][prevIdx]

    self.activeShoulderPatchIndex = ( direction == 1 and nextIdx or prevIdx )
    local padItemId = kShoulderPad2ItemId[newPadActualIdx]
    ownsVariant = GetOwnsItem(padItemId)
    
    self.sceneObjects[self.marineLeftObjectIndex].model:SetMaterialParameter("patchIndex", newPadActualIdx - 2)
    self.sceneObjects[self.marineCenterObjectIndex].model:SetMaterialParameter("patchIndex", newPadActualIdx - 2)
    self.sceneObjects[self.marineRightObjectIndex].model:SetMaterialParameter("patchIndex", newPadActualIdx - 2)
    
    if ownsVariant then
        Client.SetOptionInteger( "shoulderPad", newPadActualIdx )
        SendPlayerVariantUpdate()
    end

    local padName = kShoulderPadNames[newPadActualIdx]
    return padName, ownsVariant
end


function CustomizeScene:CycleCosmetic( cosmeticId, direction )
    assert(cosmeticId)
    assert(direction == nil or ( direction == 1 or direction == -1 ))

    if not direction then
        direction = 1
    end

    if not gCustomizeSceneData.kSceneObjectVariantsMap[cosmeticId] then
        Log("Error: invalid variant identifier")
        return false
    end

    local variants = gCustomizeSceneData.kSceneObjectVariantsMap[cosmeticId]
    local nextVariantName
    local nextVariantId
    local nextVariantItemId
    local ownsVariantItem
    local availableVariantIndex
    local variantKey

    if variantSelectObjectsChangelist[cosmeticId] then

        local limit = direction > 0 and #variantSelectObjectsChangelist[cosmeticId] or 1
        local tick = direction > 0 and 1 or -1

        for idx = (direction > 0 and 1 or #variantSelectObjectsChangelist[cosmeticId]), limit, tick do

            local sceneObjName = variantSelectObjectsChangelist[cosmeticId][idx]

            if not variantKey then
                variantKey = GetVariantKey( sceneObjName )
            end

            if not nextVariantId then
                if direction == 1 then
                    nextVariantId, availableVariantIndex = GetNextAvailableVariant( variants, self.avaiableCosmeticItems[variantKey], self.objectsActiveVariantsList[sceneObjName].activeVariantId )
                elseif direction == -1 then
                    nextVariantId, availableVariantIndex = GetPrevAvailableVariant( variants, self.avaiableCosmeticItems[variantKey], self.objectsActiveVariantsList[sceneObjName].activeVariantId )
                end
            end

            if availableVariantIndex then
                self.objectsActiveVariantsList[sceneObjName].activeVariantId = availableVariantIndex
            end
            
            if not nextVariantName then
                nextVariantName = GetVariantName( GetVariantData( cosmeticId ), nextVariantId )
            end

            if not nextVariantItemId then
                nextVariantItemId = GetVariantItemId( GetVariantData( cosmeticId ), nextVariantId )
            end

            if not ownsVariantItem then
                ownsVariantItem = GetOwnsItem( nextVariantItemId )
            end

            local marineType 
            if table.icontains(kRoboticMarineVariantIds, nextVariantId) then
                marineType = cosmeticId == gCustomizeSceneData.kSceneObjectReferences.Marine and "bigmac" or nil
            else
                marineType = cosmeticId == gCustomizeSceneData.kSceneObjectReferences.Marine and Client.GetOptionString("sexType", "Male") or nil
            end
            local cosmeticType = GetCosmeticType( sceneObjName, marineType )

            local variantsTbl = {}
            variantsTbl[variantKey] = nextVariantId

            local sceneObject, objIdx = self:GetSceneObject( sceneObjName, nil )
            local sceneObjectData = GetSceneObjectInitData( sceneObjName )

            --This scene object ONLY uses material swapping for switching skins (same model)
            if sceneObjectData.usesMaterialSwapping then
                local newMat, matIdx = GetCustomizableWorldMaterialData( cosmeticType, marineType, variantsTbl )

                if newMat ~= nil and matIdx ~= -1 then
                --Note: this delays the apply of the mat-swap until the model's Update is called again
                    if type(newMat) == "table" then
                    --special-case for models that require more than one material to be set to compose a skin
                        for i = 1, #newMat do
                            local idx = newMat[i].idx
                            local mat = newMat[i].mat
                            self.sceneObjects[objIdx].model:SetMaterialOverride( mat, idx )
                            i = i + 1
                        end

                    else
                        self.sceneObjects[objIdx].model:SetMaterialOverride( newMat, matIdx )
                    end
                else
                    self.sceneObjects[objIdx].model:ClearOverrideMaterials()
                end
            else
            --Good ole model swapping, bleh
                
                local newModelFile = GetCustomizableModelPath( cosmeticType, marineType, variantsTbl )

                if self.sceneObjects[objIdx].model:GetModelFilename() ~= newModelFile and newModelFile ~= nil then
                    --FIXME check animation graph, and only destroy model when graph changes (if possible)
                    self.sceneObjects[objIdx].model:Destroy()
                    self.sceneObjects[objIdx].model = nil
    
                    local tData = sceneObjectData
                    tData.modelFile = newModelFile
                    if sceneObjectData.isStatic then
                        self.sceneObjects[objIdx].model = self:InitAnimatedModel( tData )
                    else
                        self.sceneObjects[objIdx].model = self:InitGraphModel( tData )
                    end
                end

                if sceneObjectData.usesHybridSkins then
                --Cosmetic uses a mix of material swapping and model swapping
                    local isMatSwapped = GetIsVariantMaterialSwapped( cosmeticType, marineType, variantsTbl )
                    if isMatSwapped then
                        local newMat, matIdx = GetCustomizableWorldMaterialData( cosmeticType, marineType, variantsTbl )
                        if newMat ~= nil and matIdx ~= -1 then
                            if type(newMat) == "table" then
                                for i = 1, #newMat do
                                    local idx = newMat[i].idx
                                    local mat = newMat[i].mat
                                    self.sceneObjects[objIdx].model:SetMaterialOverrideDelayed( mat, idx )
                                    i = i + 1
                                end
                            else
                                self.sceneObjects[objIdx].model:SetMaterialOverrideDelayed( newMat, matIdx )
                            end
                        end
                    else
                        self.sceneObjects[objIdx].model:ClearOverrideMaterials()
                    end
                end

            end

            if cosmeticId == gCustomizeSceneData.kSceneObjectReferences.Marine then
            --Update shoulder patch index to ensure it is set to active-selection on skin change
                local patchIndex = self.avaiableCosmeticItems["shoulderPatches"][self.activeShoulderPatchIndex]
                self.sceneObjects[objIdx].model:SetMaterialParameter("patchIndex", patchIndex - 2)
            end

        end

        if variantKey and ownsVariantItem then
            Client.SetOptionInteger(variantKey, nextVariantId)
            SendPlayerVariantUpdate() --FIXME This is a really wasteful network message
        end
    end

    return nextVariantName, ownsVariantItem, nextVariantItemId
end


function CustomizeScene:GetMarineGenderType()
    assert(self.activeMarineGenderType)
    return self.activeMarineGenderType
end

function CustomizeScene:CycleMarineGenderType()
    
    local curSex = Client.GetOptionString("sexType", "Male") == "Male" and "Female" or "Male" --toggle
    local variants = gCustomizeSceneData.kSceneObjectVariantsMap[ gCustomizeSceneData.kSceneObjectReferences.Marine ]
    local sexTypeLabel
    local modelsList = { "MarineRight", "MarineCenter", "MarineLeft" }

    for i = 1, #modelsList do

        local sceneObjName = modelsList[i]
        local cosmeticType = GetCosmeticType( sceneObjName, curSex )
        local variantKey = GetVariantKey( sceneObjName )
        local variantsTbl = {}

        local availVarIdxLbl
        if sceneObjName == "MarineCenter" then
        --Always make center "spec-ops"
            availVarIdxLbl = "special"
        else
            availVarIdxLbl = self.avaiableCosmeticItems[variantKey][ self.objectsActiveVariantsList[sceneObjName].activeVariantId ]
        end

        variantsTbl[variantKey] = GetFullVariantWithAvailableVariantIndex( availVarIdxLbl, variants )

        local newModelFile

        if sceneObjName == "MarineCenter" then --opposite of client selection
            local oppositeCurSex = curSex == "Male" and "Female" or "Male"
            newModelFile = GetCustomizableModelPath( cosmeticType, oppositeCurSex, variantsTbl )
        else
            newModelFile = GetCustomizableModelPath( cosmeticType, curSex, variantsTbl )
        end

        local sceneObject, objIdx = self:GetSceneObject( sceneObjName, nil )

        if self.sceneObjects[objIdx].model:GetModelFilename() ~= newModelFile and newModelFile ~= nil then

            local sceneObjectData = GetSceneObjectInitData(sceneObjName)
            self.sceneObjects[objIdx].model:Destroy()   --This is not ideal...
            self.sceneObjects[objIdx].model = nil

            local tData = sceneObjectData
            tData.modelFile = newModelFile
            self.sceneObjects[objIdx].model = self:InitGraphModel( tData )

        end

        --[[
        local variantIndex = 0
        if variantKey and table.icontains(textureIndexBasedObjects, sceneObjName) then
            variantIndex = variantsTbl[variantKey] - 1
            self.sceneObjects[objIdx].model:SetMaterialParameter("textureIndex", variantIndex)
        end
        ]]
        
        local patchIndex = self.avaiableCosmeticItems["shoulderPatches"][self.activeShoulderPatchIndex]
        self.sceneObjects[self.marineLeftObjectIndex].model:SetMaterialParameter("patchIndex", patchIndex - 2)
        self.sceneObjects[self.marineCenterObjectIndex].model:SetMaterialParameter("patchIndex", patchIndex - 2)
        self.sceneObjects[self.marineRightObjectIndex].model:SetMaterialParameter("patchIndex", patchIndex - 2)
    end

    Client.SetOptionString("sexType", firstToUpper(curSex))
    sexTypeLabel = firstToUpper(curSex)
    self.activeMarineGenderType = sexTypeLabel
    SendPlayerVariantUpdate() --FIXME This is a really wasteful network message

    return sexTypeLabel
end


--Should be called whenever a new camera view is set as desired active view (clears unpurchased skins to current/active owned)
function CustomizeScene:ResetViewVariantsToOwned( viewLabel )
    if GetIsDefaultView(viewLabel) then
        return
    end
    assert(viewLabel)

    if viewLabel == gCustomizeSceneData.kViewLabels.ShoulderPatches then
    --Only effects visual, not stored
        local padIdx = Client.GetOptionInteger("shoulderPad", 1)
        self.activeShoulderPatchIndex = self:GetAvailablePatchIndex(padIdx)
        self.sceneObjects[self.marineLeftObjectIndex].model:SetMaterialParameter("patchIndex", padIdx - 2)
        self.sceneObjects[self.marineCenterObjectIndex].model:SetMaterialParameter("patchIndex", padIdx - 2)
        self.sceneObjects[self.marineRightObjectIndex].model:SetMaterialParameter("patchIndex", padIdx - 2)
        return
    end
    
    local sceneObjectIds = gCustomizeSceneData.kSceneViewCustomizableObjectsMap[viewLabel]
    assert( #sceneObjectIds >= 1 )

    --Build list of all scene objects for the given 'viewLabel'
    local sceneObjects = {}
    for o = 1, #sceneObjectIds do   --TODO this list should be pre-cached, not built inline
        local t = variantSelectObjectsChangelist[sceneObjectIds[o]]
        if type(t) == "table" then
            for x = 1, #t do
                table.insertunique(sceneObjects, t[x])
            end
        else
            table.insertunique(sceneObjects, t[1])
        end
    end

    for i = 1, #sceneObjects do

        local objName = sceneObjects[i]
        
        local variantOptionKey = sceneObjectVariantOptionsKeys[ objName ]

        local variantData = {}
         --Note: saved value is from "full" variants list
        local savedVariant = Client.GetOptionInteger( variantOptionKey, 1 )
        
        variantData[variantOptionKey] = savedVariant

        local marineType = nil
        if viewLabel == gCustomizeSceneData.kViewLabels.Marines then
            marineType = table.icontains(kRoboticMarineVariantIds, savedVariant) and "bigmac" or Client.GetOptionString("sexType", "Male")
        end
        
        local cosmeticLabel = GetCosmeticType( objName, marineType )
        local sceneObject, objIdx = self:GetSceneObject( objName, nil )

        assert(sceneObject)
        assert(objIdx)

        local sceneObjectData = GetSceneObjectInitData(objName)
        local newModelFile = GetCustomizableModelPath( cosmeticLabel, marineType, variantData )

        if sceneObjectData.usesMaterialSwapping then
            local newMat, matIdx = GetCustomizableWorldMaterialData( cosmeticLabel, marineType, variantData )
                if newMat ~= nil and matIdx ~= -1 then
                --Note: this delays the apply of the mat-swap until the model's Update is called again
                    if type(newMat) == "table" then
                    --special-case for models that require more than one material to be set to compose a skin
                        for i = 1, #newMat do
                            local idx = newMat[i].idx
                            local mat = newMat[i].mat
                            self.sceneObjects[objIdx].model:SetMaterialOverride( mat, idx )
                            i = i + 1
                        end
                    else
                        self.sceneObjects[objIdx].model:SetMaterialOverride( newMat, matIdx )
                    end
                else
                    self.sceneObjects[objIdx].model:ClearOverrideMaterials()
                end

        elseif self.sceneObjects[objIdx].model:GetModelFilename() ~= newModelFile and newModelFile ~= nil then
            --TODO Check model vs graph, and only destroy when graph diffs from Model
            self.sceneObjects[objIdx].model:Destroy()
            self.sceneObjects[objIdx].model = nil

            local tData = sceneObjectData
            tData.modelFile = newModelFile
            if sceneObjectData.isStatic then
                self.sceneObjects[objIdx].model = self:InitAnimatedModel( tData )
            else
                self.sceneObjects[objIdx].model = self:InitGraphModel( tData )
            end
        end

        if sceneObjectData.usesHybridSkins then
        --Cosmetic uses a mix of material swapping and model swapping
            local isMatSwapped = GetIsVariantMaterialSwapped( cosmeticLabel, marineType, variantData )
            if isMatSwapped then
                local newMat, matIdx = GetCustomizableWorldMaterialData( cosmeticLabel, marineType, variantData )
                if newMat ~= nil and matIdx ~= -1 then
                    if type(newMat) == "table" then
                        for i = 1, #newMat do
                            local idx = newMat[i].idx
                            local mat = newMat[i].mat
                            self.sceneObjects[objIdx].model:SetMaterialOverrideDelayed( mat, idx )
                            i = i + 1
                        end
                    else
                        self.sceneObjects[objIdx].model:SetMaterialOverrideDelayed( newMat, matIdx )
                    end
                end
            else
                self.sceneObjects[objIdx].model:ClearOverrideMaterials()
            end
        end

        --Convert back into Owned/Available format for setting active indices
        local tmpVariants = gCustomizeSceneData.kSceneObjectVariantsMap[GetSceneObjectInitData(objName).cosmeticId]
        local tmpAvailVariants = self.avaiableCosmeticItems[variantOptionKey]
        local availIdx = GetAvailableVariantWithFullVariantList( tmpVariants, tmpAvailVariants, savedVariant )
        self.objectsActiveVariantsList[objName].activeVariantId = availIdx

        if viewLabel == gCustomizeSceneData.kViewLabels.Marines then
            local padIdx = Client.GetOptionInteger("shoulderPad", 1) --Always force reset
            self.sceneObjects[objIdx].model:SetMaterialParameter("patchIndex", padIdx - 2)
        end

    end
    
end

function CustomizeScene:RefreshOwnedItems()
    self.avaiableCosmeticItems = nil
    self.avaiableCosmeticItems = {}
    self.avaiableCosmeticItems = FetchAllAvailableItems()
end

function CustomizeScene:GetAllAvailableCosmetics()
    return self.avaiableCosmeticItems
end

function CustomizeScene:UpdateNewItemPurchased(purchasedItemId)
    assert(purchasedItemId)
    
    local UpdateOptionsAndMessage = function(variantId, itemId)
        local variantKey = gCustomizeSceneData.kVariantItemOptionsMap[itemId]
        assert(variantKey)
        Client.SetOptionInteger(variantKey, variantId) --???? have default value?
        SendPlayerVariantUpdate() --FIXME This is a really wasteful network message
    end
    
    --check shoulder patches first, as they're not as complicated and thus faster
    for i = 1, #kShoulderPad2ItemId do
        if kShoulderPad2ItemId[i] == purchasedItemId then
            Client.SetOptionInteger( gCustomizeSceneData.kShoulderPatchVariantOption , i)
            self.activeShoulderPatchIndex = i
            SendPlayerVariantUpdate() --FIXME This is a really wasteful network message
            return
        end
    end

    --slog through all variant data, as we have no means to know (given item data structures shortcomings) which variant was purchased
    for k, variantData in pairs(gCustomizeSceneData.kSceneObjectVariantsDataMap) do --TODO Refactor to not require pairs()
        for variant, data in pairs(variantData) do
            if data.itemId or data.itemIds then --skip default skins
                local itemVal = data.itemIds and data.itemIds or data.itemId
                if type(itemVal) == "table" then
                    for i = 1, #itemVal do
                        if purchasedItemId == itemVal[i] then
                            UpdateOptionsAndMessage(variant, purchasedItemId)
                            return
                        end
                    end
                else
                    if purchasedItemId == itemVal then
                        UpdateOptionsAndMessage(variant, purchasedItemId)
                        return
                    end
                end
            end
        end
    end
end

function CustomizeScene:GetCustomizableObjectVariantName( objectName )
    assert(objectName)
    assert(self.objectsActiveVariantsList[objectName])

    local variantSceneKey = GetVariantKey(objectName)
    local availVariants = self.avaiableCosmeticItems[variantSceneKey]
    local availVarId = self.objectsActiveVariantsList[objectName].activeVariantId
    local variants = gCustomizeSceneData.kSceneObjectVariantsMap[self.objectsActiveVariantsList[objectName].cosmeticId]
    local varData = GetVariantData( self.objectsActiveVariantsList[objectName].cosmeticId )
    local fullVarId = GetFullVariantWithAvailableVariantIndex( availVariants[availVarId], variants )
    local varName = GetVariantName( varData, fullVarId )

    return varName
end

function CustomizeScene:GetCustomizableObjectVariantId( objectName )
    assert(objectName)
    assert(self.objectsActiveVariantsList[objectName])
    local variantSceneKey = GetVariantKey(objectName)
    local availVariants = self.avaiableCosmeticItems[variantSceneKey]
    local availVarId = self.objectsActiveVariantsList[objectName].activeVariantId
    local variants = gCustomizeSceneData.kSceneObjectVariantsMap[self.objectsActiveVariantsList[objectName].cosmeticId]
    local varData = GetVariantData( self.objectsActiveVariantsList[objectName].cosmeticId )
    local fullVarId = GetFullVariantWithAvailableVariantIndex( availVariants[availVarId], variants )
    return fullVarId
end

function CustomizeScene:GetCustomizableObjectItemId( objectName )
    assert(objectName)
    assert(self.objectsActiveVariantsList[objectName])

    local variantSceneKey = GetVariantKey(objectName)
    local availVariants = self.avaiableCosmeticItems[variantSceneKey]
    local availVarId = self.objectsActiveVariantsList[objectName].activeVariantId
    local variants = gCustomizeSceneData.kSceneObjectVariantsMap[self.objectsActiveVariantsList[objectName].cosmeticId]
    local varData = GetVariantData( self.objectsActiveVariantsList[objectName].cosmeticId )
    local fullVarId = GetFullVariantWithAvailableVariantIndex( availVariants[availVarId], variants )
    local fullVariantData = GetVariantData( self.objectsActiveVariantsList[objectName].cosmeticId )
    local fullVariantItemId = GetVariantItemId( fullVariantData, fullVarId )
    return fullVariantItemId
end

--[[
function CustomizeScene:SetZoomedSceneObject( objectName )  --XX Might want to considering hiding ALL models that in view, for the active view
    --Log("CustomizeScene:SetZoomedSceneObject( %s )", objectName)
    assert(objectName)
    assert(self.zoomedModel == nil)

    local obj, idx = self:GetSceneObject(objectName)
    assert(obj, idx)
    local modelFile = self.sceneObjects[idx].model:GetModelFilename()
    local coords = self.sceneObjects[idx].model:GetCoords()
    local data = gCustomizeSceneData.kSceneObjects[idx]

    self.sceneObjects[idx].model:SetIsVisible(false)
    
    local variantKey = GetVariantKey( objectName )
    --TODO Make sure all existing cosmetics are applied (should patch index, etc, etc)

    if data.isStatic then
        self.zoomedModel = self:InitAnimatedModel( data, RenderScene.Zone_ViewModel, true )
    else
        self.zoomedModel = self:InitGraphModel( data, RenderScene.Zone_ViewModel, true )
    end

    local vmCoords = self.zoomedModel:GetCoords()
    --TODO finish

    --cached for later modification/tracking (duplicate of data.defaultPos override on purpose.)
    self.zoomedModelCoords = vmCoords

end

--?? Transitions / position tweening? Smooth pposition changes? If not, models will just "snap" to default positions (little janky)
function CustomizeScene:RemoveZoomdSceneObject( objectName )
    --Log("CustomizeScene:RemoveZoomdSceneObject( %s )", objectName)
    assert(objectName)
    assert(self.zoomedModel)

    self.zoomedModel:Destroy()
    self.zoomedModel = nil
    self.zoomedModelCoords = nil

    local obj, idx = self:GetSceneObject(objectName)
    assert(obj, idx)

    self.sceneObjects[idx].model:SetIsVisible(true)
end
]]

function CustomizeScene:TriggerMacFlyBy()
    self.macFlyby = Client.CreateCinematic( RenderScene.Zone_Default )
    self.macFlyby:SetCinematic( gCustomizeSceneData.kMacFlyby, self.kSceneRenderMask )
    self.macFlyby:SetRepeatStyle( Cinematic.Repeat_None )
    local macFlyCoords = Coords.GetLookAt( Vector(0,0,0), Vector(0,0,1), kUpVec )
    self.macFlyby:SetCoords( macFlyCoords )
end

function CustomizeScene:UpdateSceneExtras( time, deltaTime )

    local isMarineView = GetViewTeamIndex(self.activeViewLabel) == kTeam1Index
    if isMarineView then
        
        local triggerMacFlyby = 
            ( time >= self.minMacPlayTime and self.lastMacPlayTime == 0 ) --first time
            or
            ( self.lastMacPlayTime + self.macPlayTimeInterval < time )

        if triggerMacFlyby then
            self:TriggerMacFlyBy()
            local nextRandTime = (math.random() * gCustomizeSceneData.kMacFlybyMinInterval) + gCustomizeSceneData.kMacFlybyMinInterval * 0.5 + self.minMacPlayTime
            self.macPlayTimeInterval = gCustomizeSceneData.kMacFlybyMinInterval + math.floor(nextRandTime) + self.minMacPlayTime
            self.lastMacPlayTime = time
        end
    else
    --Alien Views

        --TODO trigger below only when skin update or view transition to aliens-view Starts
        local hiveVariantId = self.objectsActiveVariantsList["Hive"].activeVariantId
        for k,v in pairs(self.hiveWispsMap) do
            if self.sceneCinematics[v] then
                if hiveVariantId == k then
                    self.sceneCinematics[v].cinematic:SetIsVisible(true) 
                else
                    self.sceneCinematics[v].cinematic:SetIsVisible(false)
                end
            end
        end

    end

end

--Simple utility/ease function to generate the correct table structure and fields for self.eventHandlers processing
function CustomizeScene:BuildEventHandler( name, interval, timeLimit, onStartFunc, onUpdateFunc, onFinalFunc, updateDelay, data )
    assert(name)
    assert(timeLimit)

    if not interval and onUpdateFunc then
        Log("Error: cannot create CustomizeScene Event handler without interval value")
        return false
    end

    local event = --?? change to class instead? benefits?
    {
        lastUpdate = 0,
        startedTime = 0,
        --polling flag? Indicates it never expires unless of explicit removal? ...eh (BUT...that would be ideal for idle "animations")
        interval = interval ~= nil and interval or false,
        timeLimit = timeLimit ~= nil and timeLimit or false,
        startDelay = updateDelay ~= nil and updateDelay or false,
        OnStart = onUpdateFunc and onUpdateFunc or nil,
        OnUpdate = onStartFunc and onStartFunc or nil,
        OnFinalize = onFinalFunc and onFinalFunc or nil,
        data = data ~= nil and data or false
    }

    return event
end

local function HasEvent(handlers, event)
    for i = 1, #handlers do
        if handlers[i].name == event.name then
            return true
        end
    end
    return false
end

function CustomizeScene:AddSceneEvent( eventDef )
    assert( eventDef and type(eventDef) == "table" )
    assert( eventDef.OnStart or eventDef.OnUpdate or eventDef.OnFinalize ) --must have at least one

    if not HasEvent(self.eventHandlers, eventDef) then
        table.insert(self.eventHandlers, eventDef)

        if eventDef.OnStart and eventDef.startDelay == nil then
            eventDef:OnStart()
            self.eventHandlers[#self.eventHandlers].startedTime = Shared.GetTime()
        end
    else
        Log("Error: Cannot add duplicate CustomizeScene Events[%s]!", eventDef.name)
    end
end

function CustomizeScene:UpdateEventHandlers( time, deltaTime )

    if #self.eventHandlers > 0 then
        for e = 1, #self.eventHandlers do
            
            if self.eventHandlers[e].startedTime + self.eventHandlers[e].timeLimit >= time then
                if self.eventHandlers[e].OnFinalize then
                    self.eventHandlers[e]:OnFinalize()
                end
                table.remove(self.eventHandlers, e) --safe to do IN loop?
            end

            --TODO deal with startedTime and startDelay
            --if self.eventHandlers[e].startedTime == 0 

            if self.eventHandlers[e].OnUpdate then
                if self.eventHandlers[e].lastUpdate + self.eventHandlers[e].interval >= time then
                    self.eventHandlers[e].OnUpdate( time, deltaTime )
                end
            end

            self.eventHandlers[e].lastUpdate = time
        end
    end

end

function CustomizeScene:OnUpdate(time, deltaTime)

    if not self.isActive then
        return
    end

    if self.debugVisEnabled then
        self:UpdateDebugCamera(time, deltaTime)
    end

    self.lastUpdateTime = time

    self:UpdateSceneExtras( time, deltaTime )

    for m = 1, #self.sceneObjects do
        self.sceneObjects[m].model:Update(deltaTime)
    end

    self:UpdateEventHandlers(time, deltaTime)

    --TODO Streamline below, as this should be done in a more config-based like setup (e.g. Active-View update-routines [defined in setup])
    if self.activeViewLabel == gCustomizeSceneData.kViewLabels.MarineStructures and self.transition == nil then
        self:UpdateMarineStructuresViewAnimations(time, deltaTime)
    
    elseif self.activeViewLabel == gCustomizeSceneData.kViewLabels.AlienLifeforms and self.transition == nil then
        self:UpdateAlienLifeformsViewAnimations(time, deltaTime)

    end

    if self.transition then
        if self.transition:Update(deltaTime, self) then
            self.previousViewLabel = self.activeViewLabel
            self.activeViewLabel = self.transition:GetTargetView()
            self.transition = nil  --finished
        end
    end

end

function CustomizeScene:Resize( newSize )
    assert(newSize and newSize:GetLength() > 0) --len likely not valid
end

function CustomizeScene:SetViewLabelGUICallback( callback )
    self.viewNearDistanceActiveCallback = callback
end

function CustomizeScene:SetActive( active )
    
    self.isActive = active

    if not self.isActive and self.transition then
    --In order for RE-activation step to work, we need to immediately complete any active camera transitions
        self.previousViewLabel = self.activeViewLabel
        self.activeViewLabel = self.transition:GetTargetView()
        self.transition = nil
    end

    self.renderCamera:SetIsVisible( self.isActive )

    Client.SetMainCameraExclusionRectEnabled( self.isActive )

    for m = 1, #self.sceneObjects do
        if self.sceneObjects[m].contentGroup == self.activeContentSection then
        --Skip updating all models not in the current active view (minor perf saving)
            self.sceneObjects[m].model:SetIsVisible( self.isActive ) --actually helps?
        end
    end
end

function CustomizeScene:GetActive()
    return self.isActive
end

function CustomizeScene:SetSceneView( viewLabel )
    assert(viewLabel)

    local viewData = gCustomizeSceneData.kCameraViewPositions[viewLabel]

    if viewData and type(viewData) == "table" then
        local coords = Coords.GetLookAt( viewData.origin, viewData.target, kUpVec )
        local viewFov = GetCustomizeCameraViewTargetFov( viewData.fov, self.screenAspect )
        local fov = GetCustomizeScreenAdjustedFov( viewFov, self.viewAspect )
        self.renderCamera:SetFov( fov )
        self.renderCamera:SetCoords( coords )
    else
        Log("Error: unrecognized view label[%d]", viewLabel)
    end

end

function CustomizeScene:ClearTransitions( targetViewLabel )
    self.transition = nil
    self:SetSceneView(targetViewLabel)
end

local gDebugCamModel = nil
function CustomizeScene:UpdateDebugCamera(time, deltaTime)

    if gDebugCamModel == nil then
        gDebugCamModel = AnimatedModel()
        gDebugCamModel:OnInitialized( camModel, RenderScene.Zone_Default )
        gDebugCamModel:SetRenderMask( self.kSceneRenderMask )
        gDebugCamModel:InstanceMaterials()
        gDebugCamModel:SetIsVisible( true )
        gDebugCamModel:SetCastsShadows(false)
        gDebugCamModel:SetStaticAnimation(true)
    end

    local camCoords

    if self.transition then
        camCoords = self.transition:GetCoords() 
        --TODO spawn orig/target objects for current transition (cinematics?)  ..can't use DebugDrawXYZ, due to no render mask support
    else
        local activeCamData = gCustomizeSceneData.kCameraViewPositions[self.activeViewLabel]
        camCoords = Coords.GetLookAt( activeCamData.origin, activeCamData.target, kUpVec )
    end

    gDebugCamModel:SetCoords( camCoords )

    local isMarineView = GetViewTeamIndex(self.activeViewLabel) == kTeam1Index
    self.renderCamera:SetCoords( isMarineView and debugCamCoords_Team1 or debugCamCoords_Team2 )
    self.renderCamera:SetFov( isMarineView and debugCameraFov_Team1 or debugCameraFov_Team2 )

end

function CustomizeScene:Destroy()
    self.transition = nil

    Client.DestroyRenderCamera( self.renderCamera )

    Client.DestroyCinematic( self.cinematic )
    Client.DestroyCinematic( self.skyBox )
    
    if self.macFlyby ~= nil then
        Client.DestroyCinematic(self.macFlyby)
    end

    for m = 1, #self.sceneObjects do
        self.sceneObjects[m].model:Destroy()
        self.sceneObjects[m] = nil
    end
    self.sceneObjects = nil

    for c = 1, #self.sceneCinematics do
        Client.DestroyCinematic( self.sceneCinematics[c].cinematic )
        self.sceneCinematics[c] = nil
    end
    self.sceneCinematics = nil

    for h = 1, #self.hiveWispsMap do
        Client.DestroyCinematic( self.hiveWispsMap[h].cinematic )
        self.hiveWispsMap[h] = nil
    end
    self.hiveWispsMap = nil

    if gDebugCamModel then
        --TODO
    end
end


function CustomizeScene:ToggleDebugView()
    self.debugVisEnabled = not self.debugVisEnabled
    Log("CustomizeScene Debug %s", self.debugVisEnabled and "Enabled" or "Disabled")

    if self.debugVisEnabled then
    --Save
        self._cacheCamCoords = self.renderCamera:GetCoords()
        self._cacheCamFov = self.renderCamera:GetFov()
        self._cacheActiveView = self.activeViewLabel

    elseif self._cacheCamCoords ~= nil and self._cacheCamFov ~= nil then 
    --Restore
        self.renderCamera:SetCoords( self._cacheCamCoords )
        self.renderCamera:SetFov( self._cacheCamFov )
        self.activeViewLabel = self._cacheActiveView
        
        gDebugCamModel:SetIsVisible( false )

        self._cacheCamCoords = nil
        self._cacheCamFov = nil
        self._cacheActiveView = nil
    end
end
Event.Hook("Console_cs_debug", function() GetCustomizeScene():ToggleDebugView() end)

Event.Hook("Console_cs_dumpcam", function()

    local scene = GetCustomizeScene()
    local label = gCustomizeSceneData.kViewLabels[scene.activeViewLabel]
    local cFov = scene.renderCamera:GetFov()
    local camViewData = gCustomizeSceneData.kCameraViewPositions[scene.activeViewLabel]
    local targetFov = GetCustomizeCameraViewTargetFov( camViewData.fov, scene.screenAspect )
    local saFov = GetCustomizeScreenAdjustedFov( targetFov, scene.viewAspect )
    Log("-------------------------------------------------")
    Log("  Customize Scene - Camera Dump")
    Log("")
    Log("\t Label: [%s]", label)
    Log("\t FOV: %s", cFov)
    Log("\t ViewAspect: %s", scene.viewAspect)
    Log("\t\t Size-Adjusted FOV: %s",saFov)
    Log("")

end)

local function SetSceneView( str )
    local cs = GetCustomizeScene()

    cs.transition = nil --clear active camera control

    if str == "marines" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.Marines )
    elseif str == "exobay" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.ExoBay )
    elseif str == "armory" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.Armory )
    elseif str == "patches" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.ShoulderPatches )
    elseif str == "marine_struct" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.MarineStructures )

    elseif str == "vent" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.TeamTransition )

    elseif str == "aliens" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.DefaultAlienView )
    elseif str == "alien_struct" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.AlienStructures )
    elseif str == "alien_lifes" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.AlienLifeforms )
    elseif str == "alien_tunnel" then
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.AlienTunnels )

    else
        cs:SetSceneView( gCustomizeSceneData.kViewLabels.DefaultMarineView )
    end

end
Event.Hook("Console_cs_setview", SetSceneView)


local DumpAllAvailableCosmetics = function()
    local cs = GetCustomizeScene()
    
    local items = cs.avaiableCosmeticItems
    Log(ToString(items))
end
Event.Hook("Console_dumpavailitems", DumpAllAvailableCosmetics)

Event.Hook("Console_cs_setres", function(x, y)
    assert(x ~= nil and y ~= nil, "X & Y resolution values required")
    local x = tonumber(x)
    local y = tonumber(y)
    Log("Setting resolution to: %s by %s", x, y)
    Client.SetOptionInteger( kGraphicsXResolutionOptionsKey, x)
    Client.SetOptionInteger( kGraphicsYResolutionOptionsKey, y)
    Client.ReloadGraphicsOptions()
end)

local csCurResIdx = 1
local csResTbl = { 
    [1] = { 1920, 1080 },    --16x9
    [2] = { 1920, 1200 },   --16x10
    [3] = { 1600, 1200 },   --4x3
    [4] = { 2560, 1080 },   --21x9
}
Event.Hook("Console_cs_swapres", function()
    local nr = csCurResIdx + 1
    if nr > 4 then
        nr = 1
    end
    csCurResIdx = nr
    local res = csResTbl[csCurResIdx]
    local x = res[1]
    local y = res[2]
    Log("Setting resolution to: %s by %s   -   Aspect: %s", x, y, GetScreenAspectIndex( x/y ))
    Client.SetOptionInteger( kGraphicsXResolutionOptionsKey, x)
    Client.SetOptionInteger( kGraphicsYResolutionOptionsKey, y)
    Client.ReloadGraphicsOptions()
end)

Event.Hook("Console_cs_setfov", function(fov)
    assert(fov, "FOV number required")
    local cs = GetCustomizeScene()
    local nf = tonumber(fov)
    Log("Setting CustomizeScene Camera FOV to: %s", nf)
    cs.renderCamera:SetFov( GetCustomizeScreenAdjustedFov( nf, cs.viewAspect ) )
end)