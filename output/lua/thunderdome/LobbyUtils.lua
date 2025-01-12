-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/LobbyUtils.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
--    Set of utility / helper functions for the Thunderdome feature
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/Utility.lua")


g_thunderdomeVerbose = Client.GetVerbosityLevel() > 0


function SLog(...)
    if g_thunderdomeVerbose then
        Log(...)
    end
end

-------------------------------------------------------------------------------
-- Lobby Data Utilities

function GetIsValidMap( mapName )
    local sIdx = kThunderdomeMaps[mapName]
    return kThunderdomeMaps[mapName] ~= nil and kThunderdomeMaps[mapName] == kThunderdomeMaps[kThunderdomeMaps[sIdx]]
end

local tpel_sec = 60
local tpel_min = 61
local tpel_hr = 60 * 60
local tpel_day = tpel_hr * 24
--McG: Yes...this is crap. Rewrite if you dislike it
function GetThunderdomePenaltyExpirationFormatted()     --TD-TODO handle singular vs plural better
    local t = Client.GetTdTimestamp()
    local pt = Client.GetThunderdomeActivePenaltyPeriod()
    local d = pt - t

    if d <= tpel_sec then --seconds
        return d .. " seconds"

    elseif d > tpel_sec and d < tpel_hr then

        local min = math.floor( d / 60 )
        local sec = math.floor( d - (tpel_sec * min) )
        if min < 2 and sec > 0 then
            return min .. " minute " .. sec .. " seconds"
        else
            return min .. " minutes"
        end

    elseif d > tpel_hr and d < tpel_day then
        
        local hr = math.floor( d / tpel_hr )
        local min = math.floor( d - (hr * tpel_hr) / 60 )

        if hr == 1 and min > 0 then
            return hr .. " hour " .. min .. " minutes"
        else
            if hr == 1 then
                return hr .. " hour"
            else
                return hr .. " hours"
            end
        end

    elseif d > tpel_day then

        local dr = math.floor( d / tpel_day )
        if dr < 2 then
            local hr = math.floor( d / tpel_hr )
            if hr > 0 then
                if hr < 2 then
                    return dr .. " day " .. hr .. " hour"
                else
                    return dr .. " day " .. hr .. " hours"
                end
            else
                return dr .. " day"
            end
        end
        return dr .. " days"
    end
end

function GetLeaveLobbyMessage()

    local td = Thunderdome()

    if td:GetIsConnectedToLobby() then
        
        local lobState = td:GetLobbyState()

        if lobState == nil then
            return ""
        end

        local message

        if lobState < kLobbyState.WaitingForCommanders then
            message = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_MESSAGE")

        elseif lobState >= kLobbyState.WaitingForCommanders and lobState < kLobbyState.WaitingForServer then
            message = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_MESSAGE_PENALTY")

        elseif lobState >= kLobbyState.WaitingForServer then
            message = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_MESSAGE_PENALTY")

        end

        return message

    elseif Shared.GetThunderdomeEnabled() then
    --Handle in-game / td instance -- lobby doesn't matter at this point
        message = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_MESSAGE_PENALTY_INGAME")
        return message
        
    end

    return ""

end


-------------------------------------------------------------------------------
-- Client UI Helpers

--TODO Add translator function to take Lobby State -> GUI string
--TODO Add Map index to map-name,...something for dispalying map-votes?

local kThunderdomeMapBackgroundSize = Vector(395, 236, 0)
function GetMapBackgroundPixelCoordinates(key)

    local atlasPosition = GetMapBackgroundTextureAtlas(key)
    if not atlasPosition then return end

    local xSize = kThunderdomeMapBackgroundSize.x
    local ySize = kThunderdomeMapBackgroundSize.y

    local xStart = xSize * atlasPosition[1]
    local yStart = ySize * atlasPosition[2]

    return { xStart, yStart, (xStart + xSize), (yStart + ySize) }

end

local kMapTextureAtlas
function GetMapBackgroundTextureAtlas(tdMap)

    if not kMapTextureAtlas then
        kMapTextureAtlas = 
        {
            [kThunderdomeMaps.ns2_ayumi    ]  = { 0, 6 },
            [kThunderdomeMaps.ns2_caged    ]  = { 0, 0 },
            [kThunderdomeMaps.ns2_biodome  ]  = { 1, 0 },
            [kThunderdomeMaps.ns2_derelict ]  = { 2, 0 },
            [kThunderdomeMaps.ns2_descent  ]  = { 0, 1 },
            [kThunderdomeMaps.ns2_eclipse  ]  = { 1, 1 },
            [kThunderdomeMaps.ns2_docking  ]  = { 2, 1 },
            [kThunderdomeMaps.ns2_kodiak   ]  = { 0, 2 },
            [kThunderdomeMaps.ns2_origin   ]  = { 1, 2 },
            [kThunderdomeMaps.ns2_mineshaft]  = { 2, 2 },
            [kThunderdomeMaps.ns2_metro    ]  = { 0, 3 },
            [kThunderdomeMaps.ns2_summit   ]  = { 1, 3 },
            [kThunderdomeMaps.ns2_tanith   ]  = { 2, 5 },
            [kThunderdomeMaps.ns2_tram     ]  = { 2, 3 },
            [kThunderdomeMaps.ns2_refinery ]  = { 0, 4 },
            [kThunderdomeMaps.ns2_unearthed]  = { 1, 4 },
            [kThunderdomeMaps.ns2_veil     ]  = { 2, 4 },
            [kThunderdomeMaps.RANDOMIZE    ]  = { 0, 5 },
            ["LOCKED"                      ]  = { 1, 5 },
        }

    end

    return kMapTextureAtlas[tdMap]

