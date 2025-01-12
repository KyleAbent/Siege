-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/ThunderdomeForceField.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
--    Set of utility / helper functions for the Thunderdome feature
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


class 'ThunderdomeForceField' (Entity)

ThunderdomeForceField.kMapName = "thunderdome_forcefield"
ThunderdomeForceField.kModelName = PrecacheAsset("models/effects/proximity_force_field_noEntry.model")

local networkVars =
{
    scale = "vector"
    --name is unused for now
}

function ThunderdomeForceField:OnCreate()
end

function ThunderdomeForceField:OnInitialized()
    
    local coords = self:GetCoords()
    coords.xAxis = coords.xAxis * self.scale.x
    coords.yAxis = coords.yAxis * self.scale.y
    coords.zAxis = coords.zAxis * self.scale.z
    
    kForceFieldPhysics = Shared.CreatePhysicsModel(ThunderdomeForceField.kModelName, false, coords, self)
    kForceFieldPhysics:SetPhysicsType(CollisionObject.Static)
    kForceFieldPhysics:SetGroup(PhysicsGroup.DefaultGroup)
    
    if Client then
        -- Create the visual representation
        kForceFieldVisual = Client.CreateRenderModel(RenderScene.Zone_Default)
        kForceFieldVisual:SetModel(ThunderdomeForceField.kModelName)
        kForceFieldVisual:SetCoords(coords)
        kForceFieldVisual:SetIsStatic(true)
        kForceFieldVisual:SetIsInstanced(true)
        kForceFieldVisual.model = ThunderdomeForceField.kModelName --why in the hell is this not taken care of with :SetModel()???
    end

    self:SetUpdates(false)

end

Shared.LinkClassToMap("ThunderdomeForceField", ThunderdomeForceField.kMapName, networkVars)

