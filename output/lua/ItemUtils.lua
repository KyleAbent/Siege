-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/ItemUtils.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Functions related to items, and debugging item drops.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/UnorderedSet.lua")

local spoofedItems = UnorderedSet()

Event.Hook("Console_spoof_items", function(...)
    
    local itemIds = {...}
    local gotInvalid = false
    for i=1, #itemIds do
        itemIds[i] = tonumber(itemIds[i])
        if not itemIds[i] or math.floor(itemIds[i]) ~= itemIds[i] then
            gotInvalid = true
            break
        end
    end
    
    if gotInvalid or #itemIds == 0 then
        Log("usage: spoof_items itemId1 itemId2 ... itemIdN")
        return
    end
    
    -- Requires cheats or dev-mode to be used in-game.
    if kInGame and not Shared.GetCheatsEnabled() and not Shared.GetDevMode() then
        Log("command spoof_items requires cheats or dev-mode to be enabled on the server.")
        return
    end
    
    local addedItems = {}
    for i=1, #itemIds do
        if spoofedItems:Add(itemIds[i]) then
            table.insert(addedItems, itemIds[i])
        end
    end
    
    if #addedItems > 0 then
        Log("Added %d items to the spoofed set: %s", #addedItems, table.concat(addedItems, ", "))
    else
        Log("No items were added (they were all already present in the set)")
    end
    
    for i=1, #addedItems do
        InventoryNewItemHandler( addedItems[i], false )
    end
    
end)

function GetOwnsItem( item )
    
    -- Check for debug spoofed items first.
    if spoofedItems:Contains(item) then
        return true
    end
    
    --Minor thing to save calling into engine
    if item == -1 or item == 0 or item == nil then
        return true
    end

    if Client then
        if type(item) == "table" then
            for i = 1, #item do
                if Client.GetOwnsItem( item[i] ) then
                    return true
                end
            end
        else
            return Client.GetOwnsItem( item )
        end
    else
        return true
    end
    
end


local itemBundles = {}
function GetAllBundleItems()
    if itemBundles and #itemBundles > 0 then
        return itemBundles --these don't change often
    end

    local bundles = {}
    if not Client.GetAllItemBundles(bundles) then
        Log("Failed to fetch Item bundles data")
    end

    for b = 1, #bundles do
        local bundleItems = {}
        if not Client.GetItemBundleItems(bundles[b], bundleItems) then
            Log("Failed to fetch items in bundle")
            break
        end
        --Bundle ItemID  -> Items in bundle (by id)
        table.insert(itemBundles, { bundleId = bundles[b], items = bundleItems  })
    end
    return itemBundles --one-time on start-up
end

function GetIsItemBundleItem(itemId)
    assert(itemId)
    local bundles = GetAllBundleItems()
    for i = 1, #bundles do
        if table.icontains(bundles[i].items, itemId) then
            return true
        end
    end
    return false
end

function GetItemBundleId(itemId)
    assert(itemId)
    local bundles = GetAllBundleItems()
    for i = 1, #bundles do
        if table.icontains(bundles[i].items, itemId) then
            return bundles[i].bundleId
        end
    end
end

function GetAllBundleItemsNames(bundleId)
    assert(bundleId)
    local bundles = GetAllBundleItems()
    local itemNames = {}

    for b = 1, #bundles do

        if bundles[b].bundleId == bundleId then

            for i = 1, #bundles[b].items do

                local itemData = {}
                if not Client.GetItemData(bundles[b].items[i], itemData) then
                    Log("Failed to fetch item data")
                    break
                end

                if itemData and itemData[8] == bundleId then
                    table.insert(itemNames, itemData[2])
                end

            end

        end

    end

    return itemNames
end

function GetBundleItemsNamesList(bundleId)
    assert(bundleId)
    local names = GetAllBundleItemsNames(bundleId)
    assert(names and #names > 0)
    return table.concat(names, "\n")
end

function GetIsItemDlcOnly(itemId)
    assert(itemId)
    return table.icontains(kDlcOnlyPurchasableItems, itemId)
end

function GetFormattedDlcItemNames( dlcId )
    assert(dlcId)
    local itemNamesStr = ""
    if kItemDlcData[dlcId] and kItemDlcData[dlcId].items then
        for i = 1, #kItemDlcData[dlcId].items do
            local itemId = kItemDlcData[dlcId].items[i]
            assert(itemId)
            local itemData = {}
            if Client.GetItemDetails( itemId, itemData ) then
                if itemData then
                    itemNamesStr = itemNamesStr .. itemData[2] .. "    "
                    if i ~= #kItemDlcData[dlcId].items then
                        itemNamesStr = itemNamesStr .. "\n"
                    end
                end
            else
                error("Failed to fetch item data for ItemID: %s", itemId)
            end
        end
    end
    --?? trim trailing newline?
    return itemNamesStr
end

local kTDAchPrefix = "TD_"
function GetIsItemThunderdomeUnlock(itemId)
    
    if itemId and itemId > 0 then
        local itemData = {}
        if not Client.GetItemDetails(itemId, itemData) then
            Log("Failed to fetch item[%s] data", itemId)
            return false
        end
        
        local achName = itemData[10] and itemData[10] or ""
        if achName == "" then
            return false
        end
        
        local achPrefix = string.sub(achName, 1, 3)
        if achPrefix == kTDAchPrefix then
            return true
        end

    end

    return false
end

function GetFormattedDlcToolTipText( dlcId )
    assert(dlcId)
    local text = ""
    if kItemDlcData[dlcId] and kItemDlcData[dlcId].displayName then
        --[[
        text = kItemDlcData[dlcId].displayName .. "\n"
        local itemsList = GetFormattedDlcItemNames( dlcId )
        text = text .. itemsList .. "\n"
        --]]
        text = "DLC Contents:\n" .. GetFormattedDlcItemNames( dlcId )
        --TODO Add text for Deluxe Edition and add its extras (Wallpapers, Avatars, Soundtrack)
    end
    return text
end

function GetFormattedDlcName( dlcId )
    assert(dlcId)
    if kItemDlcData[dlcId] then
        return kItemDlcData[dlcId].displayName --.. " " .. "DLC"
    end
    return "Unknown DLC ID"
end

function GetItemDlcAppId( itemId )
    assert(itemId)
    --Function should only be used on DLC-Only items
    assert(table.icontains(kDlcOnlyPurchasableItems, itemId))

    local findData = function(forItemId)
        --kItemDlcData is an IterableDict, so pairs in this context is jit-safe
        for dlcId, data in pairs( kItemDlcData ) do
            for i = 1, #data.items do
                if data.items[i] == forItemId then
                    return dlcId
                end
            end
        end
        return false
    end
    
    return findData(itemId)
end

function GetIsDlcBmacBundle( dlcId )
    assert(dlcId)
    return table.icontains( kBMAC_DlcBundleList, dlcId )
end

function GetDlcStorePageUrl( dlcId )
    assert(dlcId)
    local url
    if GetIsDlcBmacBundle(dlcId) then
        if dlcId == kDlcBmacPackId then
            url = kBmacStorePageUrl
        elseif dlcId == kDlcBmacSupportPackId then
            url = kPlusBmacBundleStorePageUrl
        elseif dlcId == kDlcBmacElitePackId then
            url = kEliteBmacBundleStorePageUrl
        else
            url = kEliteBmacBundleStorePageUrl
        end
    else
        url = kDlcStorePageBaseUrl .. dlcId .. "/"
    end
    return url
end

function GetIsNewItemCatalystDlc(itemId)
    assert(itemId)
    return table.icontains( kItemDlcData[kDlcCatalystId].items, itemId )
end

function GetIsNewItemDeluxeDlc(itemId)
    assert(itemId)
    return table.icontains( kItemDlcData[kDeluxeEditionProductId].items, itemId )
end

--Note: Bundle Items are not part of the "normal" item list checked by Client.GetIsItemPurchasable()
function GetIsItemPurchasable( itemId )
    
    if itemId == nil or itemId == 0 or itemId == -1 then
        return true
    end

    if not Client.GetIsSteamOverlayEnabled() then
        return false
    end

    local isPurchasable = false

    if type(itemId) == "table" then
        for i = 1, #itemId do
            if itemId[i] ~= nil and Client.GetIsItemPurchasable(itemId[i]) then
                isPurchasable = true
            end
        end
    else
        isPurchasable = Client.GetIsItemPurchasable(itemId)
    end

    if not isPurchasable and table.icontains(kBmacItemIds, itemId) then
        local dlcId = GetItemDlcAppId(itemId)
        if dlcId then
            isPurchasable = Client.GetIsDlcPurchasable(dlcId)
        end
    end

    if not isPurchasable then
    --check item bundles
        local bundles = GetAllBundleItems()
        for i = 1, #bundles do
            if not isPurchasable and table.icontains(bundles[i].items, itemId) then
                isPurchasable = true
            end
        end
    end

    --Check DLCs last (Items that are only unlocked via DLC purchase, and not individual items or bundle)
    if not isPurchasable then
        if table.icontains( kDlcOnlyPurchasableItems, itemId ) then
            local dlcId = GetItemDlcAppId(itemId)
            if dlcId then
                isPurchasable = Client.GetIsDlcPurchasable(dlcId)
            end
        end
    end

    return isPurchasable
end


local kCurrencyCodeSymbols =
{
    ["AED"] = "د.إ",
    ["ARS"] = "$",
    ["AUD"] = "$",
    ["BRL"] = "R$",
    ["CAD"] = "$",
    ["CHF"] = "₣",
    ["CLP"] = "$",
    ["CNY"] = "¥",
    ["COP"] = "$",
    ["CRC"] = "₡",
    ["EUR"] = "€",
    ["GBP"] = "£",
    ["HKD"] = "$",
    ["ILS"] = "₪",
    ["IDR"] = "Rp",
    ["INR"] = "₹",
    ["JPY"] = "¥",
    ["KRW"] = "₩",
    ["KWD"] = "د.ك",
    ["KZT"] = "〒",
    ["MXN"] = "$",
    ["MYR"] = "RM",
    ["NOK"] = "kr",
    ["NZD"] = "$",
    ["PEN"] = "S/.",
    ["PHP"] = "₱",
    ["PLN"] = "zł",
    ["QAR"] = "ر.ق",
    ["RUB"] = "р.",
    ["SAR"] = "ر.س",
    ["SGD"] = "$",
    ["THB"] = "฿",
    ["TRY"] = "₤",
    ["TWD"] = "$",
    ["UAH"] = "₴",
    ["USD"] = "$",
    ["UYU"] = "$",
    ["VND"] = "₫",
    ["ZAR"] = "R",
}
local kActiveCurrencySymbol = nil
local kActiveCurrencyCodeOverride = nil
function GetUserCurrencySymbol()
    assert(Client)
    local curCode = Client.GetCurrencyCode()
    if curCode and string.len(curCode) > 0 and kCurrencyCodeSymbols[curCode] then
        if kActiveCurrencySymbol == nil then
            kActiveCurrencySymbol = kCurrencyCodeSymbols[curCode]
        end

        if kActiveCurrencyCodeOverride ~= nil then
            return kCurrencyCodeSymbols[kActiveCurrencyCodeOverride]
        end

        return kActiveCurrencySymbol
    else
        Log("Invalid currency code [%s] fetched!", curCode)
    end
end

local OverrideCurrencyCode = function(newCode)
    
end

local DumpCurrencyCodes = function()
    Log(ToString(kCurrencyCodeSymbols))
end
Event.Hook("Console_dumpcurrencycodes", DumpCurrencyCodes)

--TODO Handle prices for speicifc cur-codes (e.g. New Taiwan Dollar, reported in fēn. Must be charged in increments of 100 fēn (e.g. 1000, not 1050).)
--See https://partner.steamgames.com/doc/store/pricing/currencies for details
function GetFormattedPrice( price, currencyCode )
    assert(price)
    assert(currencyCode)
    assert(type(price) == "number" and price > 0)
    assert(type(currencyCode) == "string" and string.len(currencyCode) >= 2)

    --FIXME Need per-currency code formatting of price
    ----Lookup Table of functions that process data and return formatted string

    --USD style formatting
    local subAmt = string.sub(price, string.len(price) - 1, string.len(price))
    local bAmt = string.sub(price, 1, string.len(price) - 2)
    if string.len(bAmt) == 0 then
    --Handle sub dollar amounts
        bAmt = "0"
    end
    --Log("\t bAmt: %s, subAmt: %s", bAmt, subAmt)
    local priceStr = GetUserCurrencySymbol() .. bAmt .. "." .. subAmt
    --Log("\t Price: %s", priceStr)
    return priceStr
end

Event.Hook("LoadComplete", function()
    
    local old_Client_ExchangeItem = Client.ExchangeItem
    assert(old_Client_ExchangeItem)
    function Client.ExchangeItem(inItemId, outItemId)
    
        if spoofedItems:Contains(inItemId) then
            spoofedItems:Add(outItemId)
            spoofedItems:RemoveElement(inItemId)
            
            Log(string.format("Exchanged spoofed item %d for spoofed item %d", inItemId, outItemId))
            
            return
        end
        
        return (old_Client_ExchangeItem(inItemId, outItemId))
    
    end
    
end)


function InventoryNewItemNotifyPush( item )
    local new = json.decode( Client.GetOptionString("inventory_new","[]") ) or {}
    new[#new+1] = item
    Client.SetOptionString("inventory_new", json.encode( new ) )
    
    local menu = GetMainMenu()
    if menu and not menu:GetIsInGame() then
        menu:CheckForNewNotifications()
    end
end

function InventoryNewItemNotifyPop()
    local new = json.decode( Client.GetOptionString("inventory_new","[]") ) or {}
    local pop = new[1]
    for i=2,#new do new[i-1] = new[i] end
    new[#new] = nil
    Client.SetOptionString("inventory_new", json.encode( new ) )
    return pop
end

function InventoryNewItemHandler( item, isDupe )
    if Client.IsInventoryLoaded() and not isDupe then
        InventoryNewItemNotifyPush( item )
        CheckCollectableAchievement()
        GetCustomizeScreen():UpdateBuyButton(item, true)
    end
end
Event.Hook("InventoryNewItem", InventoryNewItemHandler )

local function OnInventoryUpdated()
    local menu = GetMainMenu()
    if menu and Client.IsInventoryLoaded() then
        GetCustomizeScene():RefreshOwnedItems()
    end
end
Event.Hook("InventoryUpdated", OnInventoryUpdated)
Event.Hook("Console_forceitemsupdate", function() Client.UpdateInventory() end)



function FindVariant( data, displayName )

    for var, data in pairs(data) do
        if data.displayName == displayName then
            return var
        end
    end

    return 1

end

function GetVariantName( data, var )
    if data[var] then
        return data[var].displayName
    end
    return ""
end

function GetVariantItemId( data, var )
    
    if data[var] then
        local itemId
        if data[var].itemId then
            itemId = data[var].itemId
        elseif data[var].itemIds then
            itemId = data[var].itemIds  --FIXME This is not ideal, as type must be checked
        else
            itemId = nil
        end

        return itemId
    end
    return -1
end

function GetVariantModel( data, var )
    if data[var] and data[var].modelFilePart then
        return data[var].modelFilePart .. ".model"
    else
        return data[var] .. ".model"
    end
    return nil
end

function GetVariantWorldMaterial( varData, variant, className, index )
    Log("GetVariantWorldMaterial( %s, %s, %s, %s )", varData, variant, className, index)
    if varData[variant] then
        if varData[variant].worldMaterials and className and varData[variant].worldMaterials[className] then
            if varData[variant].worldMaterials[className][index] then
                return varData[variant].worldMaterials[className][index + 1]    --All material indices are offset by 1 in Globals def
            end
            return varData[variant].worldMaterials[className]
        else
            return varData[variant].worldMaterial
        end
    end
    return nil
end

function GetVariantWorldMaterialIndex( varData, variant )
    if varData[variant] then
        return varData[variant].worldMaterialIndex
    end
    return -1
end


function GetHasVariant(data, var, client)
    assert(data)
    assert(var)
    
    if not data[var] then
        return false
    end

    if data[var].itemId then
        return GetOwnsItem( data[var].itemId )
    elseif data[var].itemIds then
        return GetOwnsItem( data[var].itemIds )
    else
        return GetHasDLC(data[var].productId, client)
    end

    return false
end