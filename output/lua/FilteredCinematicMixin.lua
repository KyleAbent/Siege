-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\FilteredCinematicMixin.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- For use with entities that have a need for knowing when an option that hides cinematics or replaces them
-- has changed.
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

if not Client then return end

-- Currently this mixin is only used to provide a tag to be able to retrieve only entities that need to be updated
-- and to have a function to call in a event-based manner.
FilteredCinematicMixin = CreateMixin(FilteredCinematicMixin)
FilteredCinematicMixin.type = "FilteredCinematicUser"

-- This is the function that should be called when a cinematic hiding option is changed.
-- Should be overridden.
-- FilteredCinematicMixin:OnFilteredCinematicOptionChanged()