-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/GUI/GUIWebPageView.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    A GUIObject used to display a web page.
--    (Would have called it GUIWebView, except that name was already taken.)
--
--  Parameters (* = required)
--      url
--      textureName
--      renderSize
--      doubleClickToOpen
--      wheelEnabled        Whether or not the user is able to scroll the page with the mouse wheel.
--                          Enabled by default.
--      clickMode           A string choice of any of the following modes of operation:
--                              Full        The user can click on things in the web view, but since
--                                          it's kinda jank, they can double-click anywhere on the
--                                          view to open it up in the steam browser.
--                              NoOpen      Same as full, but the user must embrace the jank, as the
--                                          double-click-to-open functionality is disabled.
--                              OnlyOpen    The web page cannot be interacted with inside the web
--                                          view.  Instead, a single click on the page will open it
--                                          in the steam web browser.  This is the default value.
--                              None        There is no interactivity enabled for the mouse cursor
--                                          (does not affect mouse wheel setting).
--      openURL             An alternate URL to open in the steam browser, if applicable.
--
--  Properties
--      URL                 The page URL to load.
--      URLLoaded           Whether or not the URL has finished loading.  Always false if URL is not
--                          set.
--      TextureName         Sets the name of the texture to render the webpage into.  Use
--                          GUIWebPageView.AutoTexture as the value to have the object pick a
--                          texture name automatically.
--      RenderSize          Sets the size (resolution) of the web renderer.  Typically you'll want
--                          this to match the absolute size of the object holding it, or perhaps
--                          some fixed predetermined size (eg a prerendered video).  To
--                          automatically set size of web view based on object absolute size, use
--                          GUIWebPageView.AutoSize as the value.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")

---@class GUIWebPageView : GUIObject
local baseClass = GUIObject
class "GUIWebPageView" (baseClass)

local usedWebTextureNames = {}
local function GetUniqueTextureNameForWebView()
    local idx = 0
    local name
    while not name or usedWebTextureNames[name] do
        idx = idx + 1
        name = string.format("*webview_texture_%d", idx)
    end
    usedWebTextureNames[name] = true
    return name
end

local kDefaultSize = Vector(512, 512, 0)
local kMinRenderSize = Vector(32, 32, 0)
local kMaxRenderSize = Vector(2048, 2048, 0)

-- Amount of time that a non-rendering (eg invisible or off-screen) object will keep the web page
-- loaded.
local kInactivityDelay = 10

GUIWebPageView.AutoTexture = -1
GUIWebPageView.AutoSize = -1

GUIWebPageView:AddClassProperty("URL", "")
GUIWebPageView:AddClassProperty("URLLoaded", false)
GUIWebPageView:AddClassProperty("TextureName", GUIWebPageView.AutoTexture)
GUIWebPageView:AddClassProperty("RenderSize", GUIWebPageView.AutoSize)

-- Non-animated size of the object, so we can choose an appropriately sized web-view.
GUIWebPageView:AddClassProperty("_StaticSize", Vector(1, 1, 0))

-- Final size that will be used for the web view (result of automatic, or the manually set size)
GUIWebPageView:AddClassProperty("_FinalRenderSize", Vector(1, 1, 0))

-- Final name that will be used for the texture name (result of automatic, or the manually set name)
GUIWebPageView:AddClassProperty("_FinalTextureName", "")

-- Whether or not the "OnAbsoluteScaleChanged" callbacks should be enabled for this object.
GUIWebPageView:AddClassProperty("_AbsoluteScaleCallbacksEnabled", false)

-- Whether or not this object was rendered last frame.
GUIWebPageView:AddClassProperty("_BeingRendered", false)

-- Whether or not the web view should be rendering, based on whether or not the GUIObject is
-- visible, and if not, if enough time has elapsed to stop web view rendering.
GUIWebPageView:AddClassProperty("_WebViewShouldBeRendering", false)

local function UpdateFinalTextureName(self)
    
    local name = self:GetTextureName()
    if name == GUIWebPageView.AutoTexture then
        self:Set_FinalTextureName(GetUniqueTextureNameForWebView())
    else
        self:Set_FinalTextureName(name)
    end
    
end

local function UpdateStaticObjectSize(self)
    
    local size = self:GetRenderSize()
    if size ~= GUIWebPageView.AutoSize then
        return -- early out if this value is not needed.
    end
    
    local staticAbsSize = GetStaticAbsoluteSize(self)
    self:Set_StaticSize(staticAbsSize)

end

