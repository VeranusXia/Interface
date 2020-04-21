local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF not loaded')

local _G = _G
local pairs = pairs
local strfind = string.find
local unpack = unpack
local DRData = LibStub("DRData-1.0")

local UpdateTarget = function(self)
	local _, instanceType = IsInInstance();
	local drTracker = self.DRTracker

	if instanceType == 'arena' then
		local ID = self.unit:match('arena(%d)') or self:GetID() or 0
		local unit = 'arena'..tostring(ID)..'target'
		local _, targetClass = UnitClass(unit)
		if drTracker.showEnemy then
			if targetClass and (not UnitCanAttack("player", unit))) then
				drTracker.Icon:SetTexture("Interface\\TARGETINGFRAME\\UI-CLASSES-CIRCLES.BLP")
				drTracker.Icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[targetClass]))
				drTracker.Name:SetText(UnitName(unit))
				drTracker:Show()
			else
				drTracker:Hide()
			end
		else
			if targetClass then
				drTracker.Icon:SetTexture("Interface\\TARGETINGFRAME\\UI-CLASSES-CIRCLES.BLP")
				drTracker.Icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[targetClass]))
				drTracker.Name:SetText(UnitName(unit))
				drTracker:Show()
			else
				drTracker:Hide()
			end
		end
	else
		self:SetScript('OnUpdate', nil)
	end
end

local Update = function(self, event, timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, auraType)
	local unit
	for i = 1, 3 do
		if UnitGUID('arena'..i) == destGUID then
			unit = 'arena'..i
		end
	end
	if not unit then
		return
	end
	-- Enemy had a debuff refreshed before it faded, so fade + gain it quickly
	if eventType == "SPELL_AURA_REFRESH" then
		if auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) then
			self:DRFaded(unit, spellID)
		end
	-- Buff or debuff faded from an enemy
	elseif eventType == "SPELL_AURA_REMOVED" then
		if auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) then
			self:DRFaded(unit, spellID)
		end
	end
end


local Enable = function(self)
	local drTracker = self.DRTracker
	if drTracker then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", Update)

		if not drTracker.Icon then
			drTracker.Icon = drTracker:CreateTexture(nil, "OVERLAY")
			drTracker.Icon:SetAllPoints(drTracker)
			drTracker.Icon:SetTexture("Interface\\TARGETINGFRAME\\UI-CLASSES-CIRCLES.BLP")
		end
		drTracker:Show()
		return true
	end
end
 
local Disable = function(self)
	local drTracker = self.DRTracker
	if drTracker then
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:UnregisterEvent("ARENA_OPPONENT_UPDATE", Update)
		self:SetScript('OnUpdate', nil)		
		drTracker:Hide()
	end
end
 
oUF:AddElement('DRTrack', Update, Enable, Disable)