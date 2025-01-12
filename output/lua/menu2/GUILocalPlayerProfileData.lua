-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/GUILocalPlayerProfileData.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--    
--    Singleton GUI object that just serves to hold data related to the local player.  Yea, it's a
--    bit odd, wasteful to use a GUIObject for this, as there's no visual component -- just data,
--    but it's more than worth it to leverage the provided event callback system, which is super
--    convenient when dealing with async stuff.
--  
--  Properties  -TODO- Update below
--      PlayerName      The player's in-game name.
--      Skill           The player's hive skill value.
--      Level           The player's hive level.
--      XP              The amount of experience the player has.
--      Score           Total amount of points player has earned.
--      AdagradSum      Not a clue what this is, but it's used in hive skill calculation.
--  
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/Badges_Client.lua")
Script.Load("lua/PlayerRanking.lua")


-- Define a special value to indicate that no AdagradSum data is available (this is NOT the same as
-- 0).  We need this because property values cannot be nil.
do
    local kNoAdagradSum = {"NoAdagradSum"}
    setmetatable(kNoAdagradSum, { __tostring = function() return "{NoAdagradSum}" end })
    NoAdagradSum = ReadOnly(kNoAdagradSum)
end

local kMaxHiveProfileAttemptsLimit = 3

---@class GUILocalPlayerProfileData : GUIObject
class "GUILocalPlayerProfileData" (GUIObject)

local kSpoofHiveLevelOptionPath = "debug/spoof-hive-level"

GUILocalPlayerProfileData:AddClassProperty("PlayerName", "")
GUILocalPlayerProfileData:AddClassProperty("Skill", -1)
GUILocalPlayerProfileData:AddClassProperty("SkillOffset", -1)
GUILocalPlayerProfileData:AddClassProperty("CommSkill", -1)
GUILocalPlayerProfileData:AddClassProperty("CommSkillOffset", -1)
GUILocalPlayerProfileData:AddClassProperty("TDSkill", -1)
GUILocalPlayerProfileData:AddClassProperty("TDSkillOffset", -1)
GUILocalPlayerProfileData:AddClassProperty("TDAdagradSum", NoAdagradSum, true)
GUILocalPlayerProfileData:AddClassProperty("TDCommSkill", -1)
GUILocalPlayerProfileData:AddClassProperty("TDCommSkillOffset", -1)
GUILocalPlayerProfileData:AddClassProperty("TDCommanderAdagradSum", NoAdagradSum, true)
GUILocalPlayerProfileData:AddClassProperty("Level", -1)
GUILocalPlayerProfileData:AddClassProperty("XP", 0)
GUILocalPlayerProfileData:AddClassProperty("Score", 0)
GUILocalPlayerProfileData:AddClassProperty("AdagradSum", NoAdagradSum, true)
GUILocalPlayerProfileData:AddClassProperty("CommanderAdagradSum", NoAdagradSum, true)
GUILocalPlayerProfileData:AddClassProperty("Lat", 0)
GUILocalPlayerProfileData:AddClassProperty("Long", 0)

local profileDataObject
function GetLocalPlayerProfileData()
    return profileDataObject
end

local function ParseGeoCoordsResponse( response, errMsg, errCode )

    Log("GetGeoCoords Response:\n%s", response)
    local obj, pos, err = json.decode(response, 1, nil)

