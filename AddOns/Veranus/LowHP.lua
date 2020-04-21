
--[低血量报警] 
function RunicPercent_OnLoad() 
end 
frame = CreateFrame("Frame","Frame", WorldFrame) 
frame:SetPoint("CENTER") 
frame:SetWidth(40)--此处改大小 
frame:SetHeight(40) 
frame:Hide() 
frame:SetScale(1) -- this does not effect the text size. 
FrameText = frame:CreateFontString(nil,"ARTWORK"); 
FrameText:SetFontObject(GameFontNormal); 
FrameText:SetFont(STANDARD_TEXT_FONT, 30,"outline") 
FrameText:SetTextColor(0.8,0,0,1) -- change this to change color 
FrameText:SetPoint("CENTER",UIParent,"CENTER",0,0) 
frame:SetScript("OnEvent", function(self, event, arg1,arg2, ...) 
if event == "UNIT_HEALTH" then 
FrameText:SetText(format("低血量警报".."%d",UnitHealth("player")/UnitHealthMax("player")*100).."%") 
end 
local hp = UnitHealth("player") / UnitHealthMax("player") 
if hp > 0.30 or hp <= 1 then--此处改血量提醒百分比 
frame:Hide() 
else 
frame:Show() 
end 
end) 
frame:RegisterEvent("UNIT_HEALTH") 
frame:RegisterEvent("PLAYER_ENTERING_WORLD") 
RunicPercent_OnLoad()

   