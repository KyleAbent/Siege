-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/GUIMenuExitButton.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--    
--    The power symbol that appears in the upper-right corner of the screen of the main menu, to
--    quit the game.
--    
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIGlobalEventDispatcher.lua")
Script.Load("lua/menu2/widgets/GUIMenuPowerButton.lua")

---@class GUIMenuExitButton : GUIMenuPowerButton
class "GUIMenuExitButton" (GUIMenuPowerButton)

GUIMenuExitButton.kShadowScale = Vector(10, 5, 1)

function GUIMenuExitButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    GUIMenuPowerButton.Initialize(self, params, errorDepth)
    
    self:HookEvent(self, "OnPressed", self.OnPressed)
    
end

function GUIMenuExitButton:OnPressed()
    
    if Thunderdome():GetIsConnectedToLobby() then

        local leaveMessage = GetLeaveLobbyMessage()

        local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
        {
            title = Locale.ResolveString("THUNDERDOME_LEAVE_WARNING_TITLE"),
            message = leaveMessage,
            buttonConfig =
            {
                {
                    name = "ok",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("OK")),
                    },
                    callback = function(popup)  
                        popup:FireEvent("OnConfirmed", popup)
                        popup:Close()
                        Client.Exit()
                    end,
                },
                {
                    name = "cancel",
                    params =
                    {
                        label = string.upper(Locale.ResolveString("CANCEL")),
                    },
                    callback = function(popup)
                        popup:Close()
                    end,
                },
            },

        })

        return

    end

    local currentScreen = GetScreenManager():GetCurrentScreen()
    if not currentScreen then
        Client.Exit()
        return
    end
    
    -- Request the current screen to be hidden so it can protest if needed (eg "unsaved changes!")
    if currentScreen:RequestHide(Client.Exit) then
        Client.Exit()
    end
    
end
