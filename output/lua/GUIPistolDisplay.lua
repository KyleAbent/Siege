-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIPistolDisplay.lua
--
-- Created by: Max McGuire (max@unknownworlds.com)
--
-- Displays the ammo and grenade counter for the rifle.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIBulletDisplay.lua")

-- Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponVariant  = 1
pulsateAlpha   = 0
globalTime     = 0
lowAmmoWarning = true

bulletDisplay = nil

--kPistolVariants = enum({ "normal", "forge", "sandstorm", "tundra", "kodiak", "viper", "gold", "chroma", "wood", "damascus", "damasgrn", "damaspurp" })
local kTextures =
{
    "ui/rifledisplay0.dds", -- normal
    "ui/rifledisplay1.dds", -- kodiak
    "ui/rifledisplay2.dds", -- tundra
    "ui/rifledisplay4.dds", -- forge
    "ui/rifledisplay5.dds", -- sandstorm
    "ui/rifledisplay6.dds", -- viper
    "ui/rifledisplay7.dds", -- gold
    "ui/rifledisplay8.dds", -- chroma
    "ui/rifledisplay9.dds",     --Wood
    "ui/rifledisplay10.dds",    --Damascus
    "ui/rifledisplay11.dds",    --Damascus Green
    "ui/rifledisplay12.dds",    --Damascus Purple
}

--Overrides for Pistol Specific tweaks (done here to not conflit with Rifle)
function GUIBulletDisplay:SetWeaponVariant()
    self.background:SetTexture(kTextures[weaponVariant])
end

--
-- Called by the player to update the components.
--
function Update(deltaTime)

    PROFILE("GUIPistolDisplay:Update")

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
    bulletDisplay:SetGlobalTime(globalTime)
    bulletDisplay:SetWeaponVariant(weaponVariant)
    bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:Update(deltaTime)
    
end

--
-- Initializes the player components.
--
function Initialize()

    GUI.SetSize(256, 256)
    
    bulletDisplay = GUIBulletDisplay()
    bulletDisplay:Initialize()
    bulletDisplay:SetClipSize(10)
    bulletDisplay:SetGlobalTime(globalTime)
    bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:SetWeaponVariant(weaponVariant)
    
end

Initialize()