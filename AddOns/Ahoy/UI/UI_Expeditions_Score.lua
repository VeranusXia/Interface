----------------------------------------------------------
-------------- Expeditions Window - Score ----------------
----------------------------------------------------------

----------------------------------------------------------
--	Globals												--
----------------------------------------------------------
Ahoy.selectedTab = -1;
Ahoy.selectedCreature = "";
Ahoy.TabFrames = {};

----------------------------------------------------------
--	UI													--
----------------------------------------------------------

-- expeditions window
Ahoy.ExpeditionWindowFrame = CreateFrame("Frame",nil,Ahoy.MainFrame)
Ahoy.ExpeditionWindowFrame:SetWidth(450) -- Set these to whatever height/width is needed 
Ahoy.ExpeditionWindowFrame:SetHeight(170) -- for your Texture
Ahoy.ExpeditionWindowFrame:SetPoint("CENTER",0,0)
Ahoy.ExpeditionWindowFrame_Texture = Ahoy.ExpeditionWindowFrame:CreateTexture() 
Ahoy.ExpeditionWindowFrame_Texture:SetAllPoints() 
Ahoy.ExpeditionWindowFrame_Texture:SetColorTexture(0,0,0,0)
Ahoy.ExpeditionWindowFrame.background = Ahoy.ExpeditionWindowFrame_Texture
Ahoy.ExpeditionWindowFrame:Hide()

-- score scroll parent frame 
Ahoy.ScoreScrollParentFrame = CreateFrame("Frame", "MyFrame", Ahoy.ExpeditionWindowFrame) 
Ahoy.ScoreScrollParentFrame:SetSize(220, 150) 
Ahoy.ScoreScrollParentFrame:SetPoint("LEFT",0,0) 
Ahoy.ScoreScrollParentFrame_Texture = Ahoy.ScoreScrollParentFrame:CreateTexture() 
Ahoy.ScoreScrollParentFrame_Texture:SetAllPoints() 
Ahoy.ScoreScrollParentFrame_Texture:SetTexture(0,0,0,1) 
Ahoy.ScoreScrollParentFrame.background = Ahoy.ScoreScrollParentFrame_Texture 
 
-- score scroll frame 
Ahoy.ScoreScrollFrame = CreateFrame("ScrollFrame", nil, Ahoy.ScoreScrollParentFrame) 
Ahoy.ScoreScrollFrame:SetPoint("TOPLEFT", 10, -4) 
Ahoy.ScoreScrollFrame:SetPoint("BOTTOMRIGHT", -10, 3) 
Ahoy.ScoreScrollParentFrame.ScoreScrollFrame = Ahoy.ScoreScrollFrame 
 
-- score scrollbar 
Ahoy.ScoreScrollBar = CreateFrame("Slider", nil, Ahoy.ScoreScrollFrame, "UIPanelScrollBarTemplate") 
Ahoy.ScoreScrollBar:SetPoint("TOPLEFT", Ahoy.ScoreScrollParentFrame, "TOPRIGHT", -10, -16) 
Ahoy.ScoreScrollBar:SetPoint("BOTTOMLEFT", Ahoy.ScoreScrollParentFrame, "BOTTOMRIGHT", 4, 16) 
Ahoy.ScoreScrollBar:SetMinMaxValues(-1, 200) 
Ahoy.ScoreScrollBar:SetValueStep(1) 
Ahoy.ScoreScrollBar.scrollStep = 1
Ahoy.ScoreScrollBar:SetValue(0) 
Ahoy.ScoreScrollBar:SetWidth(16) 
Ahoy.ScoreScrollBar:SetScript("OnValueChanged", 
function (self, value) 
self:GetParent():SetVerticalScroll(value) 
end) 
local scrollbg = Ahoy.ScoreScrollBar:CreateTexture(nil, "BACKGROUND") 
scrollbg:SetAllPoints(Ahoy.ScoreScrollBar) 
scrollbg:SetTexture(0, 0, 0, 0.4) 
Ahoy.ScoreScrollParentFrame.ScoreScrollBar = Ahoy.ScoreScrollBar 
 
-- score content frame 
Ahoy.ScoreContentFrame = CreateFrame("Frame", nil, Ahoy.ScoreScrollFrame) 
Ahoy.ScoreContentFrame:SetSize(220, 400) 
Ahoy.ScoreScrollFrame.ScoreContentFrame = Ahoy.ScoreContentFrame 
Ahoy.ScoreScrollFrame:SetScrollChild(Ahoy.ScoreContentFrame)

----------------------------------------------------------
--	Functions											--
----------------------------------------------------------

function Ahoy_ClickedTab(tabNumber)
	local lootString = ""
	child1, child2, child3, child4 = Ahoy.TabFrames[tabNumber]:GetChildren();
	local selectedCreatureClass = child1.text:GetText();
	Ahoy_UpdateLootList(selectedCreatureClass);
end

function ClearTabSelect()
	for n = 0, Ahoy.TabsCount, 1 do
		Ahoy.TabFrames[n].texture:SetTexCoord(0.04, 0.39, 0.345, 0.381);
	end
	Ahoy.selectedTab = -1
end

