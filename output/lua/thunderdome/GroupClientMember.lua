-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/GroupClientMember.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")

Script.Load("lua/thunderdome/LobbyUtils.lua")

Script.Load("lua/thunderdome/LobbyMemberModel.lua")
Script.Load("lua/thunderdome/LobbyModel.lua")

Script.Load("lua/thunderdome/ClientLobbyFunctors.lua")


class 'GroupClientMember'


function GroupClientMember:Initialize()
    self:RegisterEvents()
end

function GroupClientMember:Destroy()
    self:UnregisterEvents()
end


function GroupClientMember:RegisterEvents()
    --Setup event for when the Lobby's state value changes, denotes various 'phases' of match setup
    Thunderdome_AddListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )

    Thunderdome_AddListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    Thunderdome_AddListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )

    Thunderdome_AddListener( kThunderdomeEvents.OnGroupStateChange, self._OnGUIGroupStateChange )
end

function GroupClientMember:UnregisterEvents()
    Thunderdome_RemoveListener( kThunderdomeEvents.OnStateChange, kLobbyClientFunctors[kThunderdomeEvents.OnStateChange] )

    Thunderdome_RemoveListener( kThunderdomeEvents.OnChatMessage, kLobbyClientFunctors[kThunderdomeEvents.OnChatMessage] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoined, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoined] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyJoinFailed, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyJoinFailed] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberJoin, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberJoin] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberLeave, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberLeave] )
    Thunderdome_RemoveListener( kThunderdomeEvents.OnLobbyMemberKicked, kLobbyClientFunctors[kThunderdomeEvents.OnLobbyMemberKicked] )

    Thunderdome_RemoveListener( kThunderdomeEvents.OnGroupStateChange, self._OnGUIGroupStateChange )
end


GroupClientMember._OnGUIGroupStateChange = function( self, newState, oldState, lobbyId )
    SLog("GroupClientMember:_OnGUIGroupStateChange( --, %s, %s, %s )", newState, oldState, lobbyId )

    local tdGui = GetThunderdomeMenu()
    assert(tdGui, "Error: No ThunderdomeMenu object found")

    local barState = GetStatusBarStateFromLobbyState( newState )
    tdGui:SetStatusBarStage( barState, lobbyId )
    
    if newState == kLobbyState.GroupWaiting and oldState > kLobbyState.GroupWaiting then
        Thunderdome():TriggerEvent( kThunderdomeEvents.OnGUIGroupStateRollback, lobbyId )
    end
end

function GroupClientMember:Update( td, deltaTime, time )
    assert(td, "Error: No valid Thunderdome object found")

    --check and trap we're in the right mode (give LobbyModel creation enough time, etc. on joining)
    if td.groupLobby then

        local lobby = td:GetGroupLobby()
        assert(lobby, "Error: No Group LobbyModel object found")

        local lobState = lobby:GetState()

        local readyMatch = 
            lobState == kLobbyState.GroupReady and 
            not Shared.GetThunderdomeEnabled()
        
        if readyMatch then
        --Owner found or created an applicable Match lobby, join it and leave group.
            SLog("  GroupClientMember:Update() -- readyMatch: %s", readyMatch)
            
            td:SetLocalGroupId( lobby:GetId() )
            td:LeaveGroup( lobby:GetId(), true )
            --Join set Match lobby after leaving friends-group 
            td:JoinLobby( lobby:GetField( LobbyModelFields.TargetLobbyId ), false, false )
        end

    end

end


function GroupClientMember:DebugDump(full)
    SLog("\t\t [GroupClientMember]")
    --SLog("\t\t\t (internals) ")
end