--FIXME Below needs to ONLY effect TD usability, and NOT "general" servers!
    if not obj then
        Log("Error: failed to retrieve Hive profile:\n%s\n%s\n%s", obj, pos, err)
        Thunderdome():SetHiveProfileFetched( true, true, "Failed to receive data" )
        return false
    end

    if obj and err then
        Thunderdome():SetHiveProfileFetched( true, true, err )
        return false
    end

    --IP based on time of request, geo-ip is not cached in remote system
    local lat   = tonumber(obj._lat) or -1
    local long  = tonumber(obj._long) or -1
    
    local tdSysEnabled = obj.td_enabled ~= nil and obj.td_enabled == true

    --Normal ranking
    local skill = Client.GetUserStat_Int( Client.kSkillFields_Skill )
    local skillOffset = Client.GetUserStat_Int( Client.kSkillFields_SkillOffset )
    local skillSign = Client.GetUserStat_Int( Client.kSkillFields_SkillSign )
    local commSkill = Client.GetUserStat_Int( Client.kSkillFields_CommSkill )
    local commSkillOffset = Client.GetUserStat_Int( Client.kSkillFields_CommSkillOffset )
    local commSkillSign = Client.GetUserStat_Int( Client.kSkillFields_CommSkillSign )
    local adagrad = Client.GetUserStat_Float( Client.kSkillFields_Adagrad )
    local commAdagrad = Client.GetUserStat_Float( Client.kSkillFields_CommAdagrad )

    --Matched play ranking
    local td_skill = Client.GetUserStat_Int( Client.kSkillFields_TD_Skill )
    local td_skillOffset = Client.GetUserStat_Int( Client.kSkillFields_TD_SkillOffset )
    local td_skill_sign = Client.GetUserStat_Int( Client.kSkillFields_TD_SkillSign )
    local td_commSkill = Client.GetUserStat_Int( Client.kSkillFields_TD_CommSkill )
    local td_commSkillOffset = Client.GetUserStat_Int( Client.kSkillFields_TD_CommSkillOffset )
    local td_commSkillSign = Client.GetUserStat_Int( Client.kSkillFields_TD_CommSkillSign )
    local td_adagrad = Client.GetUserStat_Float( Client.kSkillFields_TD_Adagrad )
    local td_commAdagrad = Client.GetUserStat_Float( Client.kSkillFields_TD_CommAdagrad )

    local xp = Client.GetUserStat_Int( Client.kSkillFields_Xp )
    local score = Client.GetUserStat_Int( Client.kSkillFields_Score )
    local level = Client.GetUserStat_Int( Client.kSkillFields_Level )
    
    --Update values per Sign field, no thanks to Steam wonkiness
    skillOffset = skillSign < 1 and skillOffset * -1 or skillOffset
    commSkillOffset = commSkillSign < 1 and commSkillOffset * -1 or commSkillOffset

    td_skillOffset = td_skill_sign < 1 and td_skillOffset * -1 or td_skillOffset
    td_commSkillOffset = td_commSkillSign < 1 and td_commSkillOffset * -1 or td_commSkillOffset

    Thunderdome():SetPlayerName( profileDataObject:GetPlayerName() )
    Client.SetLocalHiveProfileData(
        skill, commSkill, skillOffset, commSkillOffset, adagrad,
        td_skill, td_commSkill, td_skillOffset, td_commSkillOffset, td_adagrad,
        level, xp, score,
        "", --Note: badges now handled via Steam items
        lat, long,
        tdSysEnabled
    )

    profileDataObject:SetLevel(level)
    profileDataObject:SetXP(xp)
    profileDataObject:SetScore(score)

    profileDataObject:SetSkill(skill)
    profileDataObject:SetSkillOffset(skillOffset)
    profileDataObject:SetCommSkill(commSkill)
    profileDataObject:SetCommSkillOffset(commSkillOffset)
    profileDataObject:SetAdagradSum(adagrad)
    profileDataObject:SetCommanderAdagradSum(commAdagrad)

    profileDataObject:SetTDSkill(skill)
    profileDataObject:SetTDSkillOffset(skillOffset)
    profileDataObject:SetTDCommSkill(commSkill)
    profileDataObject:SetTDCommSkillOffset(commSkillOffset)
    profileDataObject:SetTDAdagradSum(adagrad)
    profileDataObject:SetTDCommanderAdagradSum(td_commAdagrad)

    profileDataObject:SetLat(lat)
    profileDataObject:SetLong(long)

    --note: tdSysEnabled is set from geo-coord http call, and determines if TD is usable in any format.
    --System breaks without valid GeoIP data!
    Thunderdome():SetHiveProfileFetched( true, false, nil, tdSysEnabled )

    local badgeCustomizer = GetBadgeCustomizer()
    if badgeCustomizer then
        badgeCustomizer:UpdateOwnedBadges()
    end

