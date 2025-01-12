-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/thunderdome/ThunderdomeWrapper.lua
--
--    Created by:   Webster Sheets (webster@web-eworks.com)
--
-- This file handles the "import" side of the Thunderdome system sandbox interface. It provides
-- an object-oriented interface to the exposed Thunderdome methods and type information for
-- the Thunderdome GUI which should be available outside the sandbox context.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/LobbyUtils.lua")

---@class PlayerProfile
---@field name string
---@field skill number
---@field skillOffset number
---@field commSkill number
---@field commSkillOffset number
---@field adagrad number
---@field lat number
---@field long number

---@class LobbyMemberData
---@field name string
---@field steamid string
---@field avg_skill number
---@field adagrad number
---@field marine_skill number
---@field alien_skill number
---@field marine_comm_skill number
---@field alien_comm_skill number
---@field map_votes string
---@field commander_able integer
---@field team integer
---@field is_commander integer
---@field lifeforms string[]
---@field join_time integer
---@field group_id integer

-- TD globals have already been imported by ThunderdomeExports.lua

---@class ThunderdomeWrapper
ThunderdomeWrapper = {}

---@return boolean
function ThunderdomeWrapper:GetIsIdle()
    return Script.CallSandbox('ThunderdomeCall', 'GetIsIdle')
end

---@return boolean
function ThunderdomeWrapper:GetLocalDataInitialized()
    return Script.CallSandbox('ThunderdomeCall', 'GetLocalDataInitialized')
end

---@return boolean
function ThunderdomeWrapper:GetLocalSteam64Id()
    return Script.CallSandbox('ThunderdomeCall', 'GetLocalSteam64Id')
end

---@return boolean
function ThunderdomeWrapper:GetLeaveLobbyPenalizes()
    return Script.CallSandbox('ThunderdomeCall', 'GetLeaveLobbyPenalizes')
end

---@return boolean
function ThunderdomeWrapper:OnLoadCompleteMessage(msg)
    return Script.CallSandbox('ThunderdomeCall', 'OnLoadCompleteMessage', msg)
end

function ThunderdomeWrapper:LoadCompletePromptsClear()
    return Script.CallSandbox('ThunderdomeCall', 'LoadCompletePromptsClear')
end

function ThunderdomeWrapper:StartingHiveProfileFetch()
    return Script.CallSandbox('ThunderdomeCall', 'StartingHiveProfileFetch')
end

function ThunderdomeWrapper:SetHiveProfileFetched(...)
    return Script.CallSandbox('ThunderdomeCall', 'SetHiveProfileFetched', ...)
end

---@return boolean
function ThunderdomeWrapper:HasValidHiveProfileData()
    return Script.CallSandbox('ThunderdomeCall', 'HasValidHiveProfileData')
end

-- Lobby Invites
-- ============================================================================

---@return boolean
function ThunderdomeWrapper:GetHasCachedInvite()
    return Script.CallSandbox('ThunderdomeCall', 'GetHasCachedInvite')
end

---@return boolean
function ThunderdomeWrapper:GetHasRecentlyJoinedInvitedLobby()
    return Script.CallSandbox('ThunderdomeCall', 'GetHasRecentlyJoinedInvitedLobby')
end

---@return boolean
function ThunderdomeWrapper:JoinLobbyInvite(msg, isLaunchId)
    return Script.CallSandbox('ThunderdomeCall', 'JoinLobbyInvite', msg)
end

function ThunderdomeWrapper:OnRejectLobbyInvitation()
    Script.CallSandbox('ThunderdomeCall', 'OnRejectLobbyInvitation')
end

-- Lobby Data Functions
-- ============================================================================

---@return boolean
function ThunderdomeWrapper:GetIsConnectedToLobby()
    return Script.CallSandbox('ThunderdomeCall', 'GetIsConnectedToLobby')
end

---@return string lobbyId
function ThunderdomeWrapper:GetActiveLobbyId()
    return Script.CallSandbox('ThunderdomeCall', 'GetActiveLobbyId')
end

---@return number|nil lobbyState
function ThunderdomeWrapper:GetLobbyState()
    return Script.CallSandbox('Thunderdome_GetLobbyState')
end

---@return string|nil
function ThunderdomeWrapper:GetLobbyVotedMap()
    return Script.CallSandbox('Thunderdome_GetLobbyVotedMap')
end

---@return number
function ThunderdomeWrapper:GetLobbyCommanderCount()
    return Script.CallSandbox('Thunderdome_GetLobbyCommanderCount')
end

