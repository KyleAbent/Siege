-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/ClientLobbyFunctors.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- This file has most of the "shared" routines that multiple client-modes reqire for TD.
-- These functors eliminate the need to use parent/child classes and keep things consistent.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/LobbyModel.lua")
Script.Load("lua/thunderdome/LobbyMemberModel.lua")

--[[
Table of functions which multiple types of Lobby-Clients share. Using these as a table-ref
allows for them to be re-used across Member and Owner client-types, without the need to
deal with function references inherited from a parent class, thus making it easier to maintain.

Note: All of these functions are inherently state-less, thus no data is meant to be stored in this file.

For any of the below functions that require parameters, they must match the ThunderdomeEvents
definition for the event, additionally they must include a (self) reference for the LobbyClientXYZ
client object (for data storage). All functors are supplied with a ref to the ThunderDomeManager object
and the current client-mode object (self).
--]]
kLobbyClientFunctors = 
{
    [kThunderdomeEvents.OnLocalHiveProfileDataFetched] = function(self)
        SLog("**kLobbyClientFunctors - OnLocalHiveProfileDataFetched()")
        local td = Thunderdome()
        local fetched
        local failed
        fetched, failed = td:GetHiveProfileFetchedFlags()
        if failed then
            Thunderdome():ResetMode()
            Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUIHiveProfileFetchFailure )
        else
            Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUIHiveProfileFetchSuccess )
        end
    end,
    
    --Handler for when local-client changes their in game Alias
    [kThunderdomeEvents.OnClientNameChange] = function(self)
        SLog("**kLobbyClientFunctors - OnClientNameChange()")
        local td = Thunderdome()

        -- Ensure we're in an actual lobby
        local lobbyId = td.activeLobbyId or td.groupLobbyId
        if not lobbyId then
            return
        end

        local model = Thunderdome():GetLocalClientMemberModel( lobbyId )
        assert(model)
        local serialized = model:Serialize()
        assert(serialized)
        Client.SetLobbyMemberData( lobbyId, kLobbyMemberModelDataSyncField, serialized )
    end,
    
    [kThunderdomeEvents.OnLeaveLobby] = function(self, ignoreLeavePrompt)
        SLog("**kLobbyClientFunctors - OnLeaveLobby( %s )", ignoreLeavePrompt)
        Thunderdome():TriggerEvent(kThunderdomeEvents.OnGUILeaveLobby)
    end,
    
    [kThunderdomeEvents.OnTeamShuffleComplete] = function(self, oldState, newState, lobbyId)     --TD-FIXME This causes errors, and in some cases...Owner fails to shuffle ALL CUR mems
        SLog("**kLobbyClientFunctors - OnTeamShuffleComplete()")

        local td = Thunderdome()
        local localSteamId = td:GetLocalSteam64Id()
        local team1List = td.activeLobby:GetField( LobbyModelFields.ShuffledTeam1 ) or {}
        local team2List = td.activeLobby:GetField( LobbyModelFields.ShuffledTeam2 ) or {}
        local assignedTeam = 0

        if table.icontains( team1List, localSteamId ) then
            assignedTeam = kTeam1Index
        end
    
        if assignedTeam == 0 and table.icontains( team2List, localSteamId ) then
            assignedTeam = kTeam2Index
        end
        
        assert(assignedTeam ~= 0, "Error: Local client SteamID64 not found in shuffled teams list!")

        local team1CommId = td.activeLobby:GetField( LobbyModelFields.Team1Commander )
        local team2CommId = td.activeLobby:GetField( LobbyModelFields.Team2Commander )

        local model = td:GetLocalClientMemberModel( self.activeLobbyId )

        if team1CommId == localSteamId or team2CommId == localSteamId then
            model:SetField( LobbyMemberModelFields.IsCommander, tostring(1) )
        end

        model:SetField( LobbyMemberModelFields.Team, assignedTeam )
        Client.SetLobbyMemberData( td.activeLobbyId, kLobbyMemberModelDataSyncField, model:Serialize() )

        if td.updateMode == ThunderdomeManager.kUpdateModes.LobbyOwner then
        --change lobby state now that shuffle data has propagated to clients (safer for propagation timing)
            td.activeLobby:SetState( kLobbyState.WaitingForMapVote )
            td:TriggerLobbyMetaDataUpload( td.activeLobbyId )
        end

    end,

    --Handle notifying the GUI when Lobby enters a new state (Map-vote, Waiting, etc), for local-clients only
    [kThunderdomeEvents.OnStateChange] = function(self, oldState, newState, lobbyId)
        SLog("**kLobbyClientFunctors - OnStateChange( --, %s, %s, %s )", oldState, newState, lobbyId)
        SLog("    oldState: %s", oldState)
        SLog("    newState: %s", newState)
        --assert(self.mapVotingLocked ~= nil)

        local td = Thunderdome()
        assert(td, "Error: No valid Thunderdome object found")

        --Friend-Group Handling
        local isGroupStateTick = 
            (newState == kLobbyState.GroupWaiting or newState == kLobbyState.GroupSearching or newState == kLobbyState.GroupReady)

            SLog("      isGroupStateTick: %s", isGroupStateTick)
        
        if isGroupStateTick then    --and newState ~= oldState 
            td:TriggerEvent( kThunderdomeEvents.OnGroupStateChange, newState, oldState, lobbyId )
        end

        if oldState and oldState > kLobbyState.WaitingForPlayers and newState == kLobbyState.WaitingForPlayers then
            td:TriggerEvent( kThunderdomeEvents.OnGUILobbyStateRollback, lobbyId )
        end
        
        if newState == kLobbyState.WaitingForCommanders then
            td:TriggerEvent( kThunderdomeEvents.OnGUICommandersWaitStart, lobbyId )
        end

        if oldState == kLobbyState.WaitingForCommanders and newState == kLobbyState.WaitingForExtraCommanders then
            td:TriggerEvent( kThunderdomeEvents.OnGUIMinRequiredCommandersSet, lobbyId )
        end

        -- It's possible that min commanders are only reached after the time limit.
        if (oldState == kLobbyState.WaitingForCommanders or oldState == kLobbyState.WaitingForExtraCommanders) and newState == kLobbyState.WaitingForMapVote then
            td:TriggerEvent( kThunderdomeEvents.OnGUICommandersWaitEnd, lobbyId )
        end

        if newState == kLobbyState.WaitingForMapVote then
            self.mapVotingLocked = false
            td:TriggerEvent( kThunderdomeEvents.OnGUIMapVoteStart, lobbyId )
        end
        
        if oldState == kLobbyState.WaitingForMapVote and newState > oldState then
            self.mapVotingLocked = true
            local mapStr = td:GetActiveLobby():GetField( LobbyModelFields.VotedMap ) 
            td:TriggerEvent( kThunderdomeEvents.OnGUIMapVoteComplete, kThunderdomeMaps[mapStr] )  --feed chosen map-idx (kThunderdomeMaps) 
        end

        if newState == kLobbyState.WaitingForServer then
            self.mapVotingLocked = true
            if self.lobbyCoordsLocked ~= nil then
                self.lobbyCoordsLocked = true
            end
            td:TriggerEvent( kThunderdomeEvents.OnGUIServerWaitStart, lobbyId )
        end

        if newState == kLobbyState.Ready then
            td:TriggerEvent( kThunderdomeEvents.OnGUIServerWaitComplete )
        end

        if newState == kLobbyState.Failed then
            if oldState == kLobbyState.WaitingForServer then
                td:TriggerEvent( kThunderdomeEvents.OnGUIServerWaitFailed )
            elseif oldState < kLobbyState.WaitingForServer then
                td:TriggerEvent( kThunderdomeEvents.OnGUIMatchProcessFailed )
            end
        end

    end,

    [kThunderdomeEvents.OnLobbyCreated] = function( self )
        SLog("**kLobbyClientFunctors - OnLobbyCreated()")
        Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUILobbyCreated )
    end,
    
    [kThunderdomeEvents.OnLobbyCreateFailed] = function( self, errorCode )
        SLog("**kLobbyClientFunctors - OnLobbyCreateFailed()")
        Thunderdome():ResetMode()
        Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUILobbyCreateFailed, errorCode )
    end,

    --Populate LOCAL client's data field with their associated data (full update only done on-join)
    [kThunderdomeEvents.OnLobbyJoined] = function( self, enterCode, lobbyId )
        SLog("**kLobbyClientFunctors - OnLobbyJoined( --, %s, %s )", enterCode, lobbyId)
        
        local td = Thunderdome()
        assert(td, "Error: Failed to get Thunderdome object!")

        local model = td:GetLocalClientMemberModel( lobbyId )
        assert(model, "Error: No local-client MemberModel found")
        model:DebugDump()
        model:SetField(LobbyMemberModelFields.JoinTime, tostring(Client.GetTdTimestamp()))
        local serialized = model:Serialize()
        assert(serialized)
        SLog("|****|  --  Setting LOCAL member data:\n%s", serialized)
        Client.SetLobbyMemberData( lobbyId, kLobbyMemberModelDataSyncField, serialized )
        SLog("\t\t  Set member data, trigger GUI event...")
        Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUILobbyJoined, lobbyId )
    end,

    [kThunderdomeEvents.OnLobbyJoinFailed] = function( self, errorCode )
        SLog("**kLobbyClientFunctors - OnLobbyJoinFailed()")
        Thunderdome():ResetMode()
        Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUILobbyJoinFailed, errorCode )
    end,
    
    [kThunderdomeEvents.OnLobbyMemberJoin] = function( self, memberId, lobbyId )
        SLog("**kLobbyClientFunctors - OnLobbyMemberJoin( --, %s, %s )", memberId, lobbyId)
        assert(memberId)
        local td = Thunderdome()
        assert(td, "Error: Failed to get Thunderdome object!")

        local memberName = "UNKNOWN"
        if td:GetIsGroupId( lobbyId ) then
            memberName = td:GetGroupLobby():GetMemberName( memberId )
        else
            memberName = td:GetActiveLobby():GetMemberName( memberId )
        end
        
        local message = memberName .. " " .. Locale.ResolveString( "LOBBY_MEMBER_JOIN_SUFFIX" )
        SLog("CHAT:  %s", message)
        td:TriggerEvent( kThunderdomeEvents.OnGUIChatMessage, "SYSTEM", lobbyId, message, kThunderdomeSystemUserId, kThunderdomeSystemUserId )
    end,
    
    --Listen for (as relay) Member LEAVE events, to trigger GUI updates
    [kThunderdomeEvents.OnLobbyMemberLeave] = function( self, memberId, lobbyId )
        SLog("**kLobbyClientFunctors - OnLobbyMemberLeave( --, %s, %s )", memberId, lobbyId)
        assert(memberId)
        local td = Thunderdome()
        assert(td, "Error: Failed to get Thunderdome object!")

        local memberName = "UNKNOWN"
        if td:GetIsGroupId( lobbyId ) then
            memberName = td:GetGroupLobby():GetMemberName( memberId )
        else
            memberName = td:GetActiveLobby():GetMemberName( memberId )
        end
        
        local message = memberName .. " " .. Locale.ResolveString( "LOBBY_MEMBER_LEFT_SUFFIX" )
        SLog("CHAT:  %s", message)

        td:RemoveMember( lobbyId, memberId )
        td:ReloadLobbyMembers( lobbyId )

        td:TriggerEvent( kThunderdomeEvents.OnGUIChatMessage, "SYSTEM", lobbyId, message, kThunderdomeSystemUserId, kThunderdomeSystemUserId )
    end,
    
    --Listen for (as relay) Member KICKED events, to trigger GUI updates
    [kThunderdomeEvents.OnLobbyMemberKicked] = function( self, memberId, lobbyId )
        SLog("**kLobbyClientFunctors - OnLobbyMemberKicked( --, %s, %s )", memberId, lobbyId)
        assert(memberId)
        local td = Thunderdome()
        assert(td, "Error: Failed to get Thunderdome object!")

        local memberName = "UNKNOWN"
        if td:GetIsGroupId( lobbyId ) then
            memberName = td:GetGroupLobby():GetMemberName( memberId )
        else
            memberName = td:GetActiveLobby():GetMemberName( memberId )
        end

        local message = memberName .. " " .. Locale.ResolveString( "LOBBY_MEMBER_KICKED_SUFFIX" )
        SLog("CHAT:  %s", message)

        td:RemoveMember( lobbyId, memberId )
        td:ReloadLobbyMembers( lobbyId )

        td:TriggerEvent( kThunderdomeEvents.OnGUIChatMessage, "SYSTEM", lobbyId, message, kThunderdomeSystemUserId, kThunderdomeSystemUserId )
    end,

    --Handle received chat message from lobby member, do not send to GUI if that client is muted
    [kThunderdomeEvents.OnChatMessage] = function( self, lobbyId, sentById, senderName, message, senderTeam )
        Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUIChatMessage, lobbyId, senderName, message, senderTeam, sentById )
    end,

}

