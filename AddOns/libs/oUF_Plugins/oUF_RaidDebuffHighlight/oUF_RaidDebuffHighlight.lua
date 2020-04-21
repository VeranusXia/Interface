local _, ns = ...
local oUF = oUF or ns.oUF
if not oUF then return end
 
local function Update(object, event, unit)
	if unit ~= object.unit then return; end
	local wasFiltered = object.RaidDebuffHighlightFilter;
	local findIt = false;
	

	for i = 1, 40 do
		local _, _, icon, _, _, _, expires, _, _, _, spellID, _, _, _, _, _, value = UnitBuff('player', i)
		if icon and wasFiltered[spellID].enable then
			object.DBHGlow:Show()
			object.DBHGlow:SetBackdropBorderColor(color.r, color.g, color.b)
			findIt = true;
			break;
		end
	end
	
	if (not findIt) then
		if object.DBHGlow then
			object.DBHGlow:Hide()
		end
	end
end
 
local function Enable(object)
	-- if we're not highlighting this unit return
	if not object.DebuffHighlightBackdrop and not object.DebuffHighlight and not object.DBHGlow then
		return
	end
	-- if we're filtering highlights and we're not of the dispelling type, return
	if object.DebuffHighlightFilter and not CanDispel[playerClass] then
		return
	end
 
	object:RegisterEvent("UNIT_AURA", Update)

	return true
end

local function Disable(object)
	object:UnregisterEvent("UNIT_AURA", Update)

	if object.DBHGlow then
		object.DBHGlow:Hide()
	end

	if object.DebuffHighlight then
		local color = origColors[object]
		if color then
			object.DebuffHighlight:SetVertexColor(color.r, color.g, color.b, color.a)
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_TALENT_UPDATE")
f:RegisterEvent("CHARACTER_POINTS_CHANGED")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:SetScript("OnEvent", CheckSpec)

oUF:AddElement('RaidDebuffHighlight', Update, Enable, Disable)