---@return string comm1
---@return string comm2
function ThunderdomeWrapper:GetLobbyCommanderIds()
    return Script.CallSandbox('Thunderdome_GetLobbyCommanderIds')
end

---@return string[] team1
---@return string[] team2
function ThunderdomeWrapper:GetLobbyTeamAssignments()
    return Script.CallSandbox('Thunderdome_GetLobbyTeamAssignments')
end

---@return boolean success
function ThunderdomeWrapper:CreateLobby()
    return Script.CallSandbox('Thunderdome_CreateLobby')
end

---@return boolean success
function ThunderdomeWrapper:CreatePrivateLobby()
    return Script.CallSandbox('Thunderdome_CreatePrivateLobby')
end

---@return boolean
function ThunderdomeWrapper:GetIsPrivateLobby()
    return Script.CallSandbox('Thunderdome_GetIsPrivateLobby')
end

---@param lobbyId string
function ThunderdomeWrapper:LeaveLobby(lobbyId, clientChoice)
    Script.CallSandbox('Thunderdome_LeaveLobby', lobbyId, clientChoice)
end

-- Group Data Functions
-- ============================================================================

---@return boolean
function ThunderdomeWrapper:GetIsGroupQueueEnabled()
    return Script.CallSandbox('ThunderdomeCall', 'GetIsGroupQueueEnabled')
end

---@param lobbyId string
---@return boolean
function ThunderdomeWrapper:GetIsGroupId(lobbyId)
    return Script.CallSandbox('ThunderdomeCall', 'GetIsGroupId', lobbyId)
end

---@return string lobbyId
function ThunderdomeWrapper:GetGroupLobbyId()
    return Script.CallSandbox('ThunderdomeCall', 'GetGroupLobbyId')
end

---@return number|nil lobbyState
function ThunderdomeWrapper:GetGroupLobbyState()
    return Script.CallSandbox('Thunderdome_GetGroupState')
end

---@return boolean success
function ThunderdomeWrapper:CreateGroup()
    return Script.CallSandbox('Thunderdome_CreateGroup')
end

---@param groupId string
function ThunderdomeWrapper:LeaveGroup(groupId)
    Script.CallSandbox('Thunderdome_LeaveGroup', groupId)
end

-- Mode functions
-- ============================================================================

---@return boolean
function ThunderdomeWrapper:GetIsSearching()
    return Script.CallSandbox('ThunderdomeCall', 'GetIsSearching')
end

function ThunderdomeWrapper:InitSearchMode()
    return Script.CallSandbox('ThunderdomeCall', 'InitSearchMode')
end

function ThunderdomeWrapper:CancelMatchSearch()
    Script.CallSandbox('ThunderdomeCall', 'CancelMatchSearch')
end

function ThunderdomeWrapper:StartGroupSearch()
    Script.CallSandbox('ThunderdomeCall', 'StartGroupSearch')
end

function ThunderdomeWrapper:CancelGroupSearch()
    Script.CallSandbox('ThunderdomeCall', 'CancelGroupSearch')
end

function ThunderdomeWrapper:AttemptServerConnect()
    Script.CallSandbox('ThunderdomeCall', 'AttemptServerConnect')
end

-- Client Member Model functions
-- ============================================================================

---@return boolean
function ThunderdomeWrapper:GetLocalCommandAble()
    return Script.CallSandbox('ThunderdomeCall', 'GetLocalCommandAble')
end

function ThunderdomeWrapper:SetLocalCommandAble(able)
    Script.CallSandbox('ThunderdomeCall', 'SetLocalCommandAble', able)
end

function ThunderdomeWrapper:SetLocalMapVotes(votedNames)
    Script.CallSandbox('ThunderdomeCall', 'SetLocalMapVotes', votedNames)
end

function ThunderdomeWrapper:SetLocalLifeformsChoices(lifeforms)
    Script.CallSandbox('ThunderdomeCall', 'SetLocalLifeformsChoices', lifeforms)
end

function ThunderdomeWrapper:SetPlayerName(name)
    Script.CallSandbox('ThunderdomeCall', 'SetPlayerName', name)
end

---@return integer teamIndex
function ThunderdomeWrapper:GetLocalClientTeam()
    return Script.CallSandbox('ThunderdomeCall', 'GetLocalClientTeam')
end

---@return boolean
function ThunderdomeWrapper:GetLocalClientIsOwner()
    return Script.CallSandbox('ThunderdomeCall', 'GetLocalClientIsOwner')
end

