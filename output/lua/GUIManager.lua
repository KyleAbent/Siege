-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIManager.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- Client only.
if Server then return end

Script.Load("lua/UtilityShared.lua")
Script.Load("lua/GUIAssets.lua")

kGUILayerDebugText = 0
kGUILayerPlayerNameTags = 1
kGUILayerPlayerHUDBackground = 2
kGUILayerDeathScreen = 3
kGUILayerChat = 4
kGUILayerPlayerHUD = 5
kGUILayerPlayerHUDForeground1 = 6
kGUILayerPlayerHUDForeground2 = 7
kGUILayerPlayerHUDForeground3 = 8
kGUILayerPlayerHUDForeground4 = 9
kGUILayerCommanderAlerts = 10
kGUILayerCommanderHUD = 11
kGUILayerLocationText = 12
kGUILayerMinimap = 13
kGUILayerMarineBuyMenu = 14 -- buy menu is big enough to touch marine minimap.
kGUILayerBigMap = 15
kGUILayerScoreboard = 16
kGUILayerCountDown = 17
kGUILayerTestEvents = 18
kGUILayerMainMenuNews = 19
kGUILayerMainMenu = 20
kGUILayerMainMenuServerDetails = 40
kGUILayerMainMenuDialogs = 60
kGUILayerTipVideos = 70
kGUILayerOptionsTooltips = 100
kGUILayerDebugUI = 9001

-- The Web layer must be much higher than the MainMenu layer
-- because the MainMenu layer inserts items above
-- kGUILayerMainMenu procedurally.
kGUILayerMainMenuWeb = 50

-- Check required because of material scripts.
if Client and Event then

    Script.Load("lua/menu/WindowManager.lua")
    Script.Load("lua/InputHandler.lua")
    
end

Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIUtility.lua")

local function CreateManager()
    local manager = GUIManager()
    manager:Initialize()
    return manager
end

class 'GUIManager'

-- 25 Hz default update interval. Should be enough for all animations
-- to be reasonably smooth
GUIManager.kUpdateInterval = 0.04

function GUIManager:Initialize()

    self.scripts = unique_set()
    self.scriptsSingleMap = {}
end

local gGUIManager
function GetGUIManager()
    return gGUIManager
end

function GUIManager:GetNumberScripts()
    return self.scripts:GetCount()
end

