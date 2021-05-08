ConsoleExec("portal TW")
ConsoleExec("profanityFilter 0")


 
--进出入战斗提示  test 20171029
local MyAddon = CreateFrame("Frame") 
local imsg = CreateFrame("Frame", "ComatAlert") 
imsg:SetSize(400, 60) 
imsg:SetPoint("TOP", 0, -100) 
imsg:Hide() 
imsg.bg = imsg:CreateTexture(nil, 'BACKGROUND') 
imsg.bg:SetTexture([[Interface\LevelUp\LevelUpTex]]) 
imsg.bg:SetPoint('BOTTOM') 
imsg.bg:SetSize(250, 20) 
imsg.bg:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125) 
imsg.bg:SetVertexColor(1, 1, 1, 0.6) 

imsg.lineTop = imsg:CreateTexture(nil, 'BACKGROUND') 
imsg.lineTop:SetDrawLayer('BACKGROUND', 2) 
imsg.lineTop:SetTexture([[Interface\LevelUp\LevelUpTex]]) 
imsg.lineTop:SetPoint("TOP") 
imsg.lineTop:SetSize(400, 5) 
imsg.lineTop:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313) 

imsg.lineBottom = imsg:CreateTexture(nil, 'BACKGROUND') 
imsg.lineBottom:SetDrawLayer('BACKGROUND', 2) 
imsg.lineBottom:SetTexture([[Interface\LevelUp\LevelUpTex]]) 
imsg.lineBottom:SetPoint("BOTTOM") 
imsg.lineBottom:SetSize(400, 5) 
imsg.lineBottom:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313) 

imsg.text = imsg:CreateFontString(nil, 'ARTWORK', 'GameFont_Gigantic') 
imsg.text:SetPoint("BOTTOM", 0, 10) 
imsg.text:SetTextColor(0.8, 0.82, 0) 
imsg.text:SetJustifyH("CENTER") 

MyAddon:RegisterEvent("PLAYER_REGEN_ENABLED") 
MyAddon:RegisterEvent("PLAYER_REGEN_DISABLED") 
MyAddon:SetScript("OnEvent", function(self, event) 
  if event == "PLAYER_REGEN_DISABLED" then 
    imsg.text:SetText(">> 进入战斗 <<") 
    ComatAlert:Show() 
  else 
    imsg.text:SetText(">> 脱离战斗 <<") 
    ComatAlert:Show() 
  end   
end) 

local timer = 0 

imsg:SetScript("OnShow", function(self) 
  timer = 0 
  self:SetScript("OnUpdate", function(self, elasped) 
    timer = timer + elasped 
    if (timer<0.5) then self:SetAlpha(timer*2) end 
    if (timer>1 and timer<1.5) then self:SetAlpha(1-(timer-1)*2) end 
    if (timer>=1.5 ) then self:Hide() end 
  end) 
end)






--战斗事件通报
local function X(self, event)

	local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	
	local inInstance, instanceType = IsInInstance()
	
	if eventType=="SPELL_INTERRUPT" then
		local spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool = select(12, CombatLogGetCurrentEventInfo())
		if sourceName==UnitName("player") then
			if inInstance==1 then
				SendChatMessage("打断-->"..GetSpellLink(extraSpellId),"say")
			else
				print("打断-->"..GetSpellLink(extraSpellId))
			end
		end
	elseif eventType=="SPELL_DISPEL" then
		local spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool, auraType = select(12, CombatLogGetCurrentEventInfo())
		if sourceName==UnitName("player") then
			if inInstance==1 then
			 SendChatMessage("驱散-->"..GetSpellLink(extraSpellId),"say")
			else
				print("驱散-->"..GetSpellLink(extraSpellId))
			end
		end
	elseif eventType=="SPELL_STOLEN" then
		local spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool, auraType = select(12, CombatLogGetCurrentEventInfo())
		if sourceName==UnitName("player") then
			if inInstance==1 then
				SendChatMessage("偷取-->"..GetSpellLink(extraSpellId),"say")
			else
				print("偷取-->"..GetSpellLink(extraSpellId))
			end
		end
	elseif eventType=="SPELL_MISSED" then
		local spellId, spellName, spellSchool, missType, isOffHand, amountMissed = select(12, CombatLogGetCurrentEventInfo())
		if missType=="REFLECT" and destName==UnitName("player") then 
			if inInstance==1 then
				SendChatMessage("反射-->"..GetSpellLink(spellId),"say")
			else	
				print("反射-->"..GetSpellLink(spellId))
			end
		end
	end
end

local frame2 = CreateFrame("FRAME")
frame2:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame2:SetScript("OnEvent", X)
