-- 2019.5.21 当在宠物对战时，界面里的系统图标位置移动，以具中。
local frame = CreateFrame("Frame")
frame:RegisterEvent("PET_BATTLE_OPENING_START")
frame:SetScript("OnEvent", function(self, event)
if (not event=="PET_BATTLE_OPENING_START") then return end
if IsAddOnLoaded("Blizzard_PetBattleUI") then
    if event=="PET_BATTLE_OPENING_START" then
      CharacterMicroButton:ClearAllPoints();
      CharacterMicroButton:SetPoint("BOTTOMLEFT", -5.5, 27.5); 
	end
end
end)