function GUIManager:CreateGUIScript(scriptName)

    local scriptPath = scriptName

    local result = StringSplit(scriptName, "/")
    scriptName = result[#result]

    local cls = _G[scriptName]
    
    -- Detect new GUI system GUIObject classes, and use the new functions for them.
    if classisa(scriptName, "GUIObject") then
        local newObj = CreateGUIObject(string.format("obj_%s", scriptName), cls, nil)
        return newObj
    end

    if not cls then

        Script.Load("lua/" .. scriptPath .. ".lua")
        cls = _G[scriptName]

    end

    if cls == nil then

        DebugPrint("Error: Failed to load GUI script named %s", scriptName)
        return nil

    else

        local newScript = cls()
        newScript._scriptName = scriptPath
        newScript:Initialize()

        -- set default update rate if not already set
        newScript.updateInterval = newScript.updateInterval or GUIManager.kUpdateInterval
        newScript.lastUpdateTime = 0
        newScript.nextUpdateTime = 0

        self.scripts:Insert(newScript)

        return newScript

    end
    
end

-- Only ever create one of this named script.
-- Just return the already created one if it already exists.
function GUIManager:CreateGUIScriptSingle(scriptName)

    local createdScript = self.scriptsSingleMap[scriptName]
    if createdScript then
        return createdScript
    end
    
    -- Not found, create the single instance.
    createdScript = self:CreateGUIScript(scriptName)
    self.scriptsSingleMap[scriptName] = createdScript

    return createdScript
end

function GUIManager:DestroyGUIScript(scriptInstance)
    
    -- Check for new GUI system scripts, and use the new functions instead.
    if scriptInstance:isa("GUIObject") then
        scriptInstance:Destroy()
        return true
    end
    
    -- Only uninitialize it if the manager has a reference to it.
    local scriptName = scriptInstance._scriptName
    if self.scripts:Remove(scriptInstance) then

        if scriptName then
            self.scriptsSingleMap[scriptName] = nil
        end
    
        scriptInstance:Uninitialize()
        return true
        
    end
    
    return false

end

-- Destroy a previously created single named script.
-- Nothing will happen if it hasn't been created yet.
function GUIManager:DestroyGUIScriptSingle(scriptName)
    local script = self.scriptsSingleMap[scriptName]
    if script then
        return self:DestroyGUIScript(script)
    end

    return false
end

function GUIManager:GetGUIScriptSingle(scriptName)
    
    return self.scriptsSingleMap[scriptName]

end

function GUIManager:NotifyGUIItemDestroyed(destroyedItem)

    if gDebugGUI then

        for _, script in ipairs(self.scripts:GetList()) do
            script:NotifyGUIItemDestroyed(destroyedItem)
        end
    
    end

end

local nextScript = 1
function GUIManager:Update(deltaTime)

    PROFILE("GUIManager:Update")
    
    if gDebugGUI then
        Client.ScreenMessage(gDebugGUIMessage)
    end

    local numScripts = self.scripts:GetCount()

    if numScripts == 0 then
        return
    end
    
    local now = Shared.GetTime()
    local sysTime = Shared.GetSystemTimeReal()
    
    local kMaxUpdateTime = 0.005 -- Limit the GUIManager.Update runtime so it doesn't cause massive frame spike

    if nextScript > numScripts then
        nextScript = 1
    end

    -- check runtime limit at end of iteration so at least one script updates per update
    for i = nextScript, numScripts do
        local script = self.scripts:GetValueAtIndex(i)
        if script and script:GetShouldUpdate() then

            if now >= script.nextUpdateTime then
                local dt = deltaTime
                if not script.deltaIsFrameTime and script.lastUpdateTime > 0 then
                    dt = now - script.lastUpdateTime
                end

                script.lastUpdateTime = now
                script:Update(dt)
                script.nextUpdateTime = now + (script.updateInterval or GUIManager.kUpdateInterval)

                if Shared.GetSystemTimeReal() - sysTime >= kMaxUpdateTime then
                    nextScript = i + 1
                    return
                end
            end

        end
    end

    for i = 1, nextScript - 1 do
        local script = self.scripts:GetValueAtIndex(i)
        if script and script:GetShouldUpdate() then
            if Shared.GetSystemTimeReal() - sysTime >= kMaxUpdateTime then
                nextScript = i
                return
            end

            if now >= script.nextUpdateTime then
                local dt = deltaTime
                if not script.deltaIsFrameTime and script.lastUpdateTime > 0 then
                    dt = now - script.lastUpdateTime
                end

                script.lastUpdateTime = now
                script:Update(dt)
                script.nextUpdateTime = now + (script.updateInterval or GUIManager.kUpdateInterval)
            end
        end
    end

end

function GUIManager:SendKeyEvent(key, down, amount)

    if not Shared.GetIsRunningPrediction() then

        for _, script in ipairs(self.scripts:GetList()) do
        
            if script:SendKeyEvent(key, down, amount) then
                return true
            end
            
        end

    end
    
    return false
    
end

function GUIManager:SendCharacterEvent(character)

    for _, script in ipairs(self.scripts:GetList()) do
    
        if script:SendCharacterEvent(character) then
            return true
        end
        
    end
    
    return false
    
end

function GUIManager:OnResolutionChanged(oldX, oldY, newX, newY)

    for _, script in ipairs(self.scripts:GetList()) do
        script:OnResolutionChanged(oldX, oldY, newX, newY)
    end

end

function GUIManager:CreateGraphicItem()
    return GUI.CreateItem()
end

function GUIManager:CreateTextItem()

    local item = GUI.CreateItem()

    -- Text items always manage their own rendering.
    item:SetOptionFlag(GUIItem.ManageRender)

    return item

end 

function GUIManager:CreateLinesItem()

    local item = GUI.CreateItem()

    -- Lines items always manage their own rendering.
    item:SetOptionFlag(GUIItem.ManageRender)

    return item
    
end

local function OnUpdateGUIManager(deltaTime)
    Client.SetDebugText("GUIManager.OnUpdateClient entry")
    if gGUIManager then
        gGUIManager:Update(deltaTime)
    end
    Client.SetDebugText("GUIManager.OnUpdateClient exit")
end

local function OnResolutionChanged(oldX, oldY, newX, newY)
    GetGUIManager():OnResolutionChanged(oldX, oldY, newX, newY)
end

-- check required because of material scripts
if Event then

    Event.Hook("UpdateClient", OnUpdateGUIManager)
    Event.Hook("ResolutionChanged", OnResolutionChanged)

    gGUIManager = gGUIManager or CreateManager()

    local function OnCommandDumbGUIScripts()
        
        local guiManager = GetGUIManager()
        
        local scriptsCount = {}
        for s = guiManager.scripts:GetCount(), 1, -1 do
            
            local script = guiManager.scripts:GetValueAtIndex(s)
            local count = scriptsCount[script._scriptName]
            
            scriptsCount[script._scriptName] = count ~= nil and count + 1 or 1
            
        end
        
        Print("script dump ----------------------")
        for name, count in pairs(scriptsCount) do
            Print("%s: %d", name, count)
        end
        Print("s------------------------------------")
        
        
    end
    Event.Hook("Console_dumpguiscripts", OnCommandDumbGUIScripts)

end
