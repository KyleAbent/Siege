-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/BotDebuggingNetworkMessages_Server.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Server part of network message handling for bot debugging
--
-- ========= For more information, visit us at http://www.unknownworlds.com =======================

assert(Server)

-- Server.HookNetworkMessage(messageName, function)

local function OnClientBotDebugTarget(client, message)

    if not GetBotDebuggingAllowed() then return end

    local botEntId = message.targetId
    local botEnt = Shared.GetEntity(botEntId)
    if botEnt and botEnt:isa("Bot") then
        GetBotDebuggingManager():AddClient(client:GetId(), botEntId)
    else
        GetBotDebuggingManager():RemoveClient(client:GetId())
    end

end
Server.HookNetworkMessage("ClientBotDebugTarget", OnClientBotDebugTarget)

local function OnClientBotDebugFollowMode(client, message)
    local isFollowing = message.follow
    GetBotDebuggingManager():SetClientFollowing(client:GetId(), isFollowing)
end
Server.HookNetworkMessage("BotDebugSetFollowMode", OnClientBotDebugFollowMode)
