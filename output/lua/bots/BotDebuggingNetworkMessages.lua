-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/BotDebuggingNetworkMessages.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Network Message Definitions related to Bot Debugging
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetBotDebuggingAllowed()
    return Shared.GetCheatsEnabled() or Shared.GetTestsEnabled()
end

local kClientDebugTargetMessage =
{
    targetId = "entityid",
}
Shared.RegisterNetworkMessage("ClientBotDebugTarget", kClientDebugTargetMessage)

local kBotDebugFollowModeMessage =
{
    follow = "boolean",
}
Shared.RegisterNetworkMessage("BotDebugSetFollowMode", kBotDebugFollowModeMessage)

-- When the targetted bot is removed, so the client can unselect the bot's entry.
local kBotDebuggingTargetDestroyed =
{
    destroyedTargetId = "entityid"
}
Shared.RegisterNetworkMessage("BotDebuggingTargetDestroyed", kBotDebuggingTargetDestroyed)

local kBotDebuggingDebugSectionUpdateMessage = -- If this bloats netmessage queue too much, dynamically create netmessages for each section and send raw data.
{
    sectionType = "enum kBotDebugSection",
    contents = "string (256)"
}
Shared.RegisterNetworkMessage("BotDebuggingSectionUpdate", kBotDebuggingDebugSectionUpdateMessage)
