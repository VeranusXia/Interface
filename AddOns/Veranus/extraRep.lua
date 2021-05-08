local SR_REP_MSG = "%s(%d/%d)：%+d";
local SR_REP_MSG2 = "|cffee80ee%s(%d/巅峰)：%+d|r";
local SR_REP_MSG3 = "|cffff4500%s(%d/巅峰)：%+d，已满请兑换！|r";
local rep = {};
local extraRep = {};
local C_Reputation_IsFactionParagon = C_Reputation.IsFactionParagon
local function SR_Update()
	local numFactions = GetNumFactions(self);
	for i = 1, numFactions, 1 do
		local name, _, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(i);
		local value = 0;
		if barValue >= 42000 then
      local hasParagon = C_Reputation_IsFactionParagon(factionID)
      if hasParagon then
        initExtraRep(factionID,name)
        local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
        value = currentValue % threshold
        if hasRewardPending then 
          value = value + threshold
        end
        local extraChange = value - extraRep[name];
        if extraChange > 0 and value < 10000 then
          extraRep[name] = value
          local extra_msg = string.format(SR_REP_MSG2, name, value, extraChange)
          createMessage(extra_msg);
        end
        if extraChange ~= 0 and value > 10000 then
          extraRep[name] = value
          local extra_msg2 = string.format(SR_REP_MSG3, name, value, extraChange)
          createMessage(extra_msg2);
        end
      end
    elseif name and (not isHeader) or (hasRep) then
      if not rep[name] then
        rep[name] = barValue;
      end
      local change = barValue - rep[name];
      if (change > 0) then
        rep[name] = barValue
        local msg = string.format(SR_REP_MSG, name, barValue - barMin, barMax - barMin, change)
        createMessage(msg)
      end
    end
	end
end
function createMessage(msg)
  local info = ChatTypeInfo["COMBAT_FACTION_CHANGE"];
	for j = 1, 4, 1 do
    local chatfrm = getglobal("ChatFrame"..j);
    for k,v in pairs(chatfrm.messageTypeList) do
      if v == "COMBAT_FACTION_CHANGE" then
        chatfrm:AddMessage(msg, info.r, info.g, info.b, info.id);
        break;
      end
    end
  end
end

function initExtraRep(factionID, name)
  local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID);
  if not extraRep[name] then
		extraRep[name] = currentValue % threshold
		if hasRewardPending then
      extraRep[name] = extraRep[name] + threshold
    end
	end
	if extraRep[name] > threshold and (not hasRewardPending) then
    extraRep[name] = extraRep[name] - threshold
  end
end

local frame = CreateFrame("Frame");
frame:RegisterEvent("UPDATE_FACTION");
frame:SetScript("OnEvent", SR_Update);
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", function() return true; end);

local NUM_FACTIONS_DISPLAYED = NUM_FACTIONS_DISPLAYED
local REPUTATION_PROGRESS_FORMAT = REPUTATION_PROGRESS_FORMAT
hooksecurefunc("ReputationFrame_Update", function(self, elapsed)
	ReputationFrame.paragonFramesPool:ReleaseAll()
	local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame)
	for n=1,NUM_FACTIONS_DISPLAYED,1 do
		local factionIndex = factionOffset+n
		local factionRow = _G["ReputationBar"..n]
		local factionBar = _G["ReputationBar"..n.."ReputationBar"]
		local factionStanding = _G["ReputationBar"..n.."ReputationBarFactionStanding"]
		if factionIndex <= GetNumFactions() then
			local name,_,_,_,_,_,_,_,_,_,_,_,_,factionID = GetFactionInfo(factionIndex)
			if factionID and C_Reputation.IsFactionParagon(factionID) then
				local currentValue,threshold,rewardQuestID,hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
				factionRow.questID = rewardQuestID
				if currentValue then
					local count = floor(currentValue/threshold)
					local value = currentValue - count*10000
				    if hasRewardPending then count = count-1 end
					if hasRewardPending then
						local paragonFrame = ReputationFrame.paragonFramesPool:Acquire()
						paragonFrame.factionID = factionID
						paragonFrame:SetPoint("RIGHT",factionRow,11,0)
						paragonFrame.Glow:SetShown(true)
						paragonFrame.Check:SetShown(true)
						paragonFrame:Show()
						value = value+threshold
					end
					factionBar:SetMinMaxValues(0,threshold)
					factionBar:SetValue(value)
					factionRow.rolloverText = format(REPUTATION_PROGRESS_FORMAT,BreakUpLargeNumbers(value),BreakUpLargeNumbers(threshold))
						factionStanding:SetText(" "..BreakUpLargeNumbers(value).."/".."巅峰("..count..")")
						factionRow.standingText = (" "..BreakUpLargeNumbers(value).."/".."巅峰("..count..")")
						factionRow.rolloverText = nil					
					if factionIndex == GetSelectedFaction() and ReputationDetailFrame:IsShown() then
						if count > 0 then
							ReputationDetailFactionName:SetText(name.."\n|cff00ff00(已开"..count.."个巅峰箱子)|r")
						end
					end
				end
			else
				factionRow.questID = nil
			end
		else
			factionRow:Hide()
		end
	end
end)