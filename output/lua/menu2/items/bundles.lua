-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/items/bundles.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Functions related to item bundles.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/menu2/popup/GUIMenuPopupIconMessage.lua")

local bundleDefs = {}
local function DefineBundle(params)
    
    RequireType("string", params.title, "params.title", 2)
    RequireType("string", params.message, "params.title", 2)
    RequireType("string", params.icon, "params.icon", 2)
    RequireType("string", params.unpackLabel, "params.unpackLabel", 2)
    RequireType("number", params.bundleItemId, "params.bundleItemId", 2)
    RequireType("number", params.unpackBundleItemId, "params.unpackBundleItemId", 2)
    
    table.insert(bundleDefs, params)
    
end

DefineBundle
{
    title = Locale.ResolveString("TUNDRA_BUNDLE_TITLE"),
    message = Locale.ResolveString("TUNDRA_BUNDLE_MSG"),
    icon = PrecacheAsset("ui/items/tundra/logo_tundra.dds"),
    unpackLabel = Locale.ResolveString("OPEN_TUNDRA_BUNDLE"),
    bundleItemId = kTundraBundleItemId,
    unpackBundleItemId = kUnpackTundraBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("NOCTURNE_BUNDLE_TITLE"),
    message = Locale.ResolveString("NOCTURNE_BUNDLE_MSG"),
    icon = PrecacheAsset("ui/items/nocturne/logo_nocturne.dds"),
    unpackLabel = Locale.ResolveString("OPEN_NOCTURNE_BUNDLE"),
    bundleItemId = kNocturneAlienPackItemId,
    unpackBundleItemId = kUnpackNocturneBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("FORGE_BUNDLE_TITLE"),
    message = Locale.ResolveString("FORGE_BUNDLE_MSG"),
    icon = PrecacheAsset("ui/items/forge/logo_forge.dds"),
    unpackLabel = Locale.ResolveString("OPEN_FORGE_BUNDLE"),
    bundleItemId = kForgeMarinePackItemId,
    unpackBundleItemId = kUnpackForgeBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("SHADOW_BUNDLE_TITLE"),
    message = Locale.ResolveString("SHADOW_BUNDLE_MSG"),
    icon = PrecacheAsset("ui/items/shadow/logo_shadow.dds"),
    unpackLabel = Locale.ResolveString("OPEN_SHADOW_BUNDLE"),
    bundleItemId = kShadowBundleItemId,
    unpackBundleItemId = kUnpackShadowBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("BMAC_SUPPORT_PACK"),
    message = Locale.ResolveString("BMAC_SUPPORT_PACK_MSG"),
    icon = PrecacheAsset("ui/items/bmac/logo_bmac_support.dds"),
    unpackLabel = Locale.ResolveString("OPEN_BMAC_BUNDLE"),
    bundleItemId = kBigMacBundleItemId,
    unpackBundleItemId = kUnpackBigMacBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("BMAC_SUPPORT_PACK_PLUS"),
    message = Locale.ResolveString("BMAC_SUPPORT_PACK_PLUS_MSG"),
    icon = PrecacheAsset("ui/items/bmac/logo_bmac_support_plus.dds"),
    unpackLabel = Locale.ResolveString("OPEN_BMAC_BUNDLE"),
    bundleItemId = kBigMacBundle2ItemId,
    unpackBundleItemId = kUnpackBigMacBundle2ItemId,
}

DefineBundle
{
    title = Locale.ResolveString("BMAC_SUPPORT_PACK_ELITE"),
    message = Locale.ResolveString("BMAC_SUPPORT_PACK_ELITE_MSG"),
    icon = PrecacheAsset("ui/items/bmac/logo_bmac_support_elite.dds"),
    unpackLabel = Locale.ResolveString("OPEN_BMAC_BUNDLE"),
    bundleItemId = kBigMacBundle3ItemId,
    unpackBundleItemId = kUnpackBigMacBundle3ItemId,
}

