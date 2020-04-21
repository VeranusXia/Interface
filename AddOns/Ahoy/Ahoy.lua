local addonName, addon = ...
Ahoy.DoingIslandExpedition = false;
Ahoy.IslandsMapOpen = false;
Ahoy.WindowClosedDuringQueue = false;
Ahoy.WindowClosedOutsideExpedition = false;
Ahoy.CorrectlyQueued = false;
Ahoy.InQueue = false;
Ahoy.Score = {};
Ahoy.RareScore = {};
Ahoy.EntriesCount = 0;
Ahoy.waitTable = {};
Ahoy.CollectedMounts = {};
Ahoy.waitFrame = nil;
Ahoy.DEBUG_MissingNPCs = {};

Ahoy_CollectedData_New = {}

function Ahoy_Load_CollectedData()
	Ahoy_CollectedData = Ahoy_CollectedData or {} -- create table if one doesn't exist
	Ahoy_CollectedData_New = Ahoy_CollectedData -- assign settings declared above
end

local function splits(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function Ahoy_BuildCollectedMountsTable()
	local mountIDs = C_MountJournal.GetMountIDs();
	for i = 1, getn(mountIDs), 1 do
		creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountIDs[i])
		Ahoy.CollectedMounts[creatureName] = isCollected
	end
end

