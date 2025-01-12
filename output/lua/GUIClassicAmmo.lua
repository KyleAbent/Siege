-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/GUIClassicAmmo.lua
--
-- Ported by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Port of the NS2+ Classic Ammo script. Adds a medium sized ammo counter on the Marine HUD.
-- Originally Created By: Juanjo Alfaro "Mendasp"
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

class 'GUIClassicAmmo' (GUIAnimatedScript)

local kFontName = Fonts.kAgencyFB_Large_Bold
local kAmmoColor = Color(163/255, 210/255, 220/255, 0.8)

function GUIClassicAmmo:Initialize()

	GUIAnimatedScript.Initialize(self)

	if GetAdvancedOption("hudbars_m") == 2 then
		self.kAmmoPos = Vector(-260, -115, 0)
	else
		self.kAmmoPos = Vector(-210, -115, 0)
	end

	self.enabled = GetAdvancedOption("classicammo")
	
	self.ammoText = self:CreateAnimatedTextItem()
	self.ammoText:SetAnchor(GUIItem.Right, GUIItem.Bottom)    
	self.ammoText:SetTextAlignmentX(GUIItem.Align_Min)    
	self.ammoText:SetTextAlignmentY(GUIItem.Align_Center)    
	self.ammoText:SetColor(kAmmoColor)
	self.ammoText:SetPosition(self.kAmmoPos)
	self.ammoText:SetFontName(kFontName)
	self.ammoText:SetScale(GetScaledVector())
	self.ammoText:SetIsVisible(false)
	GUIMakeFontScale(self.ammoText)
	
end

function GUIClassicAmmo:Reset()

	GUIAnimatedScript.Reset(self)
	
	self.ammoText:SetFontName(kFontName)
	self.ammoText:SetScale(GetScaledVector())
	GUIMakeFontScale(self.ammoText)
	
end

function GUIClassicAmmo:OnResolutionChanged(_, _, _, _)

	self:Uninitialize()
	self:Initialize()

end

local pulsateTime = 0
local function Pulsate(_, item)

	item:SetColor(Color(1, 0, 0, 0.35), pulsateTime, "CLASSIC_AMMO_PULSATE", AnimateLinear,
		function(_, this)
			this:SetColor(Color(1, 0, 0, 1), pulsateTime, "CLASSIC_AMMO_PULSATE", AnimateLinear, Pulsate)
		end)

end

function GUIClassicAmmo:Update(deltaTime)

	GUIAnimatedScript.Update(self, deltaTime)

	if not self.enabled then
		return
	end

	local player = Client.GetLocalPlayer()
	local activeWeapon = player:GetActiveWeapon()
	self.ammoText:SetIsVisible(activeWeapon and true or false)
	
	if activeWeapon then
		local ammo = GetWeaponAmmoString(activeWeapon)
		local reserveAmmo = GetWeaponReserveAmmoString(activeWeapon)
		local fraction = GetWeaponAmmoFraction(activeWeapon)
		local reserveFraction = GetWeaponReserveAmmoFraction(activeWeapon)
		local isReloading = activeWeapon:isa("ClipWeapon") and activeWeapon:GetIsReloading()
		local reloadIndicator = isReloading and " (R)" or ""
		
		self.ammoText:SetIsVisible(fraction ~= -1)
		if reserveFraction ~= -1 then
			self.ammoText:SetText(string.format("%s / %s", ammo, reserveAmmo .. reloadIndicator))
		else
			self.ammoText:SetText(string.format("%s", ammo))
		end
		
		if fraction < 0.25 then
			pulsateTime = 0.25
		elseif fraction <= 0.4 then
			pulsateTime = 0.5
		end

		if reserveFraction ~= -1 then
			if not self.ammoText:GetIsAnimating() and fraction <= 0.4 and fraction > 0 then
				self.ammoText:FadeIn(0.05, "CLASSIC_AMMO_PULSATE", AnimateLinear, Pulsate)
			elseif fraction > 0.4 then
				self.ammoText:SetColor(kAmmoColor)
			elseif fraction == 0 then
				self.ammoText:SetColor(kRed)
			end
		else
			self.ammoText:SetColor(kAmmoColor)
		end
	end
	
end

function GUIClassicAmmo:Uninitialize()

	GUIAnimatedScript.Uninitialize(self)

	self.ammoText:Destroy()
	self.ammoText = nil
	
end
