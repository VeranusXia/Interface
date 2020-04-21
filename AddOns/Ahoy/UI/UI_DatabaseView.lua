----------------------------------------------------------
--	Database View										--
----------------------------------------------------------

----------------------------------------------------------
--	Globals												--
----------------------------------------------------------
Ahoy.databaseViewInitialized = false;

----------------------------------------------------------
--	UI													--
----------------------------------------------------------

-- Database view main frame --
Ahoy.DatabaseViewFrame = CreateFrame("Frame",nil,UIParent)
Ahoy.DatabaseViewFrame:SetWidth(400) -- Set these to whatever height/width is needed 
Ahoy.DatabaseViewFrame:SetHeight(600) -- for your Texture
Ahoy.DatabaseViewFrame:SetPoint("CENTER",0,0)
local DatabaseViewFrame_Texture = Ahoy.DatabaseViewFrame:CreateTexture() 
DatabaseViewFrame_Texture:SetAllPoints() 
DatabaseViewFrame_Texture:SetTexture("Interface/store/services-popup-bg", "REPEAT", "REPEAT")
DatabaseViewFrame_Texture:SetTexCoord(0, 0.75, 0, 1)
--DatabaseViewFrame_Texture:SetColorTexture(0,0,0,0.8) 
Ahoy.DatabaseViewFrame.background = DatabaseViewFrame_Texture
Ahoy.DatabaseViewFrame.text = Ahoy.DatabaseViewFrame.text or Ahoy.DatabaseViewFrame:CreateFontString(nil,"ARTWORK","GameFontNormal")
Ahoy.DatabaseViewFrame.text:SetAllPoints(true)
Ahoy.DatabaseViewFrame.text:SetJustifyH("CENTER")
Ahoy.DatabaseViewFrame.text:SetJustifyV("CENTER")
Ahoy.DatabaseViewFrame:Hide()
Ahoy.DatabaseViewFrame:SetMovable(true)
Ahoy.DatabaseViewFrame:EnableMouse(true)


-- Database View TitleBar --
Ahoy.DatabaseViewTitleBar = CreateFrame("Frame",nil,Ahoy.DatabaseViewFrame)
Ahoy.DatabaseViewTitleBar:SetWidth(400) -- Set these to whatever height/width is needed 
Ahoy.DatabaseViewTitleBar:SetHeight(24) -- for your Texture
Ahoy.DatabaseViewTitleBar:SetPoint("TOP",0,0)
local DatabaseViewTitleBar_Texture = Ahoy.DatabaseViewTitleBar:CreateTexture() 
DatabaseViewTitleBar_Texture:SetTexture("Interface/transmogrify/transmoghorizontal", "REPEAT", "REPEAT")
DatabaseViewTitleBar_Texture:SetTexCoord(0, 1, 0.1, 0.28)
DatabaseViewTitleBar_Texture:SetHorizTile(true)
DatabaseViewTitleBar_Texture:SetAllPoints()
Ahoy.DatabaseViewTitleBar.background = DatabaseViewTitleBar_Texture
Ahoy.DatabaseViewTitleBar.text = Ahoy.DatabaseViewTitleBar.text or Ahoy.DatabaseViewTitleBar:CreateFontString(nil,"ARTWORK","GameFontNormal")
Ahoy.DatabaseViewTitleBar.text:SetAllPoints(true)
Ahoy.DatabaseViewTitleBar.text:SetJustifyH("CENTER")
Ahoy.DatabaseViewTitleBar.text:SetJustifyV("CENTER")
Ahoy.DatabaseViewTitleBar.text:SetText("Database View");
Ahoy.DatabaseViewTitleBar:EnableMouse(true)
Ahoy.DatabaseViewTitleBar:RegisterForDrag("LeftButton")
Ahoy.DatabaseViewTitleBar:SetScript("OnDragStart", 
function() 
	Ahoy.DatabaseViewFrame:StartMoving() 
end)
Ahoy.DatabaseViewTitleBar:SetScript("OnDragStop", 
function() 
	Ahoy.DatabaseViewFrame:StopMovingOrSizing() 
end)
Ahoy.DatabaseViewTitleBar:Show()

