Script.Load("lua/Utility.lua")
Script.Load("lua/GUIUtility.lua")

-- Only load the neccesairy fonts, saves load time
Fonts = {}
Fonts.kAgencyFB_Huge = PrecacheAsset("fonts/AgencyFB_huge.fnt")
Fonts.kAgencyFB_Large = PrecacheAsset("fonts/AgencyFB_large.fnt")
Fonts.kAgencyFB_Medium = PrecacheAsset("fonts/AgencyFB_medium.fnt")
Fonts.kAgencyFB_Small = PrecacheAsset("fonts/AgencyFB_small.fnt")
Fonts.kAgencyFB_Tiny = PrecacheAsset("fonts/AgencyFB_tiny.fnt")

FontFamilies = {"kAgencyFB"}
FontFamilies["kAgencyFB"] = {}
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Huge] = 96
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Large] = 41
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Medium] = 33
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Small] = 27
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Tiny] = 20

local kFontAgencyFB_Large = Fonts.kAgencyFB_Large
local kIntroScreen = "screens/IntroScreen.jpg"
local kSpinner = PrecacheAsset("ui/loading/spinner.dds")

local spinner
local statusText, statusTextShadow
local dotsText, dotsTextShadow

function OnUpdateRender()
  
    local spinnerSpeed  = 2
    local dotsSpeed     = 0.5
    local maxDots       = 4
    
    local time = Shared.GetTime()

    if spinner ~= nil then
        local angle = -time * spinnerSpeed
        spinner:SetRotation( Vector(0, 0, angle) )
    end
    
    if statusText ~= nil then
        
        local text = Locale.ResolveString("LOADING_2")

        if Client.GetIsRunningModUpdates() then
            text = Locale.ResolveString("UPDATING_MODS")
        end

        statusText:SetText(text)
        statusTextShadow:SetText(text)
        
        -- Add animated dots to the text.
        local numDots = math.floor(time / dotsSpeed) % (maxDots + 1)
        dotsText:SetText(string.rep(".", numDots))
        dotsTextShadow:SetText(string.rep(".", numDots))
        
    end


end

function OnLoadComplete(main)
    -- Make the mouse visible so that the user can alt-tab out in Windowed mode.
    Client.SetMouseVisible(true)
    Client.SetMouseClipped(false)

    local backgroundWidth = 1920
    local backgroundHeight = 1080
    local backgroundScale = math.min(Client.GetScreenWidth() / backgroundWidth, Client.GetScreenHeight() / backgroundHeight)

    local loadscreen = GUI.CreateItem()
    loadscreen:SetTexture( kIntroScreen )
    loadscreen:SetSize(Vector(backgroundWidth, backgroundHeight, 0))
    loadscreen:SetAnchor(Vector(0.5, 0.5, 0))
    loadscreen:SetHotSpot(Vector(0.5, 0.5, 0))
    loadscreen:SetOptionFlag(GUIItem.CorrectScaling)
    loadscreen:SetScale(Vector(backgroundScale, backgroundScale, 0))
    loadscreen:SetPosition( Vector(0,0,0) )

    local scaledSize = loadscreen:GetScaledSize()
    
    local spinnerSize   = GUIScale(192)
    local spinnerOffsetY = GUIScaleHeight(50 + ((Client.GetScreenHeight() - scaledSize.y) / 2))
    local spinnerOffsetX = GUIScaleWidth(50 + ((Client.GetScreenWidth() - scaledSize.x) / 2))

    spinner = GUI.CreateItem()
    spinner:SetTexture( kSpinner )
    spinner:SetSize( Vector( spinnerSize, spinnerSize, 0 ) )
    spinner:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffsetX, Client.GetScreenHeight() - spinnerSize - spinnerOffsetY, 0 ) )
    spinner:SetBlendTechnique( GUIItem.Add )
    spinner:SetLayer(3)
   
    local statusOffset = GUIScale(5)
    local shadowOffset = 2

    statusTextShadow = GUI.CreateItem()
    statusTextShadow:SetOptionFlag(GUIItem.ManageRender)
    statusTextShadow:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffsetX - statusOffset+shadowOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffsetY+shadowOffset, 0 ) )
    statusTextShadow:SetTextAlignmentX(GUIItem.Align_Max)
    statusTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
    statusTextShadow:SetFontName(kFontAgencyFB_Large)
    statusTextShadow:SetColor(Color(0,0,0,1))
    statusTextShadow:SetScale(GetScaledVector())
    GUIMakeFontScale(statusTextShadow)
    statusTextShadow:SetLayer(3)
        
    statusText = GUI.CreateItem()
    statusText:SetOptionFlag(GUIItem.ManageRender)
    statusText:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffsetX - statusOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffsetY, 0 ) )
    statusText:SetTextAlignmentX(GUIItem.Align_Max)
    statusText:SetTextAlignmentY(GUIItem.Align_Center)
    statusText:SetFontName(kFontAgencyFB_Large)
    statusText:SetScale(GetScaledVector())
    GUIMakeFontScale(statusText)
    statusText:SetLayer(3) 
    
    
    dotsTextShadow = GUI.CreateItem()
    dotsTextShadow:SetOptionFlag(GUIItem.ManageRender)
    dotsTextShadow:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffsetX - statusOffset+shadowOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffsetY+shadowOffset, 0 ) )
    dotsTextShadow:SetTextAlignmentX(GUIItem.Align_Min)
    dotsTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
    dotsTextShadow:SetFontName(kFontAgencyFB_Large)
    dotsTextShadow:SetColor(Color(0,0,0,1))
    dotsTextShadow:SetScale(GetScaledVector())
    GUIMakeFontScale(dotsTextShadow)
    dotsTextShadow:SetLayer(3)
    
    dotsText = GUI.CreateItem()
    dotsText:SetOptionFlag(GUIItem.ManageRender)
    dotsText:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffsetX - statusOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffsetY, 0 ) )
    dotsText:SetTextAlignmentX(GUIItem.Align_Min)
    dotsText:SetTextAlignmentY(GUIItem.Align_Center)
    dotsText:SetFontName(kFontAgencyFB_Large)
    dotsText:SetScale(GetScaledVector())
    GUIMakeFontScale(dotsText)
    dotsText:SetLayer(3)
end

Event.Hook("LoadComplete", OnLoadComplete)
Event.Hook("UpdateRender", OnUpdateRender)
