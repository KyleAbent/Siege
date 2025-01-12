-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudTopBar.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Base class for a top bar that holds many top bar objects.  Mainly just a glorified layout.
--
--  Properties
--      TeamNumber      The team number that this top bar is associated with.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

---@class GUIHudTopBar : GUIListLayout
local baseClass = GUIListLayout
class "GUIHudTopBar" (baseClass)

local function FindInstantiatedClass(topBar, objClassName)
    for i=1, #topBar.objects do
        if topBar.objects[i]:isa(objClassName) then
            return topBar.objects[i], i
        end
    end
    return nil, nil
end

local function UpdateTopBarObjectsForClass(topBar, objClassName)

    local cls = _G[objClassName]
    if not cls then
        return -- class hasn't been defined yet.  We can come back to this later.
    end
    local shouldBeInUse = cls.EvaluateVisibility(topBar)
    local obj, idx = FindInstantiatedClass(topBar, objClassName)
    local isInUse = obj ~= nil
    
    if shouldBeInUse == isInUse then
        return -- all is well, no need to take further action.
    end
    
    if shouldBeInUse then
        -- Create the object.
        local newObj = CreateGUIObject(string.format("topBar_%s", objClassName), cls, topBar)
        table.insert(topBar.objects, newObj)
    else
        -- Destroy the object.
        assert(type(idx) == "number")
        assert(idx > 0)
        assert(idx <= #topBar.objects)
        table.remove(topBar.objects, idx)
        obj:Destroy()
    end

end

-- GUIHudTopBar will maintain a list of classes to instantiate.
local topBarClassNames = UnorderedSet()
local topBarInstantiations = UnorderedSet()
function GUIHudTopBar.AddTopBarClass(classname)
    
    assert(type(classname) == "string")
    
    local wasAdded = topBarClassNames:Add(classname)
    
    -- All top bar instantiations will need to add this class now.
    if wasAdded then
        for i=1, #topBarInstantiations do
            UpdateTopBarObjectsForClass(topBarInstantiations[i], classname)
        end
    end
    
end


-- Load all the top bar object classes (mods can post-hook this to add their own).
Script.Load("lua/Hud2/topBar/GUIHudTopBarObjectClasses.lua")


local kSpacing = 10 -- spacing between top bar objects.

GUIHudTopBar:AddClassProperty("TeamNumber", kTeam1Index)

local function OnDestroy(self)
    topBarInstantiations:RemoveElement(self)
end

function GUIHudTopBar:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    PushParamChange(params, "spacing", kSpacing)
    PushParamChange(params, "orientation", "horizontal")
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "orientation")
    PopParamChange(params, "spacing")
    
    self.objects = {}
    
    self:HookEvent(self, "OnChildAdded", self.OnChildAdded)
    self:HookEvent(self, "OnChildRemoved", self.OnChildRemoved)
    
    for i=1, #topBarClassNames do
        UpdateTopBarObjectsForClass(self, topBarClassNames[i])
    end
    topBarInstantiations:Add(self)
    
    self:HookEvent(self, "OnDestroy", OnDestroy)
    
    -- Setup hooks for things that could determine whether or not top bar classes are used or not.
    -- Currently just team number.
    self:HookEvent(self, "OnTeamNumberChanged", self.EvaluateUsedObjects)
    
end

function GUIHudTopBar:OnChildAdded(childItem, params)

    local owner = GetOwningGUIObject(childItem)
    if not owner then
        return -- a bare GUIItem was added.
    end
    
    -- Ensure the object has a valid layout priority (should have been validated by the top bar
    -- object's Initialize().
    assert(type(owner.kLayoutSortPriority) == "number")
    assert(owner.kLayoutSortPriority == math.floor(owner.kLayoutSortPriority))
    
    -- Set the object's layer to its priority, so that top bar objects will be laid out consistently
    -- regardless of the order in which they're added. (We can use layers for this since it's all
    -- relative to the layout's layer, and these objects aren't supposed to overlap).
    owner:SetLayer(owner.kLayoutSortPriority)
    
    -- Sync this object's TeamNumber to the top bar's TeamNumber (if it uses "TeamNumber", that is)
    if owner:GetPropertyExists("TeamNumber") then
        owner:HookEvent(self, "OnTeamNumberChanged", owner.SetTeamNumber)
        owner:SetTeamNumber(self:GetTeamNumber()) -- set initial state.
    end
    
end

function GUIHudTopBar:OnChildRemoved(childItem)
    
    local owner = GetOwningGUIObject(childItem)
    if not owner then
        return
    end
    
    -- Stop syncing this object's TeamNumber to the top bar's TeamNumber.
    owner:UnHookEvent(self, "OnTeamNumberChanged", owner.SetTeamNumber)

end

-- Ensures that all top bar objects being used should be. (remove unneeded objects).
-- Ensures that all top bar object classes that should be used, are. (create missing objects).
function GUIHudTopBar:EvaluateUsedObjects()
    
    for i=1, #topBarClassNames do
        UpdateTopBarObjectsForClass(self, topBarClassNames[i])
    end

end