-- Database View Close Button --
local CloseDatabaseViewButton = CreateFrame("Button", nil, Ahoy.DatabaseViewTitleBar)
CloseDatabaseViewButton:SetPoint("TOPRIGHT", 0, -1)
CloseDatabaseViewButton:SetWidth(18)
CloseDatabaseViewButton:SetHeight(18)
local CloseDatabaseViewButton_ntex = CloseDatabaseViewButton:CreateTexture()
CloseDatabaseViewButton_ntex:SetTexture("Interface/Buttons/ui-panel-minimizebutton-up")
CloseDatabaseViewButton_ntex:SetTexCoord(0.2, 0.8, 0.2, 0.8)
CloseDatabaseViewButton_ntex:SetAllPoints()	
CloseDatabaseViewButton:SetNormalTexture(CloseDatabaseViewButton_ntex)
local CloseDatabaseViewButton_htex = CloseDatabaseViewButton:CreateTexture()
CloseDatabaseViewButton_htex:SetTexture("Interface/Buttons/ui-panel-minimizebutton-highlight")
CloseDatabaseViewButton_htex:SetTexCoord(0.2, 0.8, 0.2, 0.8)
CloseDatabaseViewButton_htex:SetAllPoints()
CloseDatabaseViewButton:SetHighlightTexture(CloseDatabaseViewButton_htex)
local CloseDatabaseViewButton_ptex = CloseDatabaseViewButton:CreateTexture()
CloseDatabaseViewButton_ptex:SetTexture("Interface/Buttons/ui-panel-minimizebutton-down")
CloseDatabaseViewButton_ptex:SetTexCoord(0.2, 0.8, 0.2, 0.8)
CloseDatabaseViewButton_ptex:SetAllPoints()
CloseDatabaseViewButton:SetPushedTexture(CloseDatabaseViewButton_ptex)
CloseDatabaseViewButton:SetScript("OnClick", 
	function (self, button, down)
		Ahoy.DatabaseViewFrame:Hide();
	end)


-- Database View Tabs --
Ahoy.DatabaseViewTab1 = CreateFrame("Frame",nil,Ahoy.DatabaseViewFrame)
Ahoy.DatabaseViewTab1:SetWidth(100) -- Set these to whatever height/width is needed 
Ahoy.DatabaseViewTab1:SetHeight(25) -- for your Texture
Ahoy.DatabaseViewTab1:SetPoint("TOPLEFT",0,-25)
local DatabaseViewTab1_Texture = Ahoy.DatabaseViewTab1:CreateTexture() 
DatabaseViewTab1_Texture:SetTexture("Interface/spellbook/ui-spellbook-tab-unselected", "REPEAT", "REPEAT")
DatabaseViewTab1_Texture:SetTexCoord(0, 1, 0.7, 0.3)
DatabaseViewTab1_Texture:SetAllPoints()
Ahoy.DatabaseViewTab1.background = DatabaseViewTab1_Texture
Ahoy.DatabaseViewTab1.text = Ahoy.DatabaseViewTab1.text or Ahoy.DatabaseViewTab1:CreateFontString(nil,"ARTWORK","GameFontNormal")
Ahoy.DatabaseViewTab1.text:SetAllPoints(true)
Ahoy.DatabaseViewTab1.text:SetJustifyH("CENTER")
Ahoy.DatabaseViewTab1.text:SetJustifyV("CENTER")
Ahoy.DatabaseViewTab1.text:SetText("Item DB");

-- dbview parent frame 
Ahoy.DBViewParentFrame = CreateFrame("Frame", "Loot Frame", Ahoy.DatabaseViewFrame) 
Ahoy.DBViewParentFrame:SetSize(400, 530) 
Ahoy.DBViewParentFrame:SetPoint("BOTTOMLEFT",0,20) 
Ahoy.DBViewParentFrame_Texture = Ahoy.DBViewParentFrame:CreateTexture() 
Ahoy.DBViewParentFrame_Texture:SetAllPoints() 
Ahoy.DBViewParentFrame_Texture:SetColorTexture(0,0,0,0.4) 
Ahoy.DBViewParentFrame.background = Ahoy.DBViewParentFrame_Texture 