DefineBundle
{
    title = Locale.ResolveString("CATALYST_BUNDLE_TITLE"),
    message = Locale.ResolveString("CATALYST_BUNDLE_MSG"),
    icon = PrecacheAsset("ui/items/catalyst/logo_catalyst_bundle.dds"),
    unpackLabel = Locale.ResolveString("OPEN_CATALYST_BUNDLE"),
    bundleItemId = kCatalystBundleId,
    unpackBundleItemId = kUnpackCatalystBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("KODIAK_BUNDLE_TITLE"),
    message = Locale.ResolveString("KODIAK_BUNDLE_MESSAGE"),
    icon = PrecacheAsset("ui/items/kodiak/bundle_large.dds"),
    unpackLabel = Locale.ResolveString("OPEN_KODIAK_BUNDLE"),
    bundleItemId = kKodiakBundleItemId,
    unpackBundleItemId = kUnpackKodiakBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("REAPER_BUNDLE_TITLE"),
    message = Locale.ResolveString("REAPER_BUNDLE_MSG"),
    icon = PrecacheAsset("ui/items/reaper/logo_reaper_bundle.dds"),
    unpackLabel = Locale.ResolveString("OPEN_REAPER_BUNDLE"),
    bundleItemId = kReaperBundleItemId,
    unpackBundleItemId = kUnpackReaperBundleItemId,
}

DefineBundle
{
    title = Locale.ResolveString("ABYSS_BUNDLE_TITLE"),
    message = Locale.ResolveString("ABYSS_BUNDLE_MSG"),
    icon = PrecacheAsset("ui/items/abyss/bundle_large.dds"),
    unpackLabel = Locale.ResolveString("OPEN_ABYSS_BUNDLE"),
    bundleItemId = kAbyssBundleItemId,
    unpackBundleItemId = kUnpackAbyssBundleItemId,
}


local function CreateUnpackWindow(params)
    
    local popup = CreateGUIObject("popup", GUIMenuPopupIconMessage, nil,
    {
        title = params.title,
        message = params.message,
        icon = params.icon,
        buttonConfig =
        {
            {
                name = "openBundle",
                params =
                {
                    label = params.unpackLabel,
                },
                callback = function(popup)
                    popup:Close()
                    Client.ExchangeItem(params.bundleItemId, params.unpackBundleItemId)
                end,
            },
            
            GUIPopupDialog.CancelButton,
        },
    })
    return popup

end

local alreadyAsked = {} -- bundle item id's that have already been asked about this session.
local function DoPopupsForUnopenedBundlesActual(callback, bundleQueue)
    
    while #bundleQueue > 0 do
        local bundleDef = bundleQueue[#bundleQueue]
        bundleQueue[#bundleQueue] = nil
    
        if GetOwnsItem(bundleDef.bundleItemId) and not alreadyAsked[bundleDef.bundleItemId] then
            alreadyAsked[bundleDef.bundleItemId] = true
            local popup = CreateUnpackWindow(bundleDef)
            popup:HookEvent(popup, "OnClosed", function()
                
                DoPopupsForUnopenedBundlesActual(callback, bundleQueue)
                
            end)
            
            return false -- stop here.  Will resume when popup is closed.
            
        end
    end
    
    -- If any popups had opened up, we would have returned from this function before now.
    -- We must be done, so fire the callback now.
    if type(callback) == "function" then
        callback()
    end
    
    return true

end

-- Checks to see if there are any unopened bundles, and if so, prompts the user to open them one
-- at a time.  When all popups have been dismissed by the user (or if no popups were displayed at
-- all), the finishedCallback function is called (optional).
-- Returns true if done, false if a popup was created.
function DoPopupsForUnopenedBundles(finishedCallback)
    
    local bundleQueue = {}
    for i=1, #bundleDefs do
        bundleQueue[i] = bundleDefs[i]
    end
    
    return (DoPopupsForUnopenedBundlesActual(finishedCallback, bundleQueue))
    
end

-- DEBUG
Event.Hook("Console_check_bundles", function()

    DoPopupsForUnopenedBundles(function()
    
        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = "YAAAAY!",
            message = "Done with popups",
            buttonConfig =
            {
                GUIPopupDialog.OkayButton,
            },
        })
        
    end)

end)
