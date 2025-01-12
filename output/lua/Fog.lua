-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. ========
--
-- lua\Fog.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

local kFogOptionsKey = "graphics/fog2"
local kDefaultFogValue = "high"
local kValidFogOptions =
{
    "high", "low", "off"
}
for i=1, #kValidFogOptions do
    kValidFogOptions[kValidFogOptions[i]] = i
end
assert(kValidFogOptions[kDefaultFogValue] ~= nil) -- default value must be valid


local currentFogOption = kDefaultFogValue -- default in the .render_setup file.
function UpdateFogVisibility()
    
    local fogOption = GetFogOptionValue()
    
    -- If player is overhead, fog should not be visible.
    if PlayerUI_IsOverhead and PlayerUI_IsOverhead() then
        fogOption = "off"
    end
    
    if currentFogOption ~= fogOption then
        Client.SetRenderSetting("fog", fogOption)
        currentFogOption = fogOption
    end

end


function GetFogOptionValue()
    local value = Client.GetOptionString(kFogOptionsKey, kDefaultFogValue)
    local valueIdx = kValidFogOptions[value]
    local finalValue = kValidFogOptions[valueIdx] or kDefaultFogValue
    return finalValue
end

function GetFogOptionPath()
    return kFogOptionsKey
end

function GetFogOptionType()
    return "string"
end

function GetFogDefaultValue()
    return kDefaultFogValue
end

Event.Hook("Console_r_fog", function(state)
    
    if state == nil or not kValidFogOptions[state] then
        Log("usage: r_fog <high|low|off>")
        return
    end
    
    Client.SetOptionString(kFogOptionsKey, state)
    UpdateFogVisibility()
    
    local optionsMenu = GetOptionsMenu()
    if optionsMenu then
        local fogOption = optionsMenu:GetOptionWidget("fog")
        if fogOption then
            fogOption:SetValue(state)
        end
    end

end)