local function UpdateFinalRenderSize(self)
    
    local size = self:GetRenderSize()
    
    -- If size is set to automatic, keep track of changes to the object's absolute size.
    local shouldBeEnabled = size == GUIWebPageView.AutoSize
    self:Set_AbsoluteScaleCallbacksEnabled(shouldBeEnabled)
    
    -- Use either the automatically-derived texture size, or the manually-set texture size.
    if size == GUIWebPageView.AutoSize then
        self:Set_FinalRenderSize(self:Get_StaticSize())
    else
        assert(GetTypeName(size) == "Vector")
        self:Set_FinalRenderSize(size)
    end
    
end

local function CheckForLoadedURL(self)
    
    assert(self.webView) -- this callback should only ever be active when the webView exists.
    
    if self.webView:GetUrlLoaded() then
        self:RemoveTimedCallback(self.loadedURLCheckCallback)
        self.loadedURLCheckCallback = nil
        self:SetURLLoaded(true)
        
        -- Workaround for an issue where sometimes the webpage would be scrolled down to the bottom.
        -- Not sure why this happens, but attempting to work around it here by just feeding the
        -- browser a ton of scroll-up events at once.  Do this after a slight delay.
        if self.wheelEnabled then
            self:AddTimedCallback(
                function(self)
                    if self.webView then
                        self.webView:OnMouseMove(64, 64) -- so it will react to wheel event.
                        self.webView:OnMouseWheel(9999, 0)
                    end
                end, 1)
        end
    end
    
end

local function UpdateWebViewObject(self)

    local shouldBeActive = true
    local needsNewObject = false
    
    local url = self:GetURL()
    local textureName = self:Get_FinalTextureName()
    local renderSize = self:Get_FinalRenderSize()
    local renderingDesired = self:Get_WebViewShouldBeRendering()
    
    if url == "" or textureName == "" or renderSize.x < 0 or renderSize.y < 0 or renderingDesired == false then
        shouldBeActive = false
    end
    
    -- Constrain texture size to reasonable values.
    local textureWidthActual = Clamp(renderSize.x, kMinRenderSize.x, kMaxRenderSize.x)
    local textureHeightActual = Clamp(renderSize.y, kMinRenderSize.y, kMaxRenderSize.y)
    
    -- If the size is different from the current web view's size (if any) then we'll need to re-make
    -- the web view.
    if self.prevTextureWidth ~= textureWidthActual or
       self.prevTextureHeight ~= textureHeightActual then
       
       needsNewObject = true
    end
    
    local destroyOld = not shouldBeActive or needsNewObject
    
    -- Clean up existing web view.
    if destroyOld and self.webView then
        Client.DestroyWebView(self.webView)
        self.webView = nil
        self.webViewTargetTextureName = nil
        self.webViewLoadedURL = nil
        if self.loadedURLCheckCallback then
            self:RemoveTimedCallback(self.loadedURLCheckCallback)
            self.loadedURLCheckCallback = nil
        end
    end
    
    -- Create new web view if needed
    if self.webView == nil and needsNewObject and shouldBeActive then
        self.webView = Client.CreateWebView(textureWidthActual, textureHeightActual)
    end
    
    -- Update existing webm, if necessary.
    if self.webView and self.webViewTargetTextureName ~= textureName then
        assert(textureName ~= "") -- shouldn't have a webView if this is the case.
        self.webViewTargetTextureName = textureName
        self.webView:SetTargetTexture(textureName)
    end
    
    -- Update URL, if necessary.
    if self.webView and self.webViewLoadedURL ~= url then
        assert(url ~= "") -- shouldn't have a webView if this is the case.
        self.webViewLoadedURL = url
        self.webView:LoadUrl(url)
        assert(self.loadedURLCheckCallback == nil)
        self.loadedURLCheckCallback = self:AddTimedCallback(CheckForLoadedURL, 0, true)
        self:SetURLLoaded(false)
    end
    
end

local function SetWebViewObjectNeedsUpdate(self)
    self:EnqueueDeferredUniqueCallback(UpdateWebViewObject)
end

local function OnURLChanged(self, url)
    
    -- In case the URL is changed before the old one was loaded, destroy the old callback that was
    -- checking for it being loaded.
    if self.loadedURLCheckCallback then
        self:RemoveTimedCallback(self.loadedURLCheckCallback)
        self.loadedURLCheckCallback = nil
    end
    
    -- Assume the URL will be immediately unloaded (since it is a deferred call, it will take until
    -- the end of the frame before the changes become visible to the rest of the system).
    self:SetURLLoaded(false)
    
    SetWebViewObjectNeedsUpdate(self)

end

local function UpdateTextureAndColor(self)
    
    local urlLoaded = self:GetURLLoaded()
    local finalTextureName = self:Get_FinalTextureName()
    
    if urlLoaded then
        self:SetTexture(finalTextureName)
        self:SetColor(1, 1, 1, 1)
    else
        self:SetTexture("")
        self:SetColor(0, 0, 0, 1)
    end
    
