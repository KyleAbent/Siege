--=============================================================================
--
-- lua/MenuManager.lua
--
-- Created by Max McGuire (max@unknownworlds.com)
-- Copyright 2012, Unknown Worlds Entertainment
--
--=============================================================================

MenuManager = { }
MenuManager.menuCinematic = nil
MenuManager.storedCinematic = nil
MenuManager.menuCinematicRenderMask = 0x01

--
-- Sets the cinematic that's displayed behind the main menu.
--
function MenuManager.SetMenuCinematic(fileName, storeMenu)

    if MenuManager.menuCinematic ~= nil then
    
        Client.DestroyCinematic(MenuManager.menuCinematic)
        MenuManager.menuCinematic = nil
        storedCinematic = nil
        
    end
    
    if fileName ~= nil then
    
        MenuManager.menuCinematic = Client.CreateCinematic(RenderScene.Zone_Default, false, true)
        MenuManager.menuCinematic:SetRepeatStyle( Cinematic.Repeat_Loop )
        MenuManager.menuCinematic:SetCinematic( fileName, MenuManager.menuCinematicRenderMask )
        if storeMenu and storeMenu == true then
            MenuManager.storedCinematic = fileName
        end
    end
    
end

function MenuManager.RestoreMenuCinematic()

    if MenuManager.menuCinematic ~= nil then
    
        Client.DestroyCinematic(MenuManager.menuCinematic)
        MenuManager.menuCinematic = nil
        
    end
    
    if MenuManager.storedCinematic ~= nil then
        
        MenuManager.menuCinematic = Client.CreateCinematic(RenderScene.Zone_Default, false, true)
        MenuManager.menuCinematic:SetRepeatStyle( Cinematic.Repeat_Loop )
        MenuManager.menuCinematic:SetCinematic( MenuManager.storedCinematic, MenuManager.menuCinematicRenderMask )

    end
    
end


function MenuManager.GetCinematicCamera()

    -- Try to get the camera from the cinematic.
    if MenuManager.menuCinematic ~= nil then
        return MenuManager.menuCinematic:GetCamera()
    else
        return false
    end
    
end

function MenuManager.PlaySound(fileName)
    StartSoundEffect(fileName)
end