function Ahoy_CheckItemCollected(rawLink)
	if string.len(rawLink) > 20 then
		local _, _, Color, Ltype, id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(rawLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(id);
		if itemType == "Miscellaneous" then
			if itemSubType == "Mount" then
				if Ahoy.CollectedMounts[itemName] == true then
					return true;
				end
			elseif itemSubType == "Companion Pets" then
				local speciesId, petGUID = C_PetJournal.FindPetIDByName(itemName);
				local ownedString = C_PetJournal.GetOwnedBattlePetString(speciesId)
				if ownedString ~= nil then
					local t1, t2 = strsplit("|",ownedString)
					local w1, w2 = strsplit(" ",t2)
					if w2 == "(1/3)" or w2 == "(2/3)" or w2 == "(3/3)" then
						return true;
					end
				end
			elseif itemSubType == "Other" then
				return PlayerHasToy(id);
			end
		elseif itemType == "Quest" then
			if AhoyQuestItemDB[tostring(id)] ~= nil then
				return IsQuestFlaggedCompleted(AhoyQuestItemDB[tostring(id)]);
			else
				print("Ahoy_Error: Missing Quest Item ID: "..id)
			end
		elseif itemType == "Armor" then
			return C_TransmogCollection.PlayerHasTransmog(id)
		elseif itemType == "Weapon" then
			return C_TransmogCollection.PlayerHasTransmog(id)
		end
		return false;
	end
end

function AhoyResetVariables()
	Ahoy.MapIconsLoaded = false;
	Ahoy.EntriesCount = 0;
	Ahoy.Score = {};
	Ahoy.RareScore = {};
	Ahoy.DoingIslandExpedition = false;
	Ahoy.InQueue = false;
	ClearTabSelect();
	for variable = 0, 16, 1 do
		child1, child2, child3, child4 = Ahoy.TabFrames[variable]:GetChildren()
		child1.text:SetText(format(" "))
		child2.text:SetText(format(" "))
		child3:Hide();
		child4.text:SetText(format(" "))
	end
	AhoyLootContentFrame.text:SetText("")
	Ahoy_AdjustTabs(-1);
	Ahoy_BuildCollectedMountsTable()
end

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function UpdateScore ()
	currentTab = 0;
	Ahoy.ScoreCopy = shallowcopy(Ahoy.Score);
	for variable = 0, Ahoy.EntriesCount, 1 do
		highestValue = 0;
		highestKey = " ";
		for k, v in pairs(Ahoy.ScoreCopy) do
			if k ~= "NPC" and k ~= "Ignore" and k ~= "PvP" and currentTab < 16 then
				if v > highestValue then
					highestValue = v;
					highestKey = k;
				end
			end
		end
		if highestKey ~= " " then
			child1, child2, child3, child4 = Ahoy.TabFrames[currentTab]:GetChildren()
			child1.text:SetText(format(highestKey))
			child2.text:SetText(format(Ahoy.ScoreCopy[highestKey] .. "    "))
			if Ahoy.RareScore[highestKey] > 0 then
				child3:Show();
				child4.text:SetText(format(Ahoy.RareScore[highestKey] .. "x"))
			else
				child3:Hide();
				child4.text:SetText(format(" "));
			end
			Ahoy.ScoreCopy[highestKey] = 0;
			currentTab = currentTab + 1;
		end
	end
	-- exclude showing tabs for ignored keys --
	local excludeCount = 0;
	if Ahoy.ScoreCopy["NPC"] ~= nil then
		excludeCount = excludeCount + 1;
	end
	if Ahoy.ScoreCopy["Ignore"] ~= nil then
		excludeCount = excludeCount + 1;
	end
	if Ahoy.ScoreCopy["PvP"] ~= nil then
		excludeCount = excludeCount + 1;
	end
	-- show/hide needed tab frames
	Ahoy_AdjustTabs(Ahoy.EntriesCount - 1 - excludeCount);
end

function Ahoy_AzeriteGain(guid, gain)
	local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-",guid);
	if type == "Creature" or type == "Vehicle" then

		if Ahoy_Settings_New.DEBUGMODE == true then
			if AhoyCreatureDB[tonumber(npc_id)] == nil then
				if Ahoy.DEBUG_MissingNPCs[npc_id] == nil then
					print("DEBUG: Missing NPC: " .. npc_id .. " " .. "Unknown Name");
					Ahoy.DEBUG_MissingNPCs[npc_id] = true;
					if Ahoy_CollectedData_New.MissingNPCs == nil then
						Ahoy_CollectedData_New.MissingNPCs = {}
					end
					if Ahoy_CollectedData_New.MissingNPCs[npc_id] == nil then
						Ahoy_CollectedData_New.MissingNPCs[npc_id] = "Unknown Name" .. "|" .. guid;
						Ahoy_CollectedData = Ahoy_CollectedData_New 
					end
				end
			end
		end

		npcRaw = AhoyCreatureDB[tonumber(npc_id)];
		if npcRaw ~= nil then
			--local npcData = splits(npcRaw,"|");
			local name, category, rarity, class = strsplit('|',npcRaw);
			--local npcClass = npcData[4];
			if class ~= nil then
				if Ahoy.Score[class] == nil then					-- is it a new entry?
					Ahoy.Score[class] = 0;						-- reset entry score to 0
					Ahoy.RareScore[class] = 0;
					Ahoy.EntriesCount = Ahoy.EntriesCount + 1;		-- increase count
				end
			end
			Ahoy.Score[class] = Ahoy.Score[class] + gain;
			if rarity == "Rare" or rarity == "Rare Elite" then
				Ahoy.RareScore[class] = Ahoy.RareScore[class] + 1;
			end
			UpdateScore();
		else
			print("[ Ahoy Error : Missing NPC ID : " .. npc_id .. " ]");
		end
	end
	if type == "GameObject" then
		if Ahoy_Settings_New.DEBUGMODE == true then
			print("DEBUG: Azerite Gain from: " .. type .. " " .. npc_id);
		end
		objectRaw = AhoyGameObjectDB[tonumber(npc_id)];
		if objectRaw ~= nil then
			local name, type, class = strsplit('|',objectRaw);
			if type == "Chest" then
				if class ~= nil then
					if Ahoy.Score[class] == nil then					-- is it a new entry?
						Ahoy.Score[class] = 0;						-- reset entry score to 0
						Ahoy.RareScore[class] = 0;
						Ahoy.EntriesCount = Ahoy.EntriesCount + 1;		-- increase count
					end
				end
				Ahoy.Score[class] = Ahoy.Score[class] + gain;
				UpdateScore();				
			end
		end
	end
end

function Ahoy_SelectedCreature(guid)
	Ahoy.selectedCreature = guid;
	ClearTabSelect();
	if guid ~= nil then
		local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-",guid);
		if type == "Creature" then
			npcRaw = AhoyCreatureDB[tonumber(npc_id)];
			if npcRaw ~= nil then
				--local npcData = splits(npcRaw,"|");
				local name, category, rarity, class = strsplit('|',npcRaw);
				--local npcClass = npcData[4];
				Ahoy_UpdateLootList(class)
			end
		end
	else
		if Ahoy.selectedTab == -1 then
			AhoyLootContentFrame.text:SetText(" ");
		end
	end
end

function Ahoy_LoadRewards()
	local name, typeID, subtypeID, iconTextureFile, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers, numRewards = GetLFGCompletionReward();
	if numRewards == nil or numRewards == 0 then
		--print ("No Rewards");
	else
		Ahoy_UpdateRewardsUI(numRewards);
	end
end

function Ahoy_VerifyCorrectQueue()
	local correctQueue = false;
	local LFGInfo = C_LFGInfo.GetAllEntriesForCategory(LE_LFG_CATEGORY_SCENARIO);
	local instanceMapID = LFGInfo[1];
	local IslandDifficultyInfo = C_IslandsQueue.GetIslandDifficultyInfo()
	for idi = 0, getn(IslandDifficultyInfo), 1 do
		local entry = IslandDifficultyInfo[idi];
		if entry ~= nil then
			if entry.difficultyId == instanceMapID then
				correctQueue = true
			end
		end
	end
	return correctQueue;
end

function Ahoy_CheckZone()
	local selectedMap = GetZoneText();
	if AhoyMapDB[selectedMap] ~= nil then
		if Ahoy_Settings_New.Toggle_AutoShowAhoyOnIsland == true then
			Ahoy_OpenMainframe()
		end
		Ahoy_WindowSwitch("Expedition");
		Ahoy.DoingIslandExpedition = true;
	end
end

function Ahoy_VerifyNewlyAddedMissingNPCs()
	if Ahoy_CollectedData_New.MissingNPCs == nil then
		Ahoy_CollectedData_New.MissingNPCs = {}
	end
	if Ahoy_Settings_New.DEBUGMODE == true then
		for index,value in pairs(AhoyCreatureDB) do 
			if Ahoy_CollectedData_New.MissingNPCs[tostring(index)] ~= nil then
				--table.remove(Ahoy_CollectedData_New.MissingNPCs, index);
				Ahoy_CollectedData_New.MissingNPCs[tostring(index)] = nil
			end
		end
	end
	Ahoy_CollectedData = Ahoy_CollectedData_New;
end


----------------------------------------------------------
--	Hooks												--
----------------------------------------------------------
-- Map Frame Hook --
WorldMapFrame:HookScript("OnShow", function() Ahoy_UpdateMap(true) end)
WorldMapFrame:HookScript("OnHide", function() Ahoy_UpdateMap(false) end)
WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", function() Ahoy_UpdateMap(true) end)

-- Object Tooltip Hook --
local currentTooltip = ""
GameTooltip:HookScript('OnSizeChanged', function(self)
	local tooltipString = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
	if Ahoy.DoingIslandExpedition == true and Ahoy_Settings_New.Toggle_MobMouseOverCategory == true then
		if tooltipString ~= nil and tooltipString ~= currentTooltip and AhoyGameObjectDB[tooltipString] then
			currentTooltip = tooltipString
			objectRaw = AhoyGameObjectDB[tooltipString];
			if objectRaw ~= nil then
				local objectData = splits(objectRaw,"|");
				local objectType = objectData[2];
				if objectType == "Chest" then
					local npcClass = objectData[3];
					if npcClass ~= nil then
						GameTooltip:AddLine("Ahoy: " .. npcClass, 1, 1, 1)
						GameTooltip:Show()
					end			
				elseif objectType == "Shrine" then
					local buff = objectData[3];
					local debuff = objectData[4];
					GameTooltip:AddLine("Ahoy: Shrine", 1, 1, 1)
					GameTooltip:AddLine(buff, .5, .5, 1)
					GameTooltip:AddLine(debuff, 1, .5, .5)
					GameTooltip:Show()
				end
			end

		end
	end
end)

GameTooltip:HookScript('OnTooltipCleared', function()
	currentTooltip = nil
end)

----------------------------------------------------------
--	Events												--
----------------------------------------------------------

-- LFG UPDATE
local LFG_UPDATE_EVENT = CreateFrame("FRAME", UIParent);
LFG_UPDATE_EVENT:RegisterEvent("LFG_UPDATE");
local function eventHandler(self, event)
	local x,y = GetLFGMode(LE_LFG_CATEGORY_SCENARIO);
	--print ("LFG_UPDATE " .. tostring(x) .. " " .. tostring(y));
	if x == nil then
		Ahoy_WindowSwitch("Splashscreen");
		if Ahoy.IslandsMapOpen then
			if Ahoy.WindowClosedOutsideExpedition == false and Ahoy.WindowClosedDuringQueue == false then
				Ahoy_OpenMainframe()
			end
		else
			Ahoy_CloseMainframe()
		end
	end
	if x == "lfgparty" and Ahoy.CorrectlyQueued then
		---- Entered Island ----
		if Ahoy_Settings_New.Toggle_AutoShowAhoyOnIsland == true then
			Ahoy_OpenMainframe()
		end
		Ahoy_WindowSwitch("Expedition");
		Ahoy.DoingIslandExpedition = true;
	end
end
LFG_UPDATE_EVENT:SetScript("OnEvent", eventHandler);


-- LFG QUEUE STATUS UPDATE
local LFG_QUEUE_STATUS_UPDATE_EVENT = CreateFrame("FRAME", UIParent);
LFG_QUEUE_STATUS_UPDATE_EVENT:RegisterEvent("LFG_QUEUE_STATUS_UPDATE");
local function eventHandler(self, event)
	local x,y = GetLFGMode(LE_LFG_CATEGORY_SCENARIO);
	--print ("LFG_QUEUE_STATUS_UPDATE " .. tostring(x) .. " " .. tostring(y));
	if x == "queued" and Ahoy_VerifyCorrectQueue() then
		Ahoy.InQueue = true;
		Ahoy.CorrectlyQueued = true;
		Ahoy_WindowSwitch("Queue");
		if Ahoy_Settings_New.Toggle_AutoShowAhoyOnMissionTable == true then
			if Ahoy.WindowClosedOutsideExpedition == false and Ahoy.WindowClosedDuringQueue == false then
				Ahoy_OpenMainframe()
			end
		end
		AhoyResetVariables()
	else
		Ahoy.InQueue = false;
		Ahoy.WindowClosedDuringQueue = false;
		if Ahoy.IslandsMapOpen == true then
			Ahoy_WindowSwitch("Splashscreen");
		end
	end
end
LFG_QUEUE_STATUS_UPDATE_EVENT:SetScript("OnEvent", eventHandler);

--ISLANDS_QUEUE_OPEN
local ISLANDS_QUEUE_OPEN_EVENT = CreateFrame("FRAME", UIParent);
ISLANDS_QUEUE_OPEN_EVENT:RegisterEvent("ISLANDS_QUEUE_OPEN");
local function eventHandler(self, event)
	if Ahoy_Settings_New.Toggle_AutoShowAhoyOnMissionTable == true then
		Ahoy_OpenMainframe()
	end
	Ahoy.IslandsMapOpen = true;
	Ahoy.WindowClosedOutsideExpedition = false;
	Ahoy.WindowClosedDuringQueue = false;
	local x,y = GetLFGMode(LE_LFG_CATEGORY_SCENARIO);
	if x == "queued" then
		Ahoy_WindowSwitch("Queue");
		Ahoy.InQueue = true;
	else
		Ahoy_WindowSwitch("Splashscreen");
		Ahoy.InQueue = false;
		Ahoy.WindowClosedDuringQueue = false;
	end
end
ISLANDS_QUEUE_OPEN_EVENT:SetScript("OnEvent", eventHandler);

--ISLANDS_QUEUE_CLOSE
local ISLANDS_QUEUE_CLOSE_EVENT = CreateFrame("FRAME", UIParent);
ISLANDS_QUEUE_CLOSE_EVENT:RegisterEvent("ISLANDS_QUEUE_CLOSE");
local function eventHandler(self, event)
	local x,y = GetLFGMode(LE_LFG_CATEGORY_SCENARIO);
	if x == "queued" then
		Ahoy.IslandsMapOpen = true;
		Ahoy_WindowSwitch("Queue");
	else
		Ahoy.IslandsMapOpen = false;
		Ahoy_CloseMainframe()
	end
end
ISLANDS_QUEUE_CLOSE_EVENT:SetScript("OnEvent", eventHandler);

--GROUP_LEFT
local GROUP_LEFT_EVENT = CreateFrame("FRAME", UIParent);
GROUP_LEFT_EVENT:RegisterEvent("GROUP_LEFT");
local function eventHandler(self, event)
	if Ahoy.DoingIslandExpedition == true then
		Ahoy.DoingIslandExpedition = false;
	end
end
GROUP_LEFT_EVENT:SetScript("OnEvent", eventHandler);


-- Finish Expedition --
local LFG_COMPLETION_REWARD_EVENT = CreateFrame("FRAME", UIParent);
LFG_COMPLETION_REWARD_EVENT:RegisterEvent("LFG_COMPLETION_REWARD");
local function eventHandler(self, event)
	if Ahoy.DoingIslandExpedition == true then
		Ahoy.DoingIslandExpedition = false;
		if Ahoy_Settings_New.Toggle_ShowRewards == true then
			Ahoy__wait(1,Ahoy_LoadRewards);
		end
	end
end
LFG_COMPLETION_REWARD_EVENT:SetScript("OnEvent", eventHandler);

-- LFG Completion Reward --
local FINISHED_EXPEDITION_EVENT = CreateFrame("FRAME", UIParent);
FINISHED_EXPEDITION_EVENT:RegisterEvent("ISLAND_COMPLETED");
local function eventHandler(self, event, mapID, winner)
	if Ahoy_Settings_New.Toggle_ShowRewards == true then
		Ahoy_WindowSwitch("Rewards");
		Ahoy.CorrectlyQueued = false;
	end
end
FINISHED_EXPEDITION_EVENT:SetScript("OnEvent", eventHandler);

-- Player Targeted Mob --
local function Ahoy_MobTargeted()
	local guid = UnitGUID("target")
	if guid ~= nil then
		Ahoy_SelectedCreature(guid);
	end
end

local PLAYER_TARGET_CHANGED_EVENT = CreateFrame("FRAME", UIParent);
PLAYER_TARGET_CHANGED_EVENT:RegisterEvent("PLAYER_TARGET_CHANGED");
local function eventHandler(self, event, mapID, winner)
	if Ahoy.DoingIslandExpedition == true then
		if Ahoy_Settings_New.Toggle_MobTargetLootDisplay == true then
			Ahoy_MobTargeted()
		end
	end
end
PLAYER_TARGET_CHANGED_EVENT:SetScript("OnEvent", eventHandler);

-- Mouse Over --
local UPDATE_MOUSEOVER_UNIT_EVENT = CreateFrame("FRAME", UIParent);
UPDATE_MOUSEOVER_UNIT_EVENT:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
local function eventHandler(self, event, ...)
	if Ahoy.DoingIslandExpedition then
		local guid, name = UnitGUID("mouseover"), UnitName("mouseover")
		local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-",guid);
		if type == "Creature" or type == "Vehicle" then
			if Ahoy_Settings_New.DEBUGMODE == true then
				GameTooltip:AddLine("NPC ID: " .. npc_id);
				if AhoyCreatureDB[tonumber(npc_id)] == nil then
					if Ahoy.DEBUG_MissingNPCs[npc_id] == nil then
						print("DEBUG: Missing NPC: " .. npc_id .. " " .. name);
						Ahoy.DEBUG_MissingNPCs[npc_id] = true;
						if Ahoy_CollectedData_New.MissingNPCs == nil then
							Ahoy_CollectedData_New.MissingNPCs = {}
						end
						if Ahoy_CollectedData_New.MissingNPCs[npc_id] == nil then
							Ahoy_CollectedData_New.MissingNPCs[npc_id] = name .. "|" .. guid;
							Ahoy_CollectedData = Ahoy_CollectedData_New 
						end
					end
				end
			end
			npcRaw = AhoyCreatureDB[tonumber(npc_id)];
			if npcRaw ~= nil then
				npcData = splits(npcRaw,"|");
				if Ahoy_Settings_New.Toggle_MobMouseOverCategory == true then
					GameTooltip:AddLine("Ahoy: " .. npcData[4], 1, 1, 1)
				end
				if Ahoy_Settings_New.Toggle_MobTooltipLootDisplay == true then
					if AhoyItemDB[npcData[4]] ~= nil then
						GameTooltip:AddLine("Potential Rewards", 1, 1, 1)
						local itemEntriesNumber = getn(AhoyItemDB[npcData[4]]);
						for i = 1, itemEntriesNumber, 1 do
							local itemLink = AhoyItemDB[npcData[4]][i];
							if Ahoy_Settings_New.ShowCollected == false then
								if Ahoy_CheckItemCollected(itemLink) == false then
									GameTooltip:AddLine(itemLink, 1, 1, 1)
								end
							else
								GameTooltip:AddLine(itemLink, 1, 1, 1)
							end
						end
					end
				end
			end
			GameTooltip:Show()
		end
	end
end
UPDATE_MOUSEOVER_UNIT_EVENT:SetScript("OnEvent", eventHandler);

-- Azerite Gain --
local AHOY_AZERITE_GAIN_EVENT = CreateFrame("FRAME", UIParent);
AHOY_AZERITE_GAIN_EVENT:RegisterEvent("ISLAND_AZERITE_GAIN");
local function eventHandler(self, event, amount, gainedByPlayer, factionIndex, gainedBy, gainedFrom)
	if Ahoy.DoingIslandExpedition then
		Ahoy_AzeriteGain(gainedFrom, amount);
		if Ahoy_Settings_New.FlashCards == true then
			Ahoy_UpdateFlashScore(amount);
		end
	end
end
AHOY_AZERITE_GAIN_EVENT:SetScript("OnEvent", eventHandler);

-- Variables loaded event --
local AHOY_LOGIN_EVENT = CreateFrame("Frame","VARIABLES_LOADED",UIParent)
AHOY_LOGIN_EVENT:RegisterEvent("VARIABLES_LOADED");
AHOY_LOGIN_EVENT:SetScript("OnEvent",
function(self,event,...)
	if event=="VARIABLES_LOADED" then
		Ahoy_LoadSettings()
		Ahoy_SetToggleDefaults()
		Ahoy_MoveToSavedPosition()
		Ahoy_BuildCollectedMountsTable()
		Ahoy__wait(0.5, Ahoy_MinimapButton_Toggle)
		Ahoy.MainFrame:SetScale(Ahoy_Settings_New.WindowScale);
		if Ahoy_Settings_New.WindowLocked then
		-- change icon to locked
		MenuItem6Frame.background:SetTexCoord(0.69, 0.79, 0.122, 0.22)
		else
		-- change icon to unlocked
		MenuItem6Frame.background:SetTexCoord(0.69, 0.79, 0.235, 0.335)
		Ahoy_WorldMapInitialize()
		Ahoy_CheckZone()
		Ahoy_UpdateMap( false )
		Ahoy_Load_CollectedData()
		Ahoy_VerifyNewlyAddedMissingNPCs()
		end
	end
end)

local function tContains(table, item)
       local index = 1;
       while table[index] do
               if ( item == table[index] ) then
                       return 1;
               end
               index = index + 1;
       end
       return nil;
end

--[[
eventsLog = {}
local ALLEVENTS_DEBUG = CreateFrame("FRAME", UIParent);
ALLEVENTS_DEBUG:RegisterAllEvents();
local function eventHandler(self, event)
	if tContains(eventsLog, event) == nil then
		print (event);
		tinsert(eventsLog,event)
	end
end
ALLEVENTS_DEBUG:SetScript("OnEvent", eventHandler);
--]]

----------------------------------------------------------
--	Chat Commands										--
----------------------------------------------------------

local function AhoyChatCommands(msg, editbox)
	local split1, split2 = strsplit(" ",msg);
	if msg == "on" then
		Ahoy_OpenMainframe();
	elseif msg == "off" then
		Ahoy_CloseMainframe();
	elseif msg == "reset" then
		Ahoy_ResetMainframePosition();
	else
		if split1 == "scale" then
			if split2 ~= nil then
				Ahoy.MainFrame:SetScale(tonumber(split2));
				Ahoy_Settings_New.WindowScale = newScale;
				Ahoy_Settings = Ahoy_Settings_New;
			else
				print ("Wrong Scale number.");
			end
		else
			print ("Welcome to Ahoy v" .. Ahoy.Version);
			print ("--------------------------------");
			print ("/ahoy on (shows the window)");
			print ("/ahoy off (hides the window)");
			print ("/ahoy reset (moves the window back to the center, in case you lost it)");
			print ("/ahoy scale # (manually scale the window, replace # with a number, default is 1)");
		end
	end
end
SLASH_AHOY1 = "/ahoy";
SlashCmdList["AHOY"] = AhoyChatCommands;

--------------------------------------
--	DEBUG							--
--------------------------------------