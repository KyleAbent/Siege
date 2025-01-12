-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/GUIMenuDiscordButton.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Button that takes the user to the official NS2 discord channel.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/menu2/GUIMenuExitButton.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

---@class GUIMenuDiscordButton : GUIMenuExitButton
local baseClass = GUIMenuExitButton
baseClass = GetTooltipWrappedClass(baseClass)
class "GUIMenuDiscordButton" (baseClass)

local kDiscordAddress = "https://discord.gg/ns2"

GUIMenuDiscordButton.kTextureRegular = PrecacheAsset("ui/newMenu/discordButton.dds")
GUIMenuDiscordButton.kTextureHover   = PrecacheAsset("ui/newMenu/discordButtonOver.dds")

GUIMenuDiscordButton.kShadowScale = Vector(10, 5, 1)

function GUIMenuDiscordButton:OnPressed()
    Client.ShowWebpage(kDiscordAddress)
end

function GUIMenuDiscordButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    baseClass.Initialize(self, params, errorDepth)
    self:SetTooltip(Locale.ResolveString("DISCORD_BUTTON_TOOLTIP"))
end