end

local function UpdateAbsScaleCallback(self)
    
    local shouldBeEnabled = self:Get_AbsoluteScaleCallbacksEnabled()
    
    if shouldBeEnabled then
        EnableOnAbsoluteScaleChangedEvent(self)
        UpdateStaticObjectSize(self)
    else
        DisableOnAbsoluteScaleChangedEvent(self)
    end
    
end

local function InactivityDelayCallback(self)
    
    self.inactivityDelayCallback = nil -- not a repeating callback, it destroys itself.
    
    -- We went X seconds without being rendered, so let's free up that web view.
    self:Set_WebViewShouldBeRendering(false)
    
end

local function UpdateWebViewShouldBeRendering(self)
    
    -- Cleanup delay callback, if it is active.  We won't be using this old callback anymore,
    -- regardless of whether or not we need the delay.
    if self.inactivityDelayCallback then
        self:RemoveTimedCallback(self.inactivityDelayCallback)
        self.inactivityDelayCallback = nil
    end
    
    -- If the object is being rendered, ensure the web view is rendering immediately.
    if self:Get_BeingRendered() then
        self:Set_WebViewShouldBeRendering(true)
    else
    
        -- If the object is not being rendered, wait a bit to see if we need it again soon.  Don't
        -- want to thrash the system.
        self.inactivityDelayCallback = self:AddTimedCallback(InactivityDelayCallback, kInactivityDelay)
        
    end
    
end

function GUIWebPageView:OnWindowFocusedChanged(focus)
    
    if focus and self.webView then
        self.webView:RefreshTexture()
    end

end

GUIWebPageView.kValidClickModes =
{
    "Full", Full=1,
    "NoOpen", NoOpen=2,
    "OnlyOpen", OnlyOpen=3,
    "None", None=4,
}
GUIWebPageView.kDefaultClickMode = "OnlyOpen"

function GUIWebPageView:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    RequireType({"string", "nil"}, params.url, "params.url", errorDepth)
    RequireType({"string", "number", "nil"}, params.textureName, "params.textureName", errorDepth)
    RequireType({"Vector", "number", "nil"}, params.renderSize, "params.renderSize", errorDepth)
    RequireType({"boolean", "nil"}, params.wheelEnabled, "params.wheelEnabled", errorDepth)
    RequireType({"string", "nil"}, params.clickMode, "params.clickMode", errorDepth)
    RequireType({"string", "nil"}, params.openURL, "params.openURL", errorDepth)
    
    PushParamChange(params, "size", params.size or kDefaultSize)
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "size")
    
    self.wheelEnabled = params.wheelEnabled ~= false -- nil defaults to true
    local clickMode = params.clickMode or self.kDefaultClickMode
    if not self.kValidClickModes[clickMode] then
        clickMode = self.kDefaultClickMode
    end
    self.clickMode = clickMode
    
    -- Automatically pick a texture name, if necessary.
    self:HookEvent(self, "OnTextureNameChanged", UpdateFinalTextureName)
    UpdateFinalTextureName(self)
    
    -- Calculate what the object's static absolute size will be.
    self:HookEvent(self, "OnAbsoluteScaleChanged", UpdateStaticObjectSize)
    self:HookEvent(self, "OnSizeChanged", UpdateStaticObjectSize)
    UpdateStaticObjectSize(self)
    
    -- Automatically pick a texture size, if necessary, based on the absolute size of this object.
    self:HookEvent(self, "OnRenderSizeChanged", UpdateFinalRenderSize)
    self:HookEvent(self, "On_StaticSizeChanged", UpdateFinalRenderSize)
    UpdateFinalRenderSize(self)
    
    -- Destroy/create/update a webview as needed.
    self:HookEvent(self, "OnURLChanged", OnURLChanged)
    self:HookEvent(self, "On_FinalRenderSizeChanged", SetWebViewObjectNeedsUpdate)
    self:HookEvent(self, "On_FinalTextureNameChanged", SetWebViewObjectNeedsUpdate)
    self:HookEvent(self, "On_WebViewShouldBeRenderingChanged", SetWebViewObjectNeedsUpdate)
    
    -- Set the texture of this object to match the webView texture, but only if the URL is loaded!
    -- If the URL isn't loaded, clear the texture, and make the color black.
    self:HookEvent(self, "OnURLLoadedChanged", UpdateTextureAndColor)
    self:HookEvent(self, "On_FinalTextureNameChanged", UpdateTextureAndColor)
    UpdateTextureAndColor(self)
    
    -- Keep track of whether or not we've enabled the OnAbsoluteScaleChanged callback.
    self:HookEvent(self, "On_AbsoluteScaleCallbacksEnabledChanged", UpdateAbsScaleCallback)
    
    -- Allow some rudimentary interaction with the web view.
    self:ListenForCursorInteractions()
    if self.wheelEnabled then
        self:ListenForWheelInteractions()
    end
    
    -- Keep track of when the object is being rendered.  If it goes too long without being rendered,
    -- destroy the WebView to free up some resources.
    self:TrackRenderStatus(self)
    self:HookEvent(self, "OnRenderingStarted", function(self2) self2:Set_BeingRendered(true) end)
    self:HookEvent(self, "OnRenderingStopped", function(self2) self2:Set_BeingRendered(false) end)
    self:HookEvent(self, "On_BeingRenderedChanged", UpdateWebViewShouldBeRendering)
    UpdateWebViewShouldBeRendering(self)
    
    -- If the window focus is regained, force a redraw of the webpage, as it might not have drawn
    -- successfully before...
    self:HookEvent(GetGlobalEventDispatcher(), "OnWindowFocusedChanged", self.OnWindowFocusedChanged)
    
    if params.url then
        self:SetURL(params.url)
    end
    
    if params.textureName then
        self:SetTextureName(params.textureName)
    end
    
    if params.renderSize then
        self:SetRenderSize(params.renderSize)
    end
    
    if params.doubleClickToOpen ~= nil then
        self:SetDoubleClickToOpen(params.doubleClickToOpen)
    end
    
    if params.openURL then
        self.openURL = params.openURL
    end
    
