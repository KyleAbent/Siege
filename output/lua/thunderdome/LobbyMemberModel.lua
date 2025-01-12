-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua/thunderdome/LobbyMemberModel.lua
-- Author: Brock 'McGlaspie' Gillespie (mcglaspie@gmail.com)
--
-- todo descrp
-- 
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/IterableDict.lua")

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")


-------------------------------------------------------------------------------


class 'LobbyMemberModel'


function LobbyMemberModel:Init( memberData )
    self.data = IterableDict()
    
    if memberData and type(memberData) == "string" then
        self:Deserialize( memberData )
    end
end

function LobbyMemberModel:Reset()
    self.data:Clear()
end

function LobbyMemberModel:GetSteamId64()
    return self.data[LobbyMemberModelFields.SteamID64]
end

function LobbyMemberModel:AssignTeam( teamIdx )
    assert(teamIdx)
    assert(teamIdx == kTeam1Index or teamIdx == kTeam2Index)
    self.data[LobbyMemberModelFields.Team] = teamIdx
end

function LobbyMemberModel:AbleToCommand( isAwesome )
    assert(type(isAwesome) == "boolean")
    self.data[LobbyMemberModelFields.CommanderAble] = isAwesome and 1 or 0
end

function LobbyMemberModel:GetIsCommander()
    return self.data[LobbyMemberModelFields.IsCommander] == 1
end

--validation functions for data fields
local function ValidateLifeforms(val)
    assert(val)
    for i = 1, #val do
        if not kLobbyLifeformTypes[val[i]] then
            return false
        end
    end
    return true
end

