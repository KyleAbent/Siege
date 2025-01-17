-- ======= Copyright ? 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/EffectsGlobals.lua
--
--    Contains global constants used by the effects system.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kEffectHostCoords = "effecthostcoords"
kEffectSurface = "surface"

-- TODO: Add stop sound, cinematics
-- TODO: Add camara shake?

--
-- All effect entries should be one of these basic types:
--
kCinematicType                     = "cinematic"                -- Server-side world cinematic at kEffectHostCoords
kWeaponCinematicType               = "weapon_cinematic"         -- Needs attach_point specified
kViewModelCinematicType            = "viewmodel_cinematic"      -- Needs attach_point specified.
kPlayerCinematicType               = "player_cinematic"         -- Shared world cinematic (like weapon_cinematic or view_model cinematic but played at world pos kEffectHostCoords)
kParentedCinematicType             = "parented_cinematic"       -- Parented to entity generating event (optional attach_point)
kLoopingCinematicType              = "looping_cinematic"        -- Looping client-side cinematic
kStopCinematicType                 = "stop_cinematic"           -- Stops a world cinematic
kStopViewModelCinematicType        = "stop_viewmodel_cinematic" -- Stops a cinematic attached to a view model

kSoundType                         = "sound"                    -- Server-side world sound
kParentedSoundType                 = "parented_sound"           -- For looping entity sounds, you'll want to use parented_sound so they are stopped when entity goes away
kPrivateSoundType                  = "private_sound"            -- TODO: Change name to one_sound? This currently plays relative to player.
kStopSoundType                     = "stop_sound"
kPlayerSoundType                   = "player_sound"             -- won't be send to triggering player

kStopEffectsType                   = "stop_effects"             -- Stops all looping or parented sounds and particles for this object (pass "")

kDecalType                         = "decal"                    -- Creates a decal at position of effect (only works when triggered from client events)

-- Also add to EffectManager:InternalTriggerEffect()
kEffectTypes =
{
    kCinematicType, kWeaponCinematicType, kViewModelCinematicType, kPlayerCinematicType, kParentedCinematicType, kLoopingCinematicType, kStopCinematicType,
    kSoundType, kParentedSoundType, kPrivateSoundType, kStopSoundType, kPlayerSoundType,
    kStopEffectsType, kStopViewModelCinematicType,
    kDecalType,
}

-- For cinematics and sounds, you can specify the asset names like this:
-- Set to "cinematics/marine/rifle/shell.cinematic" or use a table like this to control probability:
-- { {1, "cinematics/marine/rifle/shell.cinematic"}, {.5, "cinematics/marine/rifle/shell2.cinematic"} } -- shell2 triggers 1/3 of the time
-- TODO: Account for GetRicochetEffectFrequency
-- TODO: Add hooks for sound parameter changes so they can be applied to specific sound effects here
-- TODO: system for IP spin.cinematic (and MAC "fxnode_light" - "cinematics/marine/mac/light.cinematic")
kEffectParamAttachPoint             = "attach_point"
kEffectParamBlendTime               = "blend_time"
kEffectParamAnimationSpeed          = "speed"
kEffectParamForce                   = "force"
kEffectParamSilent                  = "silent"
kEffectParamVolume                  = "volume"
kEffectParamDeathTime               = "death_time"
kEffectParamLifetime                = "lifetime"        -- Lifetime for decals (default is 5)
kEffectParamScale                   = "scale"           -- Scale for decals (default is 5)
kEffectSoundParameter               = "sound_param"     -- Not working yet
kEffectParamDone                    = "done"
kEffectParamWorldSpace              = "world_space"     -- If true, the cinematic will emit particles into world space.

-- General effects. Chooses one effect from each block. Name of block is unused except for debugging/clarity. Add to InternalGetEffectMatches().
kEffectFilterClassName              = "classname"
kEffectFilterDoerName               = "doer"
kEffectFilterDamageType             = "damagetype"
kEffectFilterIsAlien                = "isalien"
kEffectFilterIsMarine               = "ismarine"
kEffectFilterBuilt                  = "built"
kEffectFilterFlinchSevere           = "flinch_severe"
kEffectFilterInAltMode              = "alt_mode"
kEffectFilterOccupied               = "occupied"
kEffectFilterEmpty                  = "empty"
kEffectFilterVariant                = "variant"
kEffectFilterFrom                   = "from"
kEffectFilterFromAnimation          = "from_animation"      -- The current animation, or the animation just finished during animation_complete
kEffectFilterUpgraded               = "upgraded"
kEffectFilterLeft                   = "left"
kEffectFilterSprinting              = "sprinting"
kEffectFilterForward                = "forward"
kEffectFilterCrouch                 = "crouch"
kEffectFilterActive                 = "active"              -- Generic "active" tag to denote change of state. Used for infantry portal spinning effects.
kEffectFilterHitSurface             = "surface"             -- Set in events that hit something
kEffectFilterDeployed               = "deployed"            -- When entity is in a deployed state
kEffectFilterCloaked                = "cloaked"
kEffectFilterEnemy                  = "enemy"
kEffectFilterSilenceUpgrade         = "silenceupgrade"
kEffectFilterSex                    = "sex"
kEffectFilterAlternateType          = "alt_type"
kEffectFilterMucous                 = "mucous"
kEffectFilterRegen                  = "regen"               -- Triggered from self (heal sounds regen vs crag etc)

kEffectFilters =
{
    kEffectFilterClassName, kEffectFilterDoerName, kEffectFilterDamageType, kEffectFilterIsAlien, kEffectFilterIsMarine, kEffectFilterBuilt, kEffectFilterFlinchSevere,
    kEffectFilterInAltMode, kEffectFilterOccupied, kEffectFilterEmpty, kEffectFilterVariant, kEffectFilterFrom, kEffectFilterFromAnimation,
    kEffectFilterUpgraded, kEffectFilterLeft, kEffectFilterSprinting, kEffectFilterForward, kEffectFilterCrouch, kEffectFilterActive, kEffectFilterHitSurface,
    kEffectFilterDeployed, kEffectFilterCloaked, kEffectFilterEnemy, kEffectFilterSilenceUpgrade, kEffectFilterSex, kEffectFilterAlternateType, kEffectFilterMucous,
    kEffectFilterRegen
}
-- create dictionary association too
for i=1, #kEffectFilters do
    kEffectFilters[kEffectFilters[i]] = i -- eg kEffectFilters["className"] = 1
end