-- dbview scroll frame 
local AhoyDBViewScrollFrame = CreateFrame("ScrollFrame", nil, Ahoy.DBViewParentFrame) 
AhoyDBViewScrollFrame:SetPoint("TOPLEFT", 4, -4) 
AhoyDBViewScrollFrame:SetPoint("BOTTOMRIGHT", -4, 4) 
AhoyDBViewScrollFrame:SetScript("OnMouseWheel", 
	function(self, delta)
		Ahoy.DBViewScrollbar:SetValue(AhoyDBViewScrollFrame:GetVerticalScroll()-(delta*20)) 
	end)
Ahoy.DBViewParentFrame.AhoyDBViewScrollFrame = AhoyDBViewScrollFrame 

-- dbview scrollbar 
Ahoy.DBViewScrollbar = CreateFrame("Slider", nil, AhoyDBViewScrollFrame, "UIPanelScrollBarTemplate") 
Ahoy.DBViewScrollbar:SetPoint("TOPLEFT", Ahoy.DBViewParentFrame, "TOPRIGHT", -18, -16) 
Ahoy.DBViewScrollbar:SetPoint("BOTTOMLEFT", Ahoy.DBViewParentFrame, "BOTTOMRIGHT", 20, 16) 
Ahoy.DBViewScrollbar:SetMinMaxValues(-1, 200) 
Ahoy.DBViewScrollbar:SetValueStep(1) 
Ahoy.DBViewScrollbar.scrollStep = 1
Ahoy.DBViewScrollbar:SetValue(0) 
Ahoy.DBViewScrollbar:SetWidth(16) 
Ahoy.DBViewScrollbar:SetScript("OnValueChanged", 
function (self, value) 
self:GetParent():SetVerticalScroll(value) 
end) 
local scrollbg1 = Ahoy.DBViewScrollbar:CreateTexture(nil, "BACKGROUND") 
scrollbg1:SetAllPoints(Ahoy.DBViewScrollbar) 
scrollbg1:SetTexture(0, 0, 0, 0.4) 
Ahoy.DBViewParentFrame.DBViewScrollbar = Ahoy.DBViewScrollbar 

-- dbview content frame 
AhoyDBViewContentFrame = CreateFrame("Frame", "Loot Scroll Frame", AhoyDBViewScrollFrame) 
AhoyDBViewContentFrame:SetSize(300, 300) 
AhoyDBViewContentFrame:SetPoint("LEFT",25,0) 
AhoyDBViewContentFrame:EnableMouse();
AhoyDBViewContentFrame.text = AhoyDBViewContentFrame.text or AhoyDBViewContentFrame:CreateFontString(nil,"ARTWORK","GameFontNormal")
AhoyDBViewContentFrame.text:SetAllPoints(true)
AhoyDBViewContentFrame.text:SetJustifyH("LEFT")
AhoyDBViewContentFrame.text:SetJustifyV("TOP")
AhoyDBViewContentFrame:SetFrameLevel(100)
AhoyDBViewContentFrame:SetToplevel(true)
AhoyDBViewContentFrame:SetHyperlinksEnabled(true)
AhoyDBViewContentFrame:SetScript("OnHyperlinkClick", 
	function(self,link,text,button) 
		SetItemRef(link, text, button, AhoyDBViewContentFrame)
	end);
AhoyDBViewScrollFrame:SetScrollChild(AhoyDBViewContentFrame)