--Note: the value sets override any existing value in its field
function LobbyMemberModel:SetField( fieldId, value )
    assert(fieldId)
        
    if fieldId == LobbyMemberModelFields.Coords then

        if type(value) == "table" then
            assert(value and #value == 2)
            assert(type(value[1]) == "number")
            assert(type(value[2]) == "number")
            self.data[fieldId] = value
        else
            assert(value and type(value) == "string")
            --return specifically allow to return > 2 elements (to capture invalid data/state in log)
            local t = StringSplit( value, ',')
            assert(#t == 2)
            --FIXME on bad formatting/table data, could result in NaN
            local lat = tonumber(t[1])
            local long = tonumber(t[2])

            self.data[fieldId] = { lat, long }
        end

    elseif fieldId == LobbyMemberModelFields.Lifeforms then
        
        if type(value) == "string" and value ~= "" then
            value = StringSplit( value, "," )
            assert(ValidateLifeforms(value))
            self.data[fieldId] = value
        elseif type(value) == "table" and #value > 0 then
            assert(ValidateLifeforms(value))
            self.data[fieldId] = value
        else
            --allow for emptying out field
            self.data[fieldId] = {}
        end
        
    elseif fieldId == LobbyMemberModelFields.CommanderAble then
        value = value == nil and 0 or value
        assert(value >= 0 and value <= 1, "Error: Invalid CommanderAble flag value, only 0 or 1 allowed")
        self.data[fieldId] = tonumber(value)
        
    elseif fieldId == LobbyMemberModelFields.AvgSkill or
           fieldId == LobbyMemberModelFields.Team or
           fieldId == LobbyMemberModelFields.IsCommander or
           fieldId == LobbyMemberModelFields.Adagrad or
           fieldId == LobbyMemberModelFields.JoinTime then
        value = value == nil and 0 or value
        self.data[fieldId] = tonumber(value)
        
    elseif fieldId == LobbyMemberModelFields.MapVotes and value ~= "" then
        self.data[fieldId] = tostring(value)

    else
        self.data[fieldId] = tostring(value)
    end
end

function LobbyMemberModel:GetField( fieldId )
    assert(fieldId)

    if self.data[ fieldId ] then
        return self.data[fieldId]
    end

    return false
end

function LobbyMemberModel:GetFieldAsString( fieldId )
    assert(fieldId)
    assert( self.data[fieldId] )
    local fVal = self.data[fieldId]
    return tostring(fVal)
end

--Returns JSON string of this model
function LobbyMemberModel:Serialize()

    local data = 
    {
        name = self.data[LobbyMemberModelFields.Name],
        steamid = self.data[LobbyMemberModelFields.SteamID64],
        avg_skill = self.data[LobbyMemberModelFields.AvgSkill],
        adagrad = self.data[LobbyMemberModelFields.Adagrad],
        marine_skill = self.data[LobbyMemberModelFields.MarineSkill],
        alien_skill = self.data[LobbyMemberModelFields.AlienSkill],
        marine_comm_skill = self.data[LobbyMemberModelFields.MarineCommSkill],
        alien_comm_skill = self.data[LobbyMemberModelFields.AlienCommSkill],
        coords = self.data[LobbyMemberModelFields.Coords],
        map_votes = self.data[LobbyMemberModelFields.MapVotes],
        commander_able = self.data[LobbyMemberModelFields.CommanderAble],
        team = self.data[LobbyMemberModelFields.Team],
        is_commander = self.data[LobbyMemberModelFields.IsCommander],
        lifeforms = self.data[LobbyMemberModelFields.Lifeforms],
        join_time = self.data[LobbyMemberModelFields.JoinTime],
        group_id = self.data[LobbyMemberModelFields.GroupId],
    }
    --Note: indentations are intentionally not used here (wastes chars)
    return json.encode( data, { indent = false } )
end

function LobbyMemberModel:Deserialize( strData )
    SLog("\t LobbyMemberModel:Deserialize( %s )", strData)

    assert(strData ~= "", "Error: Empty member meta-data screen")
    local obj, pos, err = json.decode(strData, 1, nil)
    assert(not err, "Error: Failed to deserialize LobbyMemberModel")
    assert(obj, "Error: Empty deserialized data for LobbyMemberModel")

    self:SetField( LobbyMemberModelFields.Name, obj.name )
    self:SetField( LobbyMemberModelFields.SteamID64, obj.steamid )
    self:SetField( LobbyMemberModelFields.AvgSkill, obj.avg_skill )
    self:SetField( LobbyMemberModelFields.Adagrad, obj.adagrad )
    self:SetField( LobbyMemberModelFields.MarineSkill, obj.marine_skill )
    self:SetField( LobbyMemberModelFields.AlienSkill, obj.alien_skill )
    self:SetField( LobbyMemberModelFields.MarineCommSkill, obj.marine_comm_skill )
    self:SetField( LobbyMemberModelFields.AlienCommSkill, obj.alien_comm_skill )
    self:SetField( LobbyMemberModelFields.Coords, obj.coords )
    self:SetField( LobbyMemberModelFields.MapVotes, obj.map_votes )
    self:SetField( LobbyMemberModelFields.CommanderAble, obj.commander_able )
    self:SetField( LobbyMemberModelFields.Team, obj.team )
    self:SetField( LobbyMemberModelFields.IsCommander, obj.is_commander )
    self:SetField( LobbyMemberModelFields.Lifeforms, obj.lifeforms )
    self:SetField( LobbyMemberModelFields.JoinTime, obj.join_time )
    self:SetField( LobbyMemberModelFields.GroupId, obj.group_id )
end

function LobbyMemberModel:ExportAsTable()

    return 
    {
        name = self.data[LobbyMemberModelFields.Name],
        steamid = self.data[LobbyMemberModelFields.SteamID64],
        avg_skill = self.data[LobbyMemberModelFields.AvgSkill],
        adagrad = self.data[LobbyMemberModelFields.Adagrad],
        marine_skill = self.data[LobbyMemberModelFields.MarineSkill],
        alien_skill = self.data[LobbyMemberModelFields.AlienSkill],
        marine_comm_skill = self.data[LobbyMemberModelFields.MarineCommSkill],
        alien_comm_skill = self.data[LobbyMemberModelFields.AlienCommSkill],
        map_votes = self.data[LobbyMemberModelFields.MapVotes],
        commander_able = self.data[LobbyMemberModelFields.CommanderAble],
        team = self.data[LobbyMemberModelFields.Team],
        is_commander = self.data[LobbyMemberModelFields.IsCommander],
        lifeforms = self.data[LobbyMemberModelFields.Lifeforms],
        join_time = self.data[LobbyMemberModelFields.JoinTime],
        group_id = self.data[LobbyMemberModelFields.GroupId],
    }

end

function LobbyMemberModel:DebugDump()
    SLog("\t\t [LobbyMemberModel]")
    --SLog("%s", self.data)
    for field, value in pairs(self.data) do
        local memberFieldName = GetLobbyMemberFieldName(field)
        SLog("\t\t\t %s:  %s", memberFieldName, value)
    end
end