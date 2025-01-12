-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua/Thunderdome/LobbyModel.lua
-- Author: Brock 'McGlaspie' Gillespie (mcglaspie@gmail.com)
--
-- todo descrp
-- 
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/IterableDict.lua")

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/LobbyMemberModel.lua")


-------------------------------------------------------------------------------


class 'LobbyModel'

LobbyModel.kLobbyDataMaxSerializedLength = 8104


function LobbyModel:Init()
    self.data = IterableDict()
    self.members = {}
    self.previousState = nil
end

function LobbyModel:Reset()
    self.data:Clear()
    self.members = {}
end

function LobbyModel:GetId()
    return self.data[LobbyModelFields.Id]
end

function LobbyModel:GetType()
    return self.data[LobbyModelFields.Type]
end

function LobbyModel:GetState()
    return self.data[LobbyModelFields.State]
end

function LobbyModel:GetIsGroup()
    return self.data[LobbyModelFields.IsGroup]
end

function LobbyModel:SetIsGroup(isFriendsGroup)
    assert( type(isFriendsGroup) == "boolean", "Error: invalid group flag passed" )
    if isFriendsGroup == true then
        assert( self.data[LobbyModelFields.Type] == Client.SteamLobbyType_Private, "Error: cannot set Friend-Group flag for non-private lobby type" )
    end
    self.data[LobbyModelFields.IsGroup] = isFriendsGroup
end

function LobbyModel:SetState( value )
    --SLog("\t LobbyModel:SetState( %s )", kLobbyState[tonumber(value)] )
    --assert(value, "Error: missing LobbyState value")
    
    local numVal = tonumber(value)
    assert( kLobbyState[numVal], "Error: invalid LobbyState value passed, bounds issue" )

    local asEnumVal = kLobbyState[ kLobbyState[numVal] ]

    self.previousState = self.data[LobbyModelFields.State]

    self.data[LobbyModelFields.State] = asEnumVal
    self.data[LobbyModelFields.StateChangeTime] = Client.GetTdTimestamp()
end

function LobbyModel:GetPreviousState()
    --SLog("LobbyModel:GetPreviousState()")
    --SLog("   previousState: %s", self.previousState)
    --SLog("           state: %s", self.data[LobbyModelFields.State])

    if self.previousState == nil then
    --this check is added so LobbyMember vs LobbyOwner works the same in TDMgr context
    --We must do it this way, as State is set (to activeLobby) _before_ data is propagated
    --via lobby meta-data now. This is a byproduct of switching to serialization of all data
        return self.data[LobbyModelFields.State]
    end
    return self.previousState
end

--Note: these values are not always stored in lobby meta-data ready format (e.g. not strings/integer)
function LobbyModel:GetField( fieldId )
    assert(fieldId)

    -- TD-FIXME: returning tables by value allows downstream owners to silently mutate them and corrupt lobby state.
    -- A proper solution will be implemented with TD sandboxing functionality, for now internally make a copy of the
    -- table and return it to the caller.
    if self.data[fieldId] and (fieldId == LobbyModelFields.PrevOwners or fieldId == LobbyModelFields.ShuffledTeam1 or fieldId == LobbyModelFields.ShuffledTeam2 or fieldId == LobbyModelFields.Kicked) then
        return table.duplicate(self.data[fieldId])
    end

    return self.data[fieldId]
end

function LobbyModel:GetFieldAsString( fieldId )
    assert(fieldId)
    --assert( self.data[fieldId], "LobbyModel field-%s[%s] not found / does not exist!", fieldId, LobbyMemberModelFields[fieldId] )

    if self.data[fieldId] then
        if fieldId == LobbyModelFields.Coords then
            return self.data[fieldId][1] .. "," .. self.data[fieldId][2]
        elseif fieldId == LobbyModelFields.PrevOwners or fieldId == LobbyModelFields.ShuffledTeam1 or fieldId == LobbyModelFields.ShuffledTeam2 then
            return table.concat( self.data[fieldId], "," )
        end

        return tostring( self.data[fieldId] )
    end

    SLog("\t WARNING: Empty LobbyModelField fetched - %s[%s]", LobbyModelFields[fieldId], fieldId)
    return ""
end

