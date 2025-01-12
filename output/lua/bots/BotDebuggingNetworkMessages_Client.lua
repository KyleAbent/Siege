-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/BotDebuggingNetworkMessages_Client.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Client part of network message handling for bot debugging
--
-- ========= For more information, visit us at http://www.unknownworlds.com =======================

assert(Client)

local function OnBotDebuggingTargetDestroyed()
    if gBotDebugWindow then
        gBotDebugWindow:UnselectBot()
    end
end
Client.HookNetworkMessage("BotDebuggingTargetDestroyed", OnBotDebuggingTargetDestroyed)

local function OnBotDebuggingSectionUpdate(message)
    if gBotDebugWindow == nil then return end

    local sectionType = message.sectionType
    local contents = message.contents
    gBotDebugWindow:AddOrUpdateDebugSection(EnumToString(kBotDebugSection, sectionType), contents)
end
Client.HookNetworkMessage("BotDebuggingSectionUpdate", OnBotDebuggingSectionUpdate)
