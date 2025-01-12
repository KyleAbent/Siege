-- ======= Copyright (c) 2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/widgets/Thunderdome/GMTDLoadingGraphic.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--  This is the "loading" graphic that shows up when searching for a Thunderdome lobby.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUI/GUIObject.lua")

class "GMTDLoadingGraphic" (GUIObject)

GMTDLoadingGraphic.kFlipbookTexture = PrecacheAsset("ui/thunderdome/search_loading.dds")
GMTDLoadingGraphic.kFlipbookShader  = PrecacheAsset("shaders/GUI/menu/flipbook.surface_shader")

GMTDLoadingGraphic.kFlipbookTexture_FrameSize = Vector(256, 256, 0)

GMTDLoadingGraphic.kFramesPerSecond  = 17
GMTDLoadingGraphic.kHorizontalFrames = 8
GMTDLoadingGraphic.kVerticalFrames   = 8
GMTDLoadingGraphic.kTotalFrames      = 35

function GMTDLoadingGraphic:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self:SetTexture(self.kFlipbookTexture)

    self:SetShader(self.kFlipbookShader)
    self:SetFloatParameter("framesPerSecond",  self.kFramesPerSecond )
    self:SetFloatParameter("horizontalFrames", self.kHorizontalFrames)
    self:SetFloatParameter("verticalFrames",   self.kVerticalFrames  )
    self:SetFloatParameter("numFrames",        self.kTotalFrames     )

    self:SetColor(1,1,1)
    self:SetSize(400, 400)

end
