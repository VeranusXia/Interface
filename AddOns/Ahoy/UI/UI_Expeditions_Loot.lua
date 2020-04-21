----------------------------------------------------------
-------------- Expeditions Window - Loot -----------------
----------------------------------------------------------

----------------------------------------------------------
--	Globals												--
----------------------------------------------------------
Ahoy.canBroadcast = true;

----------------------------------------------------------
--	UI													--
----------------------------------------------------------

-- loot parent frame 
Ahoy.LootParentFrame = CreateFrame("Frame", "Loot Frame", Ahoy.ExpeditionWindowFrame) 
Ahoy.LootParentFrame:SetSize(165, 145) 
Ahoy.LootParentFrame:SetPoint("Right",-20,0) 
Ahoy.LootParentFrame_Texture = Ahoy.LootParentFrame:CreateTexture() 
Ahoy.LootParentFrame_Texture:SetAllPoints() 
Ahoy.LootParentFrame_Texture:SetColorTexture(0,0,0,0) 
Ahoy.LootParentFrame.background = Ahoy.LootParentFrame_Texture 

-- loot scroll frame 
local AhoyLootScrollFrame = CreateFrame("ScrollFrame", nil, Ahoy.LootParentFrame) 
AhoyLootScrollFrame:SetPoint("TOPLEFT", 4, -24) 
AhoyLootScrollFrame:SetPoint("BOTTOMRIGHT", -4, 4) 
AhoyLootScrollFrame:SetScript("OnMouseWheel", 
	function(self, delta)
		Ahoy.LootScrollbar:SetValue(AhoyLootScrollFrame:GetVerticalScroll()-(delta*20)) 
	end)
Ahoy.LootParentFrame.AhoyLootScrollFrame = AhoyLootScrollFrame 

-- loot scrollbar 
Ahoy.LootScrollbar = CreateFrame("Slider", nil, AhoyLootScrollFrame, "UIPanelScrollBarTemplate") 
Ahoy.LootScrollbar:SetPoint("TOPLEFT", Ahoy.LootParentFrame, "TOPRIGHT", 2, -16) 
Ahoy.LootScrollbar:SetPoint("BOTTOMLEFT", Ahoy.LootParentFrame, "BOTTOMRIGHT", 20, 16) 
Ahoy.LootScrollbar:SetMinMaxValues(-1, 200) 
Ahoy.LootScrollbar:SetValueStep(1) 
Ahoy.LootScrollbar.scrollStep = 1
Ahoy.LootScrollbar:SetValue(0) 
Ahoy.LootScrollbar:SetWidth(16) 
Ahoy.LootScrollbar:SetScript("OnValueChanged", 
function (self, value) 
self:GetParent():SetVerticalScroll(value) 
end) 
local scrollbg1 = Ahoy.LootScrollbar:CreateTexture(nil, "BACKGROUND") 
scrollbg1:SetAllPoints(Ahoy.LootScrollbar) 
scrollbg1:SetTexture(0, 0, 0, 0.4) 
Ahoy.LootParentFrame.LootScrollbar = Ahoy.LootScrollbar 

-- loot content frame 
AhoyLootContentFrame = CreateFrame("Frame", "Loot Scroll Frame", AhoyLootScrollFrame) 
AhoyLootContentFrame:SetSize(200, 300) 
AhoyLootContentFrame:SetPoint("Right",-25,0) 
AhoyLootContentFrame:EnableMouse();
AhoyLootContentFrame.text = AhoyLootContentFrame.text or AhoyLootContentFrame:CreateFontString(nil,"ARTWORK","GameFontNormal")
AhoyLootContentFrame.text:SetAllPoints(true)
AhoyLootContentFrame.text:SetJustifyH("LEFT")
AhoyLootContentFrame.text:SetJustifyV("TOP")
AhoyLootContentFrame:SetFrameLevel(100)
AhoyLootContentFrame:SetToplevel(true)
AhoyLootContentFrame:SetHyperlinksEnabled(true)
AhoyLootContentFrame:SetScript("OnHyperlinkClick", 
	function(self,link,text,button) 
		SetItemRef(link, text, button, AhoyLootContentFrame)
	end);
AhoyLootContentFrame:SetScript("OnHyperlinkEnter", 
	function(self,link,text,button) 
		GameTooltip:SetOwner(AhoyLootContentFrame, "ANCHOR_LEFT", 0, -300);
		GameTooltip:SetHyperlink(link)	
	end); 
AhoyLootContentFrame:SetScript("OnHyperlinkLeave", 
	function(self,link,text,button) 
		GameTooltip:Hide()
	end); 

AhoyLootScrollFrame:SetScrollChild(AhoyLootContentFrame)

-- loot toolbar Frame
AhoyLootToolbarFrame = CreateFrame("Frame", "Ahoy Loot Toolbar", Ahoy.LootParentFrame)
AhoyLootToolbarFrame:SetSize(170, 20)
AhoyLootToolbarFrame:SetPoint("CENTER", -2, 62)
		
