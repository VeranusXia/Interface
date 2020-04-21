---------------------------------------------------------
------------------  Settings Window  --------------------
---------------------------------------------------------
Ahoy.SettingsWindowFrame = CreateFrame("Frame",nil,Ahoy.MainFrame)
Ahoy.SettingsWindowFrame:SetWidth(430) -- Set these to whatever height/width is needed 
Ahoy.SettingsWindowFrame:SetHeight(150) -- for your Texture
Ahoy.SettingsWindowFrame:SetPoint("CENTER",0,0)
Ahoy.SettingsWindowFrame_Texture = Ahoy.SettingsWindowFrame:CreateTexture() 
Ahoy.SettingsWindowFrame_Texture:SetAllPoints() 
Ahoy.SettingsWindowFrame_Texture:SetColorTexture(0,0,0,0.8)
Ahoy.SettingsWindowFrame.background = Ahoy.SettingsWindowFrame_Texture
Ahoy.SettingsWindowFrame:SetFrameLevel(20);
Ahoy.SettingsWindowFrame:SetFrameStrata("DIALOG");
Ahoy.SettingsWindowFrame:Hide()

local icon = LibStub("LibDBIcon-1.0", true)

function Ahoy_MinimapButton_Toggle()
	if Ahoy_Settings_New.Toggle_HideMinimapIcon == true then
		icon:Hide("Ahoy")
		--Ahoy_MinimapButton:Hide();
	else
		icon:Show("Ahoy")
		--Ahoy_MinimapButton:Show();
	end
end