-- Database View StatusBar --
Ahoy.DatabaseViewStatusBar = CreateFrame("Frame",nil,Ahoy.DatabaseViewFrame)
Ahoy.DatabaseViewStatusBar:SetWidth(400) -- Set these to whatever height/width is needed 
Ahoy.DatabaseViewStatusBar:SetHeight(24) -- for your Texture
Ahoy.DatabaseViewStatusBar:SetPoint("BOTTOM",0,0)
local DatabaseViewStatusBar_Texture = Ahoy.DatabaseViewStatusBar:CreateTexture() 
--DatabaseViewStatusBar_Texture:SetTexture("Interface/transmogrify/transmoghorizontal", "REPEAT", "REPEAT")
--DatabaseViewStatusBar_Texture:SetTexCoord(0, 1, 0.28, 0.1)
DatabaseViewStatusBar_Texture:SetVertexColor(0,0,0,0.9) 
DatabaseViewStatusBar_Texture:SetHorizTile(true)
DatabaseViewStatusBar_Texture:SetAllPoints()
Ahoy.DatabaseViewStatusBar.background = DatabaseViewStatusBar_Texture
Ahoy.DatabaseViewStatusBar.text = Ahoy.DatabaseViewStatusBar.text or Ahoy.DatabaseViewStatusBar:CreateFontString(nil,"ARTWORK","GameFontNormal")
Ahoy.DatabaseViewStatusBar.text:SetAllPoints(true)
Ahoy.DatabaseViewStatusBar.text:SetJustifyH("LEFT")
Ahoy.DatabaseViewStatusBar.text:SetJustifyV("CENTER")


----------------------------------------------------------
--	Function											--
----------------------------------------------------------

function Ahoy_DatabaseViewInitialize()
	if Ahoy.databaseViewInitialized == false then
		Ahoy.databaseViewInitialized = true;
		-- initialize --
		local totalStringSize = 0;
		local totalCreatures = 0;
		local totalEntries = 0;
		for k, v in pairs(AhoyItemDB) do
			totalCreatures =  totalCreatures + 1;
			AhoyDBViewTextBlock = CreateFrame("Frame", "Ahoy DBView Text Block", AhoyDBViewContentFrame) 
			AhoyDBViewTextBlock:SetSize(300, totalStringSize) 
			AhoyDBViewTextBlock:SetPoint("TOPLEFT",25,-totalStringSize) 
			AhoyDBViewTextBlock.text = AhoyDBViewTextBlock.text or AhoyDBViewTextBlock:CreateFontString(nil,"ARTWORK","GameFontNormal")
			AhoyDBViewTextBlock.text:SetAllPoints(true)
			AhoyDBViewTextBlock.text:SetJustifyH("LEFT")
			AhoyDBViewTextBlock.text:SetJustifyV("TOP")
			AhoyDBViewTextBlock:SetFrameLevel(100)
			AhoyDBViewTextBlock:SetToplevel(true)
			AhoyDBViewTextBlock:SetHyperlinksEnabled(true)
			AhoyDBViewTextBlock:SetScript("OnHyperlinkClick", 
				function(self,link,text,button) 
					SetItemRef(link, text, button, AhoyDBViewTextBlock)
				end);
			AhoyDBViewTextBlock:SetScript("OnHyperlinkEnter", 
				function(self,link,text,button) 
					GameTooltip:SetOwner(Ahoy.DatabaseViewFrame, "ANCHOR_RIGHT", 0, -300);
					GameTooltip:SetHyperlink(link)
					
				end); 
			AhoyDBViewTextBlock:SetScript("OnHyperlinkLeave", 
				function(self,link,text,button) 
					GameTooltip:Hide()
				end); 
			AhoyDBViewTextBlock.text:SetText(k .. "\n" .. Ahoy_GetLootStringWithIcons(k))
			local stringHeight = AhoyDBViewTextBlock.text:GetStringHeight()
			totalStringSize = totalStringSize + stringHeight;
			AhoyDBViewTextBlock:SetHeight(stringHeight)
			if AhoyItemDB[k] ~= nil and AhoyItemDB[k] ~= "No reward." then
				totalEntries = totalEntries + getn(AhoyItemDB[k]);
			end
		end
		Ahoy.DBViewScrollbar:SetMinMaxValues(-1, totalStringSize - 500) 
		Ahoy.DatabaseViewStatusBar.text:SetText("   " .. totalCreatures .. " Creature Types    " .. totalEntries .. " Known Items")
	end
	Ahoy.DatabaseViewFrame:Show();
end