end

RequestGeoCoords = function()
    Shared.SendHTTPRequest( GetGeoCoordsURL() , "GET", ParseGeoCoordsResponse)
end


function GUILocalPlayerProfileData:Initialize(params, errorDepth)       --???? Move all this OUT to callback triggered on SteamStatsChanged event?
    errorDepth = (errorDepth or 1) + 1
    
    GUIObject.Initialize(self, params, errorDepth)
    
    profileDataObject = self
    
    UpdatePlayerNicknameFromOptions() -- ensure the nickname has been initialized.

    local hiveProfile = {}
    if not Client.GetLocalHiveProfileData(hiveProfile) then
        
        Client.SetLocalThunderdomeMode(true)
        Thunderdome():StartingHiveProfileFetch()
        RequestGeoCoords()

    else
    --Reload from cached memory
        
        self:SetSkill( hiveProfile[1] )
        self:SetCommSkill( hiveProfile[2] )
        self:SetSkillOffset( hiveProfile[3] )
        self:SetCommSkillOffset( hiveProfile[4] )
        self:SetAdagradSum(hiveProfile[5] or NoAdagradSum)
        
        self:SetTDSkill( hiveProfile[6] )
        self:SetTDCommSkill( hiveProfile[7] )
        self:SetTDSkillOffset( hiveProfile[8] )
        self:SetTDCommSkillOffset( hiveProfile[9] )
        self:SetTDAdagradSum(hiveProfile[10] or NoAdagradSum)

        self:SetLevel( hiveProfile[11] )
        self:SetXP( hiveProfile[12] )
        self:SetScore( hiveProfile[13] )

        local badges = StringSplit(hiveProfile[14], ",")
        if #badges == 1 and badges[1] == "" then
            badges = {} -- StringSplit will cause an empty string to be an element if the cached badges is == ""
        end

        Badges_FetchBadges(_, badges)   --TODO Replace with Item lookups

        Thunderdome():SetPlayerName( self:GetPlayerName() )
        Thunderdome():SetHiveProfileFetched( true, false, nil, hiveProfile[17] )

    end

    self:HookEvent(self, "OnPlayerNameChanged",
    function()
        Thunderdome():SetPlayerName( self:GetPlayerName() )
    end)
end

function GUILocalPlayerProfileData:GetIsRookie()
    
    return self:GetLevel() <= kRookieLevel
    
end

function GUILocalPlayerProfileData:GetSkillTierAndName()
    
    local adagradSum = self:GetAdagradSum()
    if adagradSum == NoAdagradSum then
        adagradSum = nil
    end
    
    local skillTier, skillTierName = GetPlayerSkillTier(self:GetSkill(), self:GetIsRookie(), adagradSum)
    return skillTier, skillTierName
    
end

function GUILocalPlayerProfileData:GetSkillTier()
    
    local skillTier, skillTierName = self:GetSkillTierAndName()
    return skillTier
    
end

function GUILocalPlayerProfileData:GetSkillTierName()
    
    local skillTier, skillTierName = self:GetSkillTierAndName()
    return skillTierName
    
end

-- DEBUG
Event.Hook("Console_debug_spoof_hive_level", function(level)
    
    level = tonumber(level)
    if level and math.floor(level) ~= level then
        level = nil
    end
    
    if not level then
        Log("Usage: spoof_hive_level levelNumber")
        Log("    levelNumber must be an integer.  If negative, disables the spoof.")
        return
    end
    
    Log("Setting spoofed level to %s", level)
    Client.SetOptionInteger(kSpoofHiveLevelOptionPath, level)
    
end)