end

local kThunderdomeMapTitleLocales
function GetMapTitleLocale(tdMap)

    if not kThunderdomeMapTitleLocales then
        kThunderdomeMapTitleLocales = {}
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_ayumi    ]  = "THUNDERDOME_MAP_NS2_AYUMI"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_caged    ]  = "THUNDERDOME_MAP_NS2_CAGED"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_biodome  ]  = "THUNDERDOME_MAP_NS2_BIODOME"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_derelict ]  = "THUNDERDOME_MAP_NS2_DERELICT"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_descent  ]  = "THUNDERDOME_MAP_NS2_DESCENT"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_eclipse  ]  = "THUNDERDOME_MAP_NS2_ECLIPSE"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_docking  ]  = "THUNDERDOME_MAP_NS2_DOCKING"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_kodiak   ]  = "THUNDERDOME_MAP_NS2_KODIAK"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_origin   ]  = "THUNDERDOME_MAP_NS2_ORIGIN"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_mineshaft]  = "THUNDERDOME_MAP_NS2_MINESHAFT"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_metro    ]  = "THUNDERDOME_MAP_NS2_METRO"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_summit   ]  = "THUNDERDOME_MAP_NS2_SUMMIT"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_tanith   ]  = "THUNDERDOME_MAP_NS2_TANITH"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_tram     ]  = "THUNDERDOME_MAP_NS2_TRAM"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_refinery ]  = "THUNDERDOME_MAP_NS2_REFINERY"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_unearthed]  = "THUNDERDOME_MAP_NS2_UNEARTHED"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.ns2_veil     ]  = "THUNDERDOME_MAP_NS2_VEIL"
        kThunderdomeMapTitleLocales[kThunderdomeMaps.RANDOMIZE    ]  = "THUNDERDOME_MAP_RANDOMIZE"
    end

    return kThunderdomeMapTitleLocales[tdMap]

end

local kLobbyJoinResponseLocales
function GetLobbyJoinResponseLocale(responseCode)

    if not kLobbyJoinResponseLocales then
        kLobbyJoinResponseLocales = {}
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_Success]           = "STEAMLOBBYJOIN_SUCCESS"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_DoesNotExist]      = "STEAMLOBBYJOIN_DOESNOTEXIST"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_NotAllowed]        = "STEAMLOBBYJOIN_NOTALLOWED"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_Full]              = "STEAMLOBBYJOIN_FULL"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_Error]             = "STEAMLOBBYJOIN_UNEXPECTEDERROR"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_Banned]            = "STEAMLOBBYJOIN_BANNED"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_Limited]           = "STEAMLOBBYJOIN_LIMITEDUSER"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_ClanDisabled]      = "STEAMLOBBYJOIN_CLANDISABLED"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_CommunityBan]      = "STEAMLOBBYJOIN_COMMUNITYBAN"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_MemberBlocked]     = "STEAMLOBBYJOIN_MEMBERBLOCKED"
        kLobbyJoinResponseLocales[Client.SteamLobbyEnterResponse_UserBlockedMember] = "STEAMLOBBYJOIN_USERBLOCKEDMEMBER"
    end

    return kLobbyJoinResponseLocales[responseCode]

end

local kLobbyCreateResponseLocales
function GetLobbyCreateResponseLocale(responseCode)

    if not kLobbyCreateResponseLocales then
        kLobbyCreateResponseLocales = {}
        kLobbyCreateResponseLocales[Client.SteamLobbyCreateResult_OK]            = "STEAMLOBBYCREATE_OK"
        kLobbyCreateResponseLocales[Client.SteamLobbyCreateResult_Fail]          = "STEAMLOBBYCREATE_FAIL"
        kLobbyCreateResponseLocales[Client.SteamLobbyCreateResult_NoConnecttion] = "STEAMLOBBYCREATE_NOCONNECTION"
        kLobbyCreateResponseLocales[Client.SteamLobbyCreateResult_AccessDenied]  = "STEAMLOBBYCREATE_ACCESSDENIED"
        kLobbyCreateResponseLocales[Client.SteamLobbyCreateResult_Timeout]       = "STEAMLOBBYCREATE_TIMEOUT"
        kLobbyCreateResponseLocales[Client.SteamLobbyCreateResult_LimitExceeded] = "STEAMLOBBYCREATE_LIMITEXCEEDED"
    end

    return kLobbyCreateResponseLocales[responseCode]

end