-- loot toolbar collected show/hide button
AhoyLootToolbarCollectedButton = CreateFrame("Frame", "Ahoy Loot Toolbar Collected Button", AhoyLootToolbarFrame)
AhoyLootToolbarCollectedButton:SetSize(15, 15)
AhoyLootToolbarCollectedButton:SetPoint("LEFT", 10, 0)
AhoyLootToolbarCollectedButton_Texture = AhoyLootToolbarCollectedButton:CreateTexture() 
AhoyLootToolbarCollectedButton_Texture:SetAllPoints() 
AhoyLootToolbarCollectedButton_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
AhoyLootToolbarCollectedButton_Texture:SetTexCoord(0.755 - 0.067, 0.755, 0.640625 - 0.067, 0.640625)
AhoyLootToolbarCollectedButton.texture = AhoyLootToolbarCollectedButton_Texture
AhoyLootToolbarCollectedButton:SetScript("OnMouseDown", 
function() 
	Ahoy_ShowHideCollected()
end)

-- loot toolbar mob name text
AhoyLootToolbarMobNameSubFrame = CreateFrame("Frame", "AhoyLootToolbarMobNameSubFrame", AhoyLootToolbarFrame)
AhoyLootToolbarMobNameSubFrame:SetSize(100, 20)
AhoyLootToolbarMobNameSubFrame:SetPoint("CENTER", 5, 0)
AhoyLootToolbarMobNameSubFrame.text = AhoyLootToolbarMobNameSubFrame.text or AhoyLootToolbarMobNameSubFrame:CreateFontString(nil,"ARTWORK","QuestFontNormalSmall")
AhoyLootToolbarMobNameSubFrame.text:SetAllPoints(true)
AhoyLootToolbarMobNameSubFrame.text:SetTextColor(1,1,1,0.8)
AhoyLootToolbarMobNameSubFrame.text:SetJustifyH("LEFT")
AhoyLootToolbarMobNameSubFrame.text:SetJustifyV("CENTER")
AhoyLootToolbarMobNameSubFrame.text:SetText(format(" "))

-- loot toolbar broadcast button
AhoyLootToolbarBroadcastButton = CreateFrame("Frame", "Ahoy Loot Toolbar Broadcast Button", AhoyLootToolbarFrame)
AhoyLootToolbarBroadcastButton:SetSize(15, 15)
AhoyLootToolbarBroadcastButton:SetPoint("RIGHT", -10, 0)
AhoyLootToolbarBroadcastButton_Texture = AhoyLootToolbarBroadcastButton:CreateTexture() 
AhoyLootToolbarBroadcastButton_Texture:SetAllPoints() 
AhoyLootToolbarBroadcastButton_Texture:SetTexture("Interface/Buttons/ui-guildbutton-motd-up");
AhoyLootToolbarBroadcastButton.texture = AhoyLootToolbarBroadcastButton_Texture
AhoyLootToolbarBroadcastButton:SetScript("OnMouseDown", 
function() 
	if Ahoy.canBroadcast == true then
		AhoyLootToolbarBroadcastButton_Texture:SetTexture("Interface/Buttons/ui-guildbutton-motd-disabled");
		Ahoy.canBroadcast = false;
		Ahoy__wait(3,ReEnableBroadcastButton);
		AhoyBroadcastLoot()
	end
end)

----------------------------------------------------------
--	Functions											--
----------------------------------------------------------

function Ahoy_GetLootString(selectedCreatureClass)
	local lootString = ""
	if AhoyItemDB[selectedCreatureClass] ~= nil then
		-- build loot string --
		local itemEntriesNumber = getn(AhoyItemDB[selectedCreatureClass]);
		for i = 1, itemEntriesNumber, 1 do
			local itemLink = AhoyItemDB[selectedCreatureClass][i];
			if Ahoy_Settings_New.ShowCollected == false then
				if Ahoy_CheckItemCollected(itemLink) == false then
					lootString = lootString .. " " .. itemLink .. "\n";
				end
			else
				lootString = lootString .. " " .. itemLink .. "\n";
			end
		end
	end
	return lootString;
end

function Ahoy_GetLootStringWithIcons(selectedCreatureClass)
	local lootString = ""
	local collectedIcon = "|Tinterface\\buttons\\ui-checkbox-check:15:15:0:0|t";
	local notCollectedIcon = "|Tinterface\\buttons\\ui-checkbox-check-disabled:15:15:0:0|t";
	if AhoyItemDB[selectedCreatureClass] ~= nil then
		-- build loot string --
		local itemEntriesNumber = getn(AhoyItemDB[selectedCreatureClass]);
		for i = 1, itemEntriesNumber, 1 do
			local itemLink = AhoyItemDB[selectedCreatureClass][i];
			if itemLink == "No reward." then notCollectedIcon = ""; end
			if Ahoy_CheckItemCollected(itemLink) == true then
				lootString = lootString .. " " .. collectedIcon .. itemLink .. "\n";
			else
				lootString = lootString .. " " .. notCollectedIcon .. itemLink .. "\n";
			end
		end
	end
	return lootString;