end

function GUIWebPageView:Uninitialize()
    
    if self.loadedURLCheckCallback then
        self:RemoveTimedCallback(self.loadedURLCheckCallback)
        self.loadedURLCheckCallback = nil
    end
    
    if self.webView then
        self.webView:LoadUrl("")
        Client.DestroyWebView(self.webView)
        self.webView = nil
    end
    
    GUIObject.Uninitialize(self)
end

local function WebPageViewMouseMoveCommon(self)
    
    if not self.webView then
        return
    end
    
    -- Always deliver OnMouseMove events, since if we don't, other stuff like scrolling with the
    -- mouse wheel stops working.
    
    -- Transform the mouse coordinates into "web-view-space".
    local ssMousePos = GetGlobalEventDispatcher():GetMousePosition()
    
    -- First, convert screen-space mouse pos to local-space mouse pos.
    local lsMousePos = self:ScreenSpaceToLocalSpace(ssMousePos)
    
    -- Now, normalize the position according to the local size.
    local nrmMousePos = Vector(1, 1, 0)
    local localSize = self:GetSize()
    if localSize.x ~= 0 then nrmMousePos.x = lsMousePos.x / localSize.x end
    if localSize.y ~= 0 then nrmMousePos.y = lsMousePos.y / localSize.y end
    
    -- Now, convert this to web-view-space.
    local wvsMousePos = nrmMousePos * self:Get_FinalRenderSize()
    
    -- Pass it along to the web view.
    self.webView:OnMouseMove(wvsMousePos.x, wvsMousePos.y)

end

function GUIWebPageView:OnMouseHover()
    GUIObject.OnMouseHover(self)
    WebPageViewMouseMoveCommon(self)
end

function GUIWebPageView:OnMouseDrag()
    GUIObject.OnMouseDrag(self)
    WebPageViewMouseMoveCommon(self)
end

function GUIWebPageView:OnMouseClick(double)
    GUIObject.OnMouseClick(self, double)
    
    -- Do not allow interaction if the URL isn't loaded.
    if not self:GetURLLoaded() or not self.webView then
        return
    end
    
    if double or self.clickMode == "OnlyOpen" then
        Client.ShowWebpage(self.openURL or self:GetURL())
        return
    end
    
    if self.clickMode == "Full" or self.clickMode == "NoOpen" then
        self.webView:OnMouseDown(0)
    end
    
end

function GUIWebPageView:GetCanBeDoubleClicked()
    return self.clickMode == "Full"
end

function GUIWebPageView:OnMouseUp()
    GUIObject.OnMouseClick(self)
    
    -- Do not allow interaction if the URL isn't loaded.
    if not self:GetURLLoaded() or not self.webView then
        return
    end
    
    if self.clickMode == "Full" or self.clickMode == "NoOpen" then
        self.webView:OnMouseUp(0)
    end
    
end

function GUIWebPageView:OnMouseWheel(up)
    GUIObject.OnMouseWheel(self, up)
    
    -- Do not allow interaction if the URL isn't loaded.
    if not self:GetURLLoaded() or not self.webView then
        return
    end
    
    local dist = 30
    if not up then
        dist = dist * -1
    end
    
    self.webView:OnMouseWheel(dist, 0)
    
end