--Note: All Lobby meta-data coming from Steamworks calls will be string type
function LobbyModel:SetField( fieldId, value )
    assert(fieldId)
    --assert(value) --XX removed, to allow 'nil' to be set
    local parsedValue

    --Handle special-cases for specific fields
    if fieldId == LobbyModelFields.Coords then

        if type(value) == "string" then
            assert(type(value) == "string") --??  ...allow table?
            --parse into table chunks
            local t = StringSplit( value, ',')
            assert(#t == 2)
            local lat = tonumber(t[1])
            local long = tonumber(t[2])
            parsedValue = { lat, long }
        elseif type(value) == "table" then
            assert(#value == 2)
            assert(type(value[1]) == "number")
            assert(type(value[2]) == "number")
            parsedValue = { value[1], value[2] }
        else
            assert(false)
        end

    elseif fieldId == LobbyModelFields.PrevOwners or fieldId == LobbyModelFields.ShuffledTeam1 or fieldId == LobbyModelFields.ShuffledTeam2 or fieldId == LobbyModelFields.Kicked then

        if type(value) == "table" then
            parsedValue = value

        elseif type(value) == "string" then

            local t = StringSplit( value, ',')
            if (#t == 1 and t[1] ~= nil and t[1] ~= "") or #t > 1 then
            --make sure we're not adding "empty" values
                parsedValue = t
            else
                parsedValue = {}    
            end

        else
            parsedValue = {}
        end

    elseif fieldId == LobbyModelFields.Build or fieldId == LobbyModelFields.LastSrvReqTime or fieldId == LobbyModelFields.StateChangeTime or fieldId == LobbyModelFields.MedianSkill or fieldId == LobbyModelFields.Version then
        parsedValue = tonumber(value)

    elseif fieldId == LobbyModelFields.Type then
        assert(GetIsValidLobbyType(tonumber(value)), "Error: Invalid Lobby-Type value")
        parsedValue = tonumber(value)

    elseif fieldId == LobbyModelFields.State then
        parsedValue = kLobbyState[ kLobbyState[tonumber(value)] ]

    elseif fieldId == LobbyModelFields.IsGroup then
        parsedValue = tonumber(value) == 1

    else
        parsedValue = value --string
    end

    self.data[fieldId] = parsedValue
end

--Adds a new LobbyMemberModel to this object's cache
function LobbyModel:AddMemberModel( member )
    SLog("LobbyModel:AddMemberModel( [LobbyMemberModel] )")
    assert(member)
    local memId = member:GetField(LobbyMemberModelFields.SteamID64)
    assert(memId ~= nil and memId ~= "")
    table.insert( self.members, member )
end

function LobbyModel:RemoveMemberModel( memberId )
    SLog("LobbyModel:RemoveMemberModel( %s )", memberId)
    assert(memberId)
    local removed = false
    for i = 1, #self.members do
        if self.members[i]:GetField( LobbyMemberModelFields.SteamID64 ) == memberId then
            SLog("\t Removed %s at Idx[%s]", memberId, i)
            table.remove( self.members, i )
            removed = true
            break
        end
    end
    return removed
end

function LobbyModel:OverwriteMemberModel( member )
    SLog("\t LobbyModel:OverwriteMemberModel( [LobbyMemberModel] )")
    assert(member)
    local memId = member:GetField(LobbyMemberModelFields.SteamID64)
    for i = 1, #self.members do
        if self.members[i] and self.members[i]:GetField(LobbyMemberModelFields.SteamID64) == memId then
            self.members[i] = member
            return true
        end
    end
    SLog("\t Failed to find matching MemberID[%s] for supplied model", memId)
    return false
end

function LobbyModel:GetMemberModel( memberId )
    assert(memberId)
    for i = 1, #self.members do
        if self.members[i] and memberId == self.members[i]:GetField( LobbyMemberModelFields.SteamID64 ) then
            return self.members[i]
        end
    end
    return nil --false?
end

--Simple convinience function for accessing lobby client display name
function LobbyModel:GetMemberName( steamId )
    assert(steamId)
    for i = 1, #self.members do
        if steamId == self.members[i]:GetField( LobbyMemberModelFields.SteamID64 ) then
            return self.members[i]:GetField( LobbyMemberModelFields.Name )
        end
    end
    return kDefaultPlayerName
end

function LobbyModel:GetMembersIdList()
    local list = {}
    for i = 1, #self.members do
        local mId = self.members[i]:GetField( LobbyMemberModelFields.SteamID64 )
        if mId and mId ~= "" then
            table.insert( list, mId )
        end
    end
    return list
end

function LobbyModel:GetFilteredMembers(memIdList)
    assert(memIdList)

    local filteredList = {}
    for i = 1, #self.members do
        if table.icontains( memIdList, self.members[i]:GetField( LobbyMemberModelFields.SteamID64 ) ) then
            table.insert( filteredList, self.members[i] )
        end
    end
    return filteredList
end

function LobbyModel:GetMembers()
    return self.members
end

function LobbyModel:GetMemberCount()
    return #self.members
end

function LobbyModel:FlushAllMembers()
    self.members = nil
    self.members = {}
end

function LobbyModel:Serialize()
    --SLog("-LobbyModel:Serialize()-")
    local serialized = ""
    local temp = {}

    --Ignore these 'static' fields, as they're set via Steam, not model
    local skipFields = 
    {
        LobbyModelFields.Build,
        LobbyModelFields.SteamBranch,
        LobbyModelFields.Version,
    }

    for i = 1, #LobbyModelFields do
        local fieldId = LobbyModelFields[ LobbyModelFields[i] ]
        if not table.icontains( skipFields, fieldId ) then
            if self.data[fieldId] ~= nil then   --self.data[fieldId] and (removed, as some fields are booleans)

                local fieldVal = self.data[fieldId]
                if fieldId == LobbyModelFields.IsGroup then --convert boolean
                    fieldVal = fieldVal and 1 or 0
                end

                temp[ LobbyModelFields[i] ] = fieldVal
            end
        end
    end
    --SLog("  Serializable Data: %s", temp)
    serialized = json.encode( temp, { indent = false } )
    if string.len(serialized) > self.kLobbyDataMaxSerializedLength then
        SLog("WARNING: LobbyModel serialized format exceeds maximum field length! - [%s]", #json)
    end
    return serialized
end

function LobbyModel:Deserialize( serialized )
    --SLog("-LobbyModel:Deserialize( ** )-")
    --SLog("  MetaData: %s", serialized)
    assert(serialized and serialized ~= "", "Error: No LobbyModel serialized string passed")
    local obj, pos, err = json.decode(serialized, 1, nil)
    assert(not err, "Error: Failed to deserialize LobbyMemberModel")
    assert(obj, "Error: Empty deserialized data for LobbyMemberModel")

    --SLog("    Deserialized MetaData: %s", obj)
    
    self:SetField( LobbyModelFields.Id, obj.Id )
    self:SetField( LobbyModelFields.Type, obj.Type )
    
    self:SetState( obj.State )
    self:SetField( LobbyModelFields.StateChangeTime, obj.StateChangeTime )

    self:SetField( LobbyModelFields.NumMembers, obj.NumMembers )
    self:SetField( LobbyModelFields.PrevOwners, obj.PrevOwners )

    self:SetField( LobbyModelFields.ServerReqId, obj.ServerReqId )
    self:SetField( LobbyModelFields.ServerReqAttempts, obj.ServerReqAttempts )
    self:SetField( LobbyModelFields.ServerReqStatus, obj.ServerReqStatus )
    self:SetField( LobbyModelFields.LastSrvReqTime, obj.LastSrvReqTime )

    self:SetField( LobbyModelFields.ServerIP, obj.ServerIP )
    self:SetField( LobbyModelFields.ServerPort, obj.ServerPort )
    self:SetField( LobbyModelFields.ServerPassword, obj.ServerPassword )

    self:SetField( LobbyModelFields.Coords, obj.Coords )
    self:SetField( LobbyModelFields.VotedMap, obj.VotedMap )
    self:SetField( LobbyModelFields.ShuffledTeam1, obj.ShuffledTeam1 )
    self:SetField( LobbyModelFields.ShuffledTeam2, obj.ShuffledTeam2 )
    self:SetField( LobbyModelFields.Team1Commander, obj.Team1Commander )
    self:SetField( LobbyModelFields.Team2Commander, obj.Team2Commander )
    self:SetField( LobbyModelFields.MedianSkill, obj.MedianSkill )

    self:SetField( LobbyModelFields.Kicked, obj.Kicked )

    self:SetField( LobbyModelFields.IsGroup, obj.IsGroup )
    self:SetField( LobbyModelFields.NumGroups, obj.NumGroups )
    self:SetField( LobbyModelFields.TargetLobbyId, obj.TargetLobbyId )

    return true
end

function LobbyModel:DebugDump(full)
    SLog("[LobbyModel]")

    SLog("\t Data Fields:")
    for field, value in pairs(self.data) do
        local fieldName = GetLobbyFieldName(field)

        if field == LobbyModelFields.State then
            value = kLobbyState[value]
        --TODO write binding-layer sope converter for Lobby Type enum
        end

        SLog("\t\t %s:  %s", fieldName, value)
    end

    if full then
        SLog("\t Members Data:")
        for i = 1, #self.members do
            self.members[i]:DebugDump()
        end
    end

end