end

function Ahoy_GetChatLootStrings(selectedCreatureClass)
	local lootStrings = {}
	if AhoyItemDB[selectedCreatureClass] ~= nil then
		-- build loot string --
		local itemEntriesNumber = getn(AhoyItemDB[selectedCreatureClass]);
		local stringBuffer = ""
		local index = 1;
		for i = 1, itemEntriesNumber, 1 do
			local itemLinkWH = AhoyItemDB[selectedCreatureClass][i];
			if strlen(itemLinkWH) > 10 then
				local _, _, Color, Ltype, id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(itemLinkWH,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(id)
				if itemLink ~= nil then
					if strlen(stringBuffer..itemLink) > 250 then
						lootStrings[index] = stringBuffer;
						index = index + 1;
						stringBuffer = itemLink;
					else
						stringBuffer = stringBuffer.." "..itemLink;
						if i == itemEntriesNumber then
							lootStrings[index] = stringBuffer;
						end
					end
				end
			else
				lootStrings[1] = "None";
			end
		end
	end
	return lootStrings;
end

function Ahoy_UpdateLootList(selectedCreatureClass)
	local lootString = Ahoy_GetLootString(selectedCreatureClass)
	AhoyLootToolbarMobNameSubFrame.text:SetText(selectedCreatureClass);
	AhoyLootContentFrame.text:SetText(lootString);
	local height = AhoyLootContentFrame.text:GetStringHeight();
	AhoyLootContentFrame:SetHeight(height);
	Ahoy.LootScrollbar:SetMinMaxValues(-1, height/2) 
end

function Ahoy_ShowHideCollected()
	if Ahoy_Settings_New.ShowCollected == true then
		Ahoy_Settings_New.ShowCollected = false;
		AhoyLootToolbarCollectedButton_Texture:SetTexCoord(0.460, 0.530, 0.640625 - 0.067, 0.640625) -- eye closed 1
	else
		Ahoy_Settings_New.ShowCollected = true;
		AhoyLootToolbarCollectedButton_Texture:SetTexCoord(0.360, 0.430, 0.640625 - 0.067, 0.640625) -- eye open
	end
	Ahoy_Settings = Ahoy_Settings_New;
	if Ahoy.selectedTab ~= -1 and Ahoy.selectedTab ~= nil then
		Ahoy_ClickedTab(Ahoy.selectedTab);
	else
		if Ahoy.selectedCreature ~= "" and Ahoy.selectedCreature ~= nil then
			Ahoy_SelectedCreature(Ahoy.selectedCreature);
		end
	end
end

function AhoyBroadcastLoot()
	lootStrings = {};
	if Ahoy.selectedTab ~= -1 and Ahoy.selectedTab ~= nil then
		if Ahoy_Settings_New.DEBUGMODE == true then
			print ("selected tab " .. Ahoy.selectedTab)
		end
		child1, child2, child3, child4 = Ahoy.TabFrames[Ahoy.selectedTab]:GetChildren();
		local selectedCreatureClass = child1.text:GetText();
		lootStrings = Ahoy_GetChatLootStrings(selectedCreatureClass)
	else
		if Ahoy.selectedCreature ~= "" and Ahoy.selectedCreature ~= nil then
			if Ahoy_Settings_New.DEBUGMODE == true then
				print ("selected creature " .. Ahoy.selectedCreature)
			end
			local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-",Ahoy.selectedCreature);
			local npcRaw = AhoyCreatureDB[tonumber(npc_id)];
			if npcRaw ~= nil then
				local name, category, rarity, class = strsplit('|',npcRaw);
				lootStrings = Ahoy_GetChatLootStrings(class)
			end
		end
	end
	print (getn(lootStrings));
	if getn(lootStrings) > 0 then
		if lootStrings[1] ~= "None" then
			lootStrings[0] = "Ahoy! Focus on " .. AhoyLootToolbarMobNameSubFrame.text:GetText() .. ". Potential rewards: ";
			for s = 0, getn(lootStrings), 1 do
				if Ahoy_Settings_New.DEBUGMODE == true then
					print(lootStrings[s])
				end
				SendChatMessage(lootStrings[s] ,"INSTANCE_CHAT");
			end
		else
			if Ahoy_Settings_New.DEBUGMODE == true then
				print("Ignore " .. AhoyLootToolbarMobNameSubFrame.text:GetText() .. " no known loot.")
			end
			SendChatMessage("Ignore " .. AhoyLootToolbarMobNameSubFrame.text:GetText() .. " no known loot." ,"INSTANCE_CHAT");
		end
	end
end

function ReEnableBroadcastButton()
	AhoyLootToolbarBroadcastButton_Texture:SetTexture("Interface/Buttons/ui-guildbutton-motd-up");
	Ahoy.canBroadcast = true;
end