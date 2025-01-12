--=============================================================================
--
-- lua/Weapons/ViewModel.lua
--
-- Created by Max McGuire (max@unknownworlds.com)
-- Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
--
--=============================================================================

--
-- ViewModel is the class which handles rendering and animating the view model
-- (i.e. weapon model) for a player. To use this class, create a 'view_model'
-- entity and set its parent to the player that it will belong to. There should
-- be one view model entity per player (the same view model entity is used for
-- all of the weapons).
--
Script.Load("lua/Globals.lua")
Script.Load("lua/Mixins/ModelMixin.lua")

class 'ViewModel' (Entity)

ViewModel.mapName = "view_model"

local networkVars =
{
    weaponId = "entityid"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

function ViewModel:OnCreate()
    
    Entity.OnCreate(self)
    
    local constants = (Client and {kRenderZone = RenderScene.Zone_ViewModel}) or {}

    InitMixin(self, BaseModelMixin, constants)
    InitMixin(self, ModelMixin)
    
    self.weaponId = Entity.invalidId
    
    if Client then
        self.clientWeaponId = Entity.invalidId
    end

    -- mark the viewmodel as not physics cullable (its origin is not in world coords)
    self:SetPhysicsCullable(false)
    
    -- Use a custom propagation callback to only propagate to the owning player.
    self:SetPropagate(Entity.Propagate_PlayerOwner)
    
    self:SetUpdates(true, kDefaultUpdateRate)

end

function ViewModel:SetWeapon(weapon)

    if weapon ~= nil then
        self.weaponId = weapon:GetId()
    else
        self.weaponId = Entity.invalidId
    end
    
end

if Client then

    function ViewModel:OnWeaponIdChanged()
        
        local parent = self:GetParent()
        if parent and parent.OnUpdateViewModelEvent then
            parent:OnUpdateViewModelEvent()
        end
        
    end

end

function ViewModel:SetIsHighlightEnabled()
    return 0.5
end

function ViewModel:GetCameraCoords()

    if self:GetNumModelCameras() > 0 then
    
        local camera = self:GetModelCamera(0)
        return true, camera:GetCoords()
        
    end

    return false, nil
    
end

-- Pass along to weapon so melee attacks can be triggered at exact time of impact.
function ViewModel:OnTag(tagHit)

    PROFILE("ViewModel:OnTag")

    local weapon = self:GetWeapon()
    if weapon ~= nil and weapon.OnTag then
        weapon:OnTag(tagHit)
    end

end

if Client then

    -- Override camera coords with custom camera animation
    function ViewModel:OnAdjustModelCoords(coords)
    
        PROFILE("ViewModel:OnAdjustModelCoords")
        
        local overrideCoords = Coords.GetIdentity()
        local standardAspect = 1900 / 1200 -- Aspect ratio the view models are designed for.
        
        if self:GetNumModelCameras() > 0 then

            local camera = self:GetModelCamera(0)
            
            if self:GetParent() == Client.GetLocalPlayer() and not MainMenu_GetIsOpened() then
                Client.SetZoneFov( RenderScene.Zone_ViewModel, GetScreenAdjustedFov(camera:GetFov(), standardAspect) )
            end

            overrideCoords = camera:GetCoords():GetInverse()
            
        else
        
            if self:GetParent() == Client.GetLocalPlayer() then
                Client.SetZoneFov( RenderScene.Zone_ViewModel, GetScreenAdjustedFov(math.rad(65), standardAspect) )
            end
            
        end
        
        local parent = self:GetParent()
        if parent and parent.ModifyViewModelCoords then
            overrideCoords = parent:ModifyViewModelCoords(overrideCoords)
        end
        
        return overrideCoords
        
    end
    
    function ViewModel:OnDestroy()
        local renderModel = self:GetRenderModel()
        if renderModel then
            renderModel:ClearOverrideMaterials()
        end
    end

    local reloadFraction = -1
    local initialFraction
    local insertNum
    local lastSeq
    local lastReloadFraction

    function GetReloadFraction()
        return math.min(reloadFraction, 1)
    end

    function ViewModel:OnUpdateRender()
    
        PROFILE("ViewModel:OnUpdateRender")

        if self.clientWeaponId ~= self.weaponId then
            self.clientWeaponId = self.weaponId
            self:OnWeaponIdChanged()
        end
        
        -- Hide view model when in third person.
        -- Only show local player model and active weapon for local player when third person
        -- or for other players (not ethereal Fades).
        self:SetIsVisible(self:GetIsVisible() and not self:GetParent():GetDrawWorld() and not Client.kHideViewModel)

        reloadFraction = -1
        local weapon = self:GetWeapon()
        if weapon then
            local player = Client.GetLocalPlayer()
            if player:isa("Marine") or player:isa("Exo") then
                local model = Shared.GetModel(self.modelIndex)
                if model then
                    local seqLength = model:GetSequenceLength(self.animationSequence)
                    local seqName = model:GetSequenceName(self.animationSequence)
                    if lastSeq ~= seqName then
                        lastSeq = seqName
                        if weapon:isa("Shotgun") then
                            if seqName == "reload_start" then
                                insertNum = weapon:GetClip()
                            elseif seqName == "reload_insert" then
                                insertNum = insertNum or weapon:GetClip()
                                insertNum = insertNum + 1
                                initialFraction = insertNum/weapon:GetClipSize()
                            end
                        elseif weapon:isa("GrenadeLauncher") then
                            if string.find(seqName, "reload") and not string.find(seqName, "end") or not seqName == "reload_one" then
                                insertNum = weapon:GetClip()
                                initialFraction = insertNum/weapon:GetClipSize()
                            end
                        end
                    end

                    if seqName == "reload" or weapon:isa("Rifle") and seqName == "secondary" then
                        reloadFraction = (Shared.GetTime()-self.animationStart) / (seqLength/self.animationSpeed)
                    elseif weapon:isa("Shotgun") then
                        if seqName == "reload_start" then
                            reloadFraction = (insertNum + (Shared.GetTime()-self.animationStart) / (seqLength/self.animationSpeed)) / weapon:GetClipSize()
                        elseif seqName == "reload_insert" then
                            reloadFraction = initialFraction + (Shared.GetTime()-self.animationStart) / (seqLength*(weapon:GetClipSize()-insertNum)/self.animationSpeed)*(1-initialFraction)
                        end
                    elseif weapon:isa("GrenadeLauncher") then
                        if string.find(seqName, "reload") then
                            if not string.find(seqName, "end") or not seqName == "reload_one" then
                                reloadFraction = (insertNum + (Shared.GetTime()-self.animationStart) / (seqLength/self.animationSpeed)) / weapon:GetClipSize()
                                lastReloadFraction = reloadFraction
                            else
                                reloadFraction = lastReloadFraction + (Shared.GetTime()-self.animationStart) / (seqLength/self.animationSpeed)*(1-lastReloadFraction)
                            end
                        end
                    end
                end
            elseif player:isa("Alien") then
                reloadFraction = AlienUI_GetMovementSpecialCooldown()
            end
        end
        
    end
    
end

function ViewModel:GetEffectParams(tableParams)
    
    tableParams[kEffectFilterClassName] = self:GetClassName()
    
    -- Override classname with class of weapon we represent
    local weapon = self:GetWeapon()
    if weapon ~= nil then
        tableParams[kEffectFilterClassName] = weapon:GetClassName()
        weapon:GetEffectParams(tableParams)
    end
    
end

function ViewModel:GetWeapon()
    return Shared.GetEntity(self.weaponId)
end

function ViewModel:OnUpdateAnimationInput(modelMixin)

    PROFILE("ViewModel:OnUpdateAnimationInput")
    
    local parent = self:GetParent()
    if parent then
        parent:OnUpdateAnimationInput(modelMixin)
    end
    
end

Shared.LinkClassToMap("ViewModel", ViewModel.mapName, networkVars)