---@return PlayerProfile
function ThunderdomeWrapper:GetLocalPlayerProfile()
    return Script.CallSandbox('ThunderdomeCall', 'GetLocalPlayerProfile')
end

---@param lobbyId string
---@return string|nil mapVotes
function ThunderdomeWrapper:GetLocalMapVotes(lobbyId)
    return Script.CallSandbox('Thunderdome_GetLocalMapVotes', lobbyId)
end

---@param lobbyId string
---@return LobbyMemberData[]
function ThunderdomeWrapper:GetMemberListLocalData(lobbyId)
    return Script.CallSandbox('Thunderdome_GetMemberListLocalData', lobbyId)
end

---@param lobbyId string
---@return integer[]
function ThunderdomeWrapper:GetMemberListLocalGroups(lobbyId)
    return Script.CallSandbox('Thunderdome_GetMemberListLocalGroups', lobbyId)
end

---@param lobbyId string
---@param memberId string
---@return LobbyMemberData
function ThunderdomeWrapper:GetMemberLocalData(lobbyId, memberId)
    return Script.CallSandbox('Thunderdome_GetMemberLocalData', lobbyId, memberId)
end

---@param lobbyId string
---@param memberId string
---@return boolean
function ThunderdomeWrapper:GetLobbyContainsMember(lobbyId, memberId)
    return Script.CallSandbox('Thunderdome_GetLobbyContainsMember', lobbyId, memberId)
end

-- Social management functions
-- ============================================================================

function ThunderdomeWrapper:CastLocalKickVote(vote)
    Script.CallSandbox('ThunderdomeCall', 'CastLocalKickVote', vote)
end

---@param clientId string
function ThunderdomeWrapper:RequestVoteKickPlayer(clientId)
    Script.CallSandbox('ThunderdomeCall', 'RequestVoteKickPlayer', clientId)
end

---@param clientId string
function ThunderdomeWrapper:KickPlayerFromGroup(clientId)
    Script.CallSandbox('Thunderdome_KickPlayerFromGroup', clientId)
end

---@return string voteId
function ThunderdomeWrapper:GetActiveKickVote()
    return Script.CallSandbox('ThunderdomeCall', 'GetActiveKickVote')
end

---@return number
function ThunderdomeWrapper:GetActiveKickVoteTimestamp()
    return Script.CallSandbox('ThunderdomeCall', 'GetActiveKickVoteTimestamp')
end

---@return string[]
function ThunderdomeWrapper:GetMutedClients()
    return Script.CallSandbox('Thunderdome_GetMutedClients')
end

---@param clientId string
function ThunderdomeWrapper:AddMutedClient(clientId)
    Script.CallSandbox('ThunderdomeCall', 'AddMutedClient', clientId)
end

---@param clientId string
function ThunderdomeWrapper:RemoveMutedClient(clientId)
    Script.CallSandbox('ThunderdomeCall', 'RemoveMutedClient', clientId)
end

---@param message string
---@param lobbyId string
function ThunderdomeWrapper:SendChatMessage(message, lobbyId)
    Script.CallSandbox('ThunderdomeCall', 'SendChatMessage', message, lobbyId)
end

-- Thunderdome() instance
-- ============================================================================

function ThunderdomeWrapper:__tostring()
    return 'ThunderdomeWrapper {}'
end

local _tdInstance = nil

-- Lazy-load the ThunderdomeManager instance and setup the migration wrapper
---@return ThunderdomeWrapper
function Thunderdome()
    if not _tdInstance then
        Script.CallSandbox('InitThunderdome')

        -- Development-mode wrapper to forward all Thunderdome():XXX() calls into the sandbox
        -- TD-TODO: remove once all used functions have been ported to direct ThunderdomeWrapper functions
        _tdInstance = setmetatable(ThunderdomeWrapper, {
            __index = function(t, key)
                SLog("$$$ ThunderdomeWrapper:%s() generated!", key)

                rawset(t, key, function(_, ...)
                    return Script.CallSandbox('ThunderdomeCall', key, ...)
                end)

                return t[key]
            end
        })
    end

    return _tdInstance
end

-- Event Handlers
-- ============================================================================

function Thunderdome_AddListener( evt, handler )
    return Script.CallSandbox( 'Thunderdome_AddListener', evt, handler )
end

function Thunderdome_RemoveListener( evt, handler )
    return Script.CallSandbox( 'Thunderdome_RemoveListener', evt, handler )
end

function ThunderdomeWrapper:TriggerEvent( evt, ... )
    return Script.CallSandbox( 'Thunderdome_TriggerEvent', evt, ... )
end