Ahoy_CheckButton_ShowSelectedMobLoot = CreateFrame("CheckButton", "Ahoy_CheckButton_ShowSelectedMobLoot_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_ShowSelectedMobLoot:SetPoint("TOPLEFT", 10, -10);
Ahoy_CheckButton_ShowSelectedMobLoot_GlobalNameText:SetText(" Show Selected Mob Loot");
Ahoy_CheckButton_ShowSelectedMobLoot.tooltip = "When checked, Ahoy will display potential loot rewards from the targeted mob on the right tab.";
Ahoy_CheckButton_ShowSelectedMobLoot:SetScript("OnClick", function() Ahoy_Settings_New.Toggle_MobTargetLootDisplay = Ahoy_CheckButton_ShowSelectedMobLoot:GetChecked(); Ahoy_Settings = Ahoy_Settings_New; end);

Ahoy_CheckButton_ShowRewardsAtTheEnd = CreateFrame("CheckButton", "Ahoy_CheckButton_ShowRewardsAtTheEnd_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_ShowRewardsAtTheEnd:SetPoint("TOPLEFT", 10, -30);
Ahoy_CheckButton_ShowRewardsAtTheEnd_GlobalNameText:SetText(" Show Rewards at the End");
Ahoy_CheckButton_ShowRewardsAtTheEnd.tooltip = "Instantly show rewards at the end of an expedition in the Ahoy window.";
Ahoy_CheckButton_ShowRewardsAtTheEnd:SetScript("OnClick", function() Ahoy_Settings_New.Toggle_ShowRewards = Ahoy_CheckButton_ShowRewardsAtTheEnd:GetChecked(); Ahoy_Settings = Ahoy_Settings_New; end);

Ahoy_CheckButton_AutoShowAhoyOnTable = CreateFrame("CheckButton", "Ahoy_CheckButton_AutoShowAhoyOnTable_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_AutoShowAhoyOnTable:SetPoint("TOPLEFT", 10, -50);
Ahoy_CheckButton_AutoShowAhoyOnTable_GlobalNameText:SetText(" Auto Open - Expedition Map");
Ahoy_CheckButton_AutoShowAhoyOnTable.tooltip = "The Ahoy window will open automatically when you click the Expedition Map";
Ahoy_CheckButton_AutoShowAhoyOnTable:SetScript("OnClick", function() Ahoy_Settings_New.Toggle_AutoShowAhoyOnMissionTable = Ahoy_CheckButton_AutoShowAhoyOnTable:GetChecked(); Ahoy_Settings = Ahoy_Settings_New; end);

Ahoy_CheckButton_AutoShowAhoyOnIsland = CreateFrame("CheckButton", "Ahoy_CheckButton_AutoShowAhoyOnIsland_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_AutoShowAhoyOnIsland:SetPoint("TOPLEFT", 10, -70);
Ahoy_CheckButton_AutoShowAhoyOnIsland_GlobalNameText:SetText(" Auto Open - Island Expedition");
Ahoy_CheckButton_AutoShowAhoyOnIsland.tooltip = "The Ahoy window will open automatically when a new Island Expedition Begins";
Ahoy_CheckButton_AutoShowAhoyOnIsland:SetScript("OnClick", function() Ahoy_Settings_New.Toggle_AutoShowAhoyOnIsland = Ahoy_CheckButton_AutoShowAhoyOnIsland:GetChecked(); Ahoy_Settings = Ahoy_Settings_New; end);

Ahoy_CheckButton_HideMinimapButton = CreateFrame("CheckButton", "Ahoy_CheckButton_HideMinimapButton_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_HideMinimapButton:SetPoint("TOPLEFT", 10, -90);
Ahoy_CheckButton_HideMinimapButton_GlobalNameText:SetText(" Hide the minimap button.");
Ahoy_CheckButton_HideMinimapButton.tooltip = "Hides the minimap button, ahoy can be opened with the /ahoy chat command too.";
Ahoy_CheckButton_HideMinimapButton:SetScript("OnClick", 
function() 
	Ahoy_Settings_New.Toggle_HideMinimapIcon = Ahoy_CheckButton_HideMinimapButton:GetChecked();
	Ahoy_Settings = Ahoy_Settings_New;
	Ahoy_MinimapButton_Toggle()
end);

Ahoy_CheckButton_MapIcons = CreateFrame("CheckButton", "Ahoy_CheckButton_MapIcons_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_MapIcons:SetPoint("TOPLEFT", 10, -110);
Ahoy_CheckButton_MapIcons_GlobalNameText:SetText(" Show map icons.");
Ahoy_CheckButton_MapIcons.tooltip = "Shows possible rare locations and cave locations with possible rares on the map.";
Ahoy_CheckButton_MapIcons:SetScript("OnClick", 
function() 
	Ahoy_Settings_New.MapIcons = Ahoy_CheckButton_MapIcons:GetChecked();
	Ahoy_Settings = Ahoy_Settings_New;
	Ahoy_UpdateMap(true)
end);

Ahoy_CheckButton_ShowTooltipMobLoot = CreateFrame("CheckButton", "Ahoy_CheckButton_ShowTooltipMobLoot_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_ShowTooltipMobLoot:SetPoint("TOP", 20, -10);
Ahoy_CheckButton_ShowTooltipMobLoot_GlobalNameText:SetText(" Tooltip - Show Loot");
Ahoy_CheckButton_ShowTooltipMobLoot.tooltip = "When checked, Ahoy will display potential loot rewards from the mob you mouseover in the tooltip.";
Ahoy_CheckButton_ShowTooltipMobLoot:SetScript("OnClick", function() Ahoy_Settings_New.Toggle_MobTooltipLootDisplay = Ahoy_CheckButton_ShowTooltipMobLoot:GetChecked(); Ahoy_Settings = Ahoy_Settings_New; end);

Ahoy_CheckButton_TooltipShowMobCategory = CreateFrame("CheckButton", "Ahoy_CheckButton_TooltipShowMobCategory_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_TooltipShowMobCategory:SetPoint("TOP", 20, -30);
Ahoy_CheckButton_TooltipShowMobCategory_GlobalNameText:SetText(" Tooltip - Show Details");
Ahoy_CheckButton_TooltipShowMobCategory.tooltip = "When checked, Ahoy will display mob category when highlighting mobs and named chests and also shrine buffs and debuffs when highlighting them.";
Ahoy_CheckButton_TooltipShowMobCategory:SetScript("OnClick", function() Ahoy_Settings_New.Toggle_MobMouseOverCategory = Ahoy_CheckButton_TooltipShowMobCategory:GetChecked(); Ahoy_Settings = Ahoy_Settings_New; end);

Ahoy_CheckButton_DEBUG = CreateFrame("CheckButton", "Ahoy_CheckButton_DEBUG_GlobalName", Ahoy.SettingsWindowFrame, "ChatConfigCheckButtonTemplate");
Ahoy_CheckButton_DEBUG:SetPoint("TOP", 20, -50);
Ahoy_CheckButton_DEBUG_GlobalNameText:SetText(" Enable Debug Mode");
Ahoy_CheckButton_DEBUG.tooltip = "Enables debug mode, showing extra stuff, for development use only.";
Ahoy_CheckButton_DEBUG:SetScript("OnClick", function() Ahoy_Settings_New.DEBUGMODE = Ahoy_CheckButton_DEBUG:GetChecked(); Ahoy_Settings = Ahoy_Settings_New; end);


function Ahoy_LoadCheckButtonStates()
	Ahoy_CheckButton_ShowSelectedMobLoot:SetChecked(Ahoy_Settings_New.Toggle_MobTargetLootDisplay);
	Ahoy_CheckButton_TooltipShowMobCategory:SetChecked(Ahoy_Settings_New.Toggle_MobMouseOverCategory);
	Ahoy_CheckButton_ShowRewardsAtTheEnd:SetChecked(Ahoy_Settings_New.Toggle_ShowRewards);
	Ahoy_CheckButton_AutoShowAhoyOnTable:SetChecked(Ahoy_Settings_New.Toggle_AutoShowAhoyOnMissionTable);
	Ahoy_CheckButton_AutoShowAhoyOnIsland:SetChecked(Ahoy_Settings_New.Toggle_AutoShowAhoyOnIsland);
	Ahoy_CheckButton_HideMinimapButton:SetChecked(Ahoy_Settings_New.Toggle_HideMinimapIcon);
	Ahoy_CheckButton_ShowTooltipMobLoot:SetChecked(Ahoy_Settings_New.Toggle_MobTooltipLootDisplay);
	Ahoy_CheckButton_DEBUG:SetChecked(Ahoy_Settings_New.DEBUGMODE);
	Ahoy_CheckButton_MapIcons:SetChecked(Ahoy_Settings_New.MapIcons);
end

-- Close Settings Button --
local CloseSettingsButton = CreateFrame("Button", nil, Ahoy.SettingsWindowFrame)
CloseSettingsButton:SetPoint("CENTER", 0, -90)
CloseSettingsButton:SetWidth(120)
CloseSettingsButton:SetHeight(30)
CloseSettingsButton:SetText("Close Settings")
CloseSettingsButton:SetNormalFontObject("GameFontNormal")
local CloseSettingsButton_ntex = CloseSettingsButton:CreateTexture()
CloseSettingsButton_ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
CloseSettingsButton_ntex:SetTexCoord(0, 0.625, 0, 0.6875)
CloseSettingsButton_ntex:SetAllPoints()	
CloseSettingsButton:SetNormalTexture(CloseSettingsButton_ntex)
local CloseSettingsButton_htex = CloseSettingsButton:CreateTexture()
CloseSettingsButton_htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
CloseSettingsButton_htex:SetTexCoord(0, 0.625, 0, 0.6875)
CloseSettingsButton_htex:SetAllPoints()
CloseSettingsButton:SetHighlightTexture(CloseSettingsButton_htex)
local CloseSettingsButton_ptex = CloseSettingsButton:CreateTexture()
CloseSettingsButton_ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
CloseSettingsButton_ptex:SetTexCoord(0, 0.625, 0, 0.6875)
CloseSettingsButton_ptex:SetAllPoints()
CloseSettingsButton:SetPushedTexture(CloseSettingsButton_ptex)
CloseSettingsButton:SetScript("OnClick", function (self, button, down) Ahoy.SettingsWindowFrame:Hide() end)