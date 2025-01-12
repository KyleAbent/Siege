-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/LobbyClientMember.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/LobbyUtils.lua")

Script.Load("lua/thunderdome/LobbyMemberModel.lua")
Script.Load("lua/thunderdome/LobbyModel.lua")

Script.Load("lua/thunderdome/ClientLobbyFunctors.lua")


class 'LobbyClientMember'




function LobbyClientMember:Initialize()

    --Default to NOT allowing voting (for now), and only when state allows
    self.mapVotingLocked = true

    self:RegisterEvents()

end

function LobbyClientMember:RegisterEvents()
    SLog("LobbyClientMember:RegisterEvents()")

    --Setup event for when the Lobby's state value changes, denotes various 'phases' of match setup
    Thunderdome_AddListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )

    Thunderdome_AddListener( kThunderdomeEvents.OnTeamShuffleComplete, kLobbyClientFunctors[kThunderdomeEvents.OnTeamShuffleComplete] )

    --Listen for any times local-client changes their in-game alias (options or console command)
    Thunderdome_AddListener( kThunderdomeEvents.OnClientNameChange, kLobbyClientFunctors[kThunderdomeEvents.OnClientNameChange] )

    Thunderdome_AddListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )

    --Local client notified they joined a lobby, use to trigger setting their own meta-data
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )

    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )

    --Listen for (as relay) Member JOIN events, to trigger GUI updates
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    --Listen for (as relay) Member LEAVE events, to trigger GUI updates
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    --Listen for (as relay) Member KICKED events, to trigger GUI updates
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )

end

function LobbyClientMember:UnRegisterEvents()
    SLog("LobbyClientMember:UnRegisterEvents()")
    
    Thunderdome_RemoveListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnTeamShuffleComplete, kLobbyClientFunctors[kThunderdomeEvents.OnTeamShuffleComplete] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnClientNameChange, kLobbyClientFunctors[kThunderdomeEvents.OnClientNameChange] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )
end

--It's required that we de-register any TD event hooks, as members can become owners, thus object ref changes
function LobbyClientMember:Destroy()
    self:UnRegisterEvents()
end


function LobbyClientMember:Update( thunderDome, deltaTime, time )
    assert(thunderDome)

    local lobby = thunderDome:GetActiveLobby()
    local lobState = lobby:GetState()

    local readyConn = 
        (lobState == kLobbyState.Ready or lobState == kLobbyState.Playing) and 
        not Shared.GetThunderdomeEnabled() and --doubles as not-is-connected
        thunderDome.pendingAkfPromptAction == false and
        thunderDome.pendingReconnectPrompt == false

    --[[
    if (lobState == kLobbyState.Ready or lobState == kLobbyState.Playing) then
        SLog("    pendingAkfPromptAction:   %s", thunderDome.pendingAkfPromptAction)
        SLog("    pendingReconnectPrompt:   %s", thunderDome.pendingReconnectPrompt)
    end
    --]]
    
    if readyConn then
    --Lobby is ready for players to join TD server
        
        SLog("  LobbyClientMember:Update() -- readyConn: %s", readyConn)

        local numConnAttempts = Client.GetOptionInteger( kOptionKey_CachedLobbyConnAttempts, 0)
        local prevAttemptMade = Client.GetOptionBoolean( kOptionKey_CachedLobbyConnMade, false )
        local isFirstConnect = (numConnAttempts == 0 and prevAttemptMade == false)

        SLog("\t   numConnAttempts:     %s", numConnAttempts)
        SLog("\t   prevAttemptMade:     %s", prevAttemptMade)
        SLog("\t    isFirstConnect:     %s", isFirstConnect)

        if isFirstConnect then
            SLog(" *** Is FirstConnectionAttempt, joining...")
            thunderDome:AttemptServerConnect()
        end
        
    end

end


function LobbyClientMember:DebugDump(full)
    SLog("\t\t [LobbyClientMember]")
    SLog("\t\t\t (internals) ")
    SLog("\t\t\t\t mapVotingLocked:     %s", self.mapVotingLocked)
end
