-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Hud\GUINotificationMixin.lua
--
-- Created by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Adds common functionality needed to store, and retrieve GUI notifications in queue.
-- Should be client-side only.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local debugNotificationSources = false
local function OnDebugResearchNotificationSources()

    if Shared.GetTestsEnabled() then
        debugNotificationSources = not debugNotificationSources
        Print("Debug research notification sources: %s", debugNotificationSources)
    else
        Print("Tests must be enabled for this command. Disabling it just in case.")
        debugNotificationSources = false
    end

end
Event.Hook("Console_debug_research_notification_sources", OnDebugResearchNotificationSources)

GUINotificationMixin = CreateMixin( GUINotificationMixin )
GUINotificationMixin.type = "GUINotification"

GUINotificationMixin.kDelayTime = 2

GUINotificationMixin.expectedMixins =
{
}

GUINotificationMixin.optionalCallbacks =
{
}

GUINotificationMixin.networkVars =
{
}

function GUINotificationMixin:__initmixin()

    PROFILE("GUINotificationMixin:__initmixin")

    if Client then
        self.notifications = { }
        self.timeInitialized = Shared.GetTime()
    end

end

if Client then

    -- This is to delay adding of new notifications to the GUI until a certain time has passed.
    -- This is a workaround for a bug where the tech tree is still populated when switching teams really fast.
    -- Clearing tech tree on the client side causes some pretty bad issues, like buy menu not working etc.
    --
    -- The GUIEvent ClientUI script won't get removed and re-inited (This is current ClientUI behavior), so this should only _actually_ do
    -- something when F4->Rejoin. So buying something like an exo or jetpack shouldn't have a delay.
    -- If the ClientUI behavior changes and we get a delay, oh well i'll get to it then.
    function GUINotificationMixin:GetDelayTimePassed()
        return Shared.GetTime() > self.timeInitialized + GUINotificationMixin.kDelayTime
    end

    function GUINotificationMixin:AddNotification(notification)

        if debugNotificationSources then
            Log("Adding Research Notification - TechID: %s, Instanced: %s, EntityID: %s, Source: %s",
            EnumToString(kTechId, notification.techId),
            GetTechIdIsInstanced(notification.techId),
            notification.entityId,
            EnumToString(kResearchNotificationSource, notification.source))
        end

        table.insert(self.notifications, notification)

    end

    -- this function returns the oldest notification and clears it from the list
    function GUINotificationMixin:GetAndClearNotification()

        local notification

        if table.icount(self.notifications) > 0 then

            notification = self.notifications[1]
            table.remove(self.notifications, 1)

        end

        return notification

    end

end