function Ahoy_CreateTabFrames()
	for t = 0, Ahoy.TabsCount, 1 do
		local AhoyTabFrame = CreateFrame("Frame", "AhoyTab "..t, Ahoy.ScoreContentFrame)
		AhoyTabFrame:SetSize(189, 20)
		AhoyTabFrame:SetPoint("CENTER", -14, 200-t*19.5 - 10)
		local AhoyTabFrame_texture = AhoyTabFrame:CreateTexture() 
		AhoyTabFrame_texture:SetAllPoints() 
		AhoyTabFrame_texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
		AhoyTabFrame_texture:SetTexCoord(0.04, 0.39, 0.345, 0.381)
		AhoyTabFrame.texture = AhoyTabFrame_texture
		Ahoy.ScoreScrollFrame.ScoreContentFrame = AhoyTabFrame

		--- Handle Controls ---
		AhoyTabFrame:EnableMouseWheel(true)
		AhoyTabFrame:EnableMouse()
		AhoyTabFrame:SetScript("OnMouseWheel", 
		function(self, delta)
			Ahoy.ScoreScrollBar:SetValue(Ahoy.ScoreScrollFrame:GetVerticalScroll()-(delta*20)) 
		end)
		AhoyTabFrame:SetScript('OnEnter', 
		function()
			if t ~= Ahoy.selectedTab then
				AhoyTabFrame.texture:SetTexCoord(0.04, 0.39, 0.347 + 0.037, 0.383 + 0.037) 
			end
		end)
		AhoyTabFrame:SetScript('OnLeave', 
		function()
			if t ~= Ahoy.selectedTab then
				AhoyTabFrame.texture:SetTexCoord(0.04, 0.39, 0.345, 0.381)
			end
		end)
		AhoyTabFrame:SetScript("OnMouseDown", 
		function() 
			ClearTabSelect();
			Ahoy.selectedTab = t;
			Ahoy_ClickedTab(Ahoy.selectedTab);
			AhoyTabFrame.texture:SetTexCoord(0.04, 0.39, 0.349 + 0.074, 0.387 + 0.074)
		end)
		
		--- SUBFRAMES ---
		local MobNameSubFrame = CreateFrame("Frame", "MobName"..t, AhoyTabFrame)
		MobNameSubFrame:SetSize(100, 20)
		MobNameSubFrame:SetPoint("CENTER", 5, 0)
		MobNameSubFrame.text = MobNameSubFrame.text or MobNameSubFrame:CreateFontString(nil,"ARTWORK","QuestFontNormalSmall")
		MobNameSubFrame.text:SetAllPoints(true)
		MobNameSubFrame.text:SetJustifyH("LEFT")
		MobNameSubFrame.text:SetJustifyV("CENTER")
		MobNameSubFrame.text:SetText(format(" "))

		local MobScoreSubFrame = CreateFrame("Frame", "MobScore"..t, AhoyTabFrame)
		MobScoreSubFrame:SetSize(50, 20)
		MobScoreSubFrame:SetPoint("RIGHT", 6, 1)
		MobScoreSubFrame.text = MobScoreSubFrame.text or MobScoreSubFrame:CreateFontString(nil,"ARTWORK","GameFontNormal")
		MobScoreSubFrame.text:SetAllPoints(true)
		MobScoreSubFrame.text:SetJustifyH("RIGHT")
		MobScoreSubFrame.text:SetJustifyV("CENTER")
		MobScoreSubFrame.text:SetTextColor(1,1,0,1)
		MobScoreSubFrame.text:SetText(format(" "))

		local SilverSkullSubFrame = CreateFrame("Frame", "SilverSkull"..t, AhoyTabFrame)
		SilverSkullSubFrame:SetSize(15, 15)
		SilverSkullSubFrame:SetPoint("LEFT", 30, 0)
		local SilverSkullSubFrame_Texture = SilverSkullSubFrame:CreateTexture() 
		SilverSkullSubFrame_Texture:SetAllPoints() 
		SilverSkullSubFrame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
		SilverSkullSubFrame_Texture:SetTexCoord(0.755 - 0.067, 0.755, 0.640625 - 0.067, 0.640625)

		local SilverSkillScoreSubFrame = CreateFrame("Frame", "SilverSkillScore"..t, AhoyTabFrame)
		SilverSkillScoreSubFrame:SetSize(25, 20)
		SilverSkillScoreSubFrame:SetPoint("LEFT", 15, 0)
		SilverSkillScoreSubFrame.text = SilverSkillScoreSubFrame.text or SilverSkillScoreSubFrame:CreateFontString(nil,"ARTWORK","QuestFontNormalSmall")
		SilverSkillScoreSubFrame.text:SetAllPoints(true)
		SilverSkillScoreSubFrame.text:SetJustifyH("LEFT")
		SilverSkillScoreSubFrame.text:SetJustifyV("CENTER")
		SilverSkillScoreSubFrame.text:SetTextColor(0,0,0,.7)
		SilverSkillScoreSubFrame.text:SetText(format("5x"))

		Ahoy.TabFrames[t] = AhoyTabFrame
	end
end

function Ahoy_AdjustTabs(number)
	for n = 0, Ahoy.TabsCount, 1 do
		if n > number then
			Ahoy.TabFrames[n]:Hide();
		else
			Ahoy.TabFrames[n]:Show();
		end
	end
end