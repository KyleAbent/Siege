

kThunderdome_FieldTimeKeys = enum({
    "TD_tpf_01",
    "TD_tpf_02",
    "TD_tpf_03",
    "TD_tpf_04",
    "TD_tpf_05",
    "TD_tpf_06",
    "TD_tpf_09",
    "TD_tpf_12",
    "TD_tpf_16",
    "TD_tpf_20",
    "TD_tpf_26",
    "TD_tpf_35",
    "TD_tpf_45",
    "TD_tpf_55",
    "TD_tpf_75",
    "TD_tpf_95",
    "TD_tpf_115",
    "TD_tpf_150",
    "TD_tpf_200",
    "TD_tpf_300",
    "TD_tpf_500",
    "TD_tpf_700",
    "TD_tpf_1000",
    "TD_tpf_1500",
})

kThunderdome_CommTimeKeys = enum({ "TD_tpc_10", "TD_tpc_20", "TD_tpc_45", "TD_tpc_60", "TD_tpc_90", })

kThunderdome_FieldWinsKeys = enum({
    "TD_fv_03",
    "TD_fv_05",
    "TD_fv_07",
    "TD_fv_10",
    "TD_fv_13",
    "TD_fv_15",
    "TD_fv_17",
    "TD_fv_20",
    "TD_fv_23",
    "TD_fv_25",
    "TD_fv_27",
    "TD_fv_30",
    "TD_fv_33",
    "TD_fv_37",
    "TD_fv_40",
    "TD_fv_43",
    "TD_fv_45",
    "TD_fv_47",
    "TD_fv_50",
    "TD_fv_55",
    "TD_fv_60",
    "TD_fv_65",
    "TD_fv_70",
    "TD_fv_75",
    "TD_fv_80",
    "TD_fv_85",
    "TD_fv_90",
    "TD_fv_110",
    "TD_fv_200",
    "TD_fv_250",
    "TD_fv_300",
    "TD_fv_350",
    "TD_fv_400",
    "TD_fv_500",
})

kThunderdome_CommWinsKeys = enum({ "TD_cv_10", "TD_cv_15", "TD_cv_20", "TD_cv_25", "TD_cv_45", "TD_cv_60", "TD_cv_80", })


function GrantAchievement(client, achievementId)
    assert(client)
    assert(achievementId)
    if not Server.GrantAchievement(client, achievementId) then
        Log("ERROR: Failed to grant '%s' achivement for Client[%s]", achievementId, client:GetId())
        return false
    end
    return true
end

local kAchSep = "_"
function GetAchTargetVal(achId)
    assert(achId)
    local l = string.find( achId, kAchSep, 4, string.len(achId) )
    local v = string.sub( achId, l + 1, string.len(achId) )
    local achVal = tonumber(v)
    return achVal
end

function HandleFieldTimeUnlocks( client, newVal )
    if not client or (newVal <= 0 or not newVal) then
        return
    end

    local adjNewVal = newVal / 60 / 60 --format into hours

    for ach, idx in ipairs( kThunderdome_FieldTimeKeys ) do
        local achId = tostring(kThunderdome_FieldTimeKeys[kThunderdome_FieldTimeKeys[idx]])
        local achVal = GetAchTargetVal(achId)

        if adjNewVal < achVal then
            break   --end of possible unlocks for this call
        end

        if adjNewVal >= achVal then
            GrantAchievement( client, achId )
        end
    end
end

function HandleCommanderTimeUnlocks( client, newVal )
    if not client or (newVal <= 0 or not newVal) then
        return
    end

    local adjNewVal = newVal / 60 / 60  --format into hours

    for ach, idx in ipairs( kThunderdome_CommTimeKeys ) do
        local achId = tostring(kThunderdome_CommTimeKeys[kThunderdome_CommTimeKeys[idx]])
        local achVal = GetAchTargetVal(achId)

        if adjNewVal < achVal then
            break   --end of possible unlocks for this call
        end

        if adjNewVal >= achVal then
            GrantAchievement( client, achId )
        end
    end
end

function HandleFieldWinsUnlocks( client, newVal )
    if not client or (newVal <= 0 or not newVal) then
        return
    end

    for ach, idx in ipairs( kThunderdome_FieldWinsKeys ) do
        local achId = tostring(kThunderdome_FieldWinsKeys[kThunderdome_FieldWinsKeys[idx]])
        local achVal = GetAchTargetVal(achId)

        if newVal < achVal then
            break   --end of possible unlocks for this call
        end

        if newVal >= achVal then
            GrantAchievement( client, achId )
        end
    end
end

function HandleCommanderWinsUnlocks( client, newVal )
    if not client or (newVal <= 0 or not newVal) then
        return
    end

    for ach, idx in ipairs( kThunderdome_CommWinsKeys ) do
        local achId = tostring(kThunderdome_CommWinsKeys[kThunderdome_CommWinsKeys[idx]])
        local achVal = GetAchTargetVal(achId)

        if newVal < achVal then
            break   --end of possible unlocks for this call
        end

        if newVal >= achVal then
            GrantAchievement( client, achId )
        end
    end
end
