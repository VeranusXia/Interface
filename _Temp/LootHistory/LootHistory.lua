 
-- Addon 
local lh = CreateFrame("Frame");  
local pr ;
lh:RegisterEvent("ADDON_LOADED");
lh:RegisterEvent("PLAYER_LOGOUT");
lh:RegisterEvent("PLAYER_ENTERING_WORLD") 


local R = {
    ["6455"] = {"Avoidant", "I", 315607},
    ["6483"] = {"Avoidant", "I", 315607},
    ["6460"] = {"Avoidant", "II", 315608},
    ["6484"] = {"Avoidant", "II", 315608},
    ["6465"] = {"Avoidant", "III", 315609},
    ["6485"] = {"Avoidant", "III", 315609},
    ["6455"] = {"Expedient", "I", 315544},
    ["6474"] = {"Expedient", "I", 315544},
    ["6460"] = {"Expedient", "II", 315545},
    ["6475"] = {"Expedient", "II", 315545},
    ["6465"] = {"Expedient", "III", 315546},
    ["6476"] = {"Expedient", "III", 315546},
    ["6455"] = {"Masterful", "I", 315529},
    ["6471"] = {"Masterful", "I", 315529},
    ["6460"] = {"Masterful", "II", 315530},
    ["6472"] = {"Masterful", "II", 315530},
    ["6465"] = {"Masterful", "III", 315531},
    ["6473"] = {"Masterful", "III", 315531},
    ["6455"] = {"Severe", "I", 315554},
    ["6480"] = {"Severe", "I", 315554},
    ["6460"] = {"Severe", "II", 315557},
    ["6481"] = {"Severe", "II", 315557},
    ["6465"] = {"Severe", "III", 315558},
    ["6482"] = {"Severe", "III", 315558},
    ["6455"] = {"Versatile", "I", 315549},
    ["6477"] = {"Versatile", "I", 315549},
    ["6460"] = {"Versatile", "II", 315552},
    ["6478"] = {"Versatile", "II", 315552},
    ["6465"] = {"Versatile", "III", 315553},
    ["6479"] = {"Versatile", "III", 315553},
    ["6455"] = {"Siphoner", "I", 315590},
    ["6493"] = {"Siphoner", "I", 315590},
    ["6460"] = {"Siphoner", "II", 315591},
    ["6494"] = {"Siphoner", "II", 315591},
    ["6465"] = {"Siphoner", "III", 315592},
    ["6495"] = {"Siphoner", "III", 315592},
    ["6455"] = {"Strikethrough", "I", 315277},
    ["6437"] = {"Strikethrough", "I", 315277},
    ["6460"] = {"Strikethrough", "II", 315281},
    ["6438"] = {"Strikethrough", "II", 315281},
    ["6465"] = {"Strikethrough", "III", 315282},
    ["6439"] = {"Strikethrough", "III", 315282},
    ["6555"] = {"Racing Pulse", "I", 318266},
    ["6559"] = {"Racing Pulse", "II", 318492},
    ["6560"] = {"Racing Pulse", "III", 318496},
    ["6556"] = {"Deadly Momentum", "I", 318268},
    ["6561"] = {"Deadly Momentum", "II", 318493},
    ["6562"] = {"Deadly Momentum", "III", 318497},
    ["6558"] = {"Surging Vitality", "I", 318270},
    ["6565"] = {"Surging Vitality", "II", 318495},
    ["6566"] = {"Surging Vitality", "III", 318499},
    ["6557"] = {"Honed Mind", "I", 318269},
    ["6563"] = {"Honed Mind", "II", 318494},
    ["6564"] = {"Honed Mind", "III", 318498},
    ["6549"] = {"Echoing Void", "I", 318280},
    ["6550"] = {"Echoing Void", "II", 318485},
    ["6551"] = {"Echoing Void", "III", 318486},
    ["6552"] = {"Infinite Stars", "I", 318274},
    ["6553"] = {"Infinite Stars", "II", 318487},
    ["6554"] = {"Infinite Stars", "III", 318488},
    ["6547"] = {"Ineffable Truth", "I", 318303},
    ["6548"] = {"Ineffable Truth", "II", 318484},
    ["6537"] = {"Twilight Devastation", "I", 318276},
    ["6538"] = {"Twilight Devastation", "II", 318477},
    ["6539"] = {"Twilight Devastation", "III", 318478},
    ["6543"] = {"Twisted Appendage", "I", 318481},
    ["6544"] = {"Twisted Appendage", "II", 318482},
    ["6545"] = {"Twisted Appendage", "III", 318483},
    ["6540"] = {"Void Ritual", "I", 318286},
    ["6541"] = {"Void Ritual", "II", 318479},
    ["6542"] = {"Void Ritual", "III", 318480},
    ["6573"] = {"Gushing Wound", "", 318272},
    ["6546"] = {"Glimpse of Clarity", "", 318239},
    ["6571"] = {"Searing Flames", "", 318293},
    ["6572"] = {"Obsidian Skin", "", 316651},
    ["6567"] = {"Devour Vitality", "", 318294},
    ["6568"] = {"Whispered Truths", "", 316780},
    ["6570"] = {"Flash of Insight", "", 318299},
    ["6569"] = {"Lash of the Void", "", 317290},
}



function lh:OnEvent(event, arg1)
    lh.SetupNameInfo();
	if (addon ~= modName) then
		return;
	end
	if (not LootHistory_DB) then
		LootHistory_DB = {};
	end 
	
	if (not LootHistory_DB[pr]) then
		LootHistory_DB[pr] = {};
	end  
end
lh:SetScript("OnEvent", lh.OnEvent);
lh.SetupNameInfo = function()
	playerName = UnitName("player");
	realmName = GetRealmName();
	 pr= playerName .. "-" .. realmName
end
 
function MsgFilter_Item( self, event, arg1,sender, ... )
	if sender==pr then 
		local name, link, qa, level, needlevel, itemType= GetItemInfo(arg1)

		if (itemType ==ARMOR  or itemType == WEAPON   ) and qa>=3 and needlevel>=120 and level>300 then 
			 
			local itemString = string.match(arg1, "item[%-?%d:]+")
	 
			local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
			linkLevel, specializationID, upgradeId, instanceDifficultyId , numBonusIds  = strsplit(":", itemString)
	  
			local data = {}
			local t = time()
			data.item=itemString
			data.time=t
			LootHistory_DB[pr][t..itemId] = data 

		end  
	end 
end

 
  
 
 
ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", MsgFilter_Item) 
 
function SlashCmdList.LootHistory(msg)
	lh:AddWin() 

end
SLASH_LootHistory1 = '/loothistory'
SLASH_LootHistory2 = '/lh'



function lh:AddWin()
    local frame, button  
    frame = CreateFrame("Frame", "lhFrame", UIParent, "UIPanelDialogTemplate")
    frame.Title:SetTextColor(1,1,1)
	frame.Title:SetText("Loot History")
    frame:SetWidth(700)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
	frame:SetPoint("TOP", 0, -200)  
    local index = 1
	lh:addHeaderLine(frame) 
	local now=time()
	 
	
	
    for k, v in pairs(lh:tableSort(LootHistory_DB[pr])) do
		local timediff = (now - v.time)/3600  
		local name, link, qa, level, needlevel, itemType= GetItemInfo(v.item)
		
		  
	 
		local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
		linkLevel, specializationID, upgradeId, instanceDifficultyId , numBonusIds, affixes = strsplit(":", v.item,15)
		  
		
		if index<=24  then --and timediff<=168
			if (itemType ==ARMOR  or itemType == WEAPON   ) and qa==4 and needlevel>=120 and level>300 then 
			
		
			
			
				local entry = CreateFrame("Frame", nil, frame)
				entry:SetWidth(580) -- 设置宽度
				entry:SetHeight(20) -- 设置高度 
				entry:SetPoint("TOP",   0, -50-index*20)
 
				local itemstats	= GetItemStats(link)
 
				 
				local socket = itemstats["EMPTY_SOCKET_PRISMATIC"] or 0; 
				local speed = itemstats["ITEM_MOD_CR_SPEED_SHORT"] or 0; 
				local lifesteal = itemstats["ITEM_MOD_CR_LIFESTEAL_SHORT"] or 0; 
				local avoidance = itemstats["ITEM_MOD_CR_AVOIDANCE_SHORT"] or 0; 
				local studriness = itemstats["ITEM_MOD_CR_STURDINESS_SHORT"] or 0; 
				local corruption = itemstats["ITEM_MOD_CORRUPTION"] or 0;  
		   
		
				local cr= ""
		

				local ilv = 0
		 

				
				
				local b = tonumber(numBonusIds) or 0
				 local bonusIDs = bonusIDs or {}
				 table.wipe(bonusIDs)

				if b then
					for i = 1, b do
						local bonusID = select(i, strsplit(":", affixes))
						table.insert(bonusIDs, bonusID)
					end
					
				end
				 if b>=4 then
					ilv = tonumber(bonusIDs[b-1])-5845
					if bonusIDs[b] =="4783" then
						if bonusIDs[b-1] =="5850" then cr=cr.."+"..ilv.."战火 " end
						if bonusIDs[b-1] =="5855" then  cr=cr.."+"..ilv.."战火 " end
					end
					if bonusIDs[b] =="4784" then 
						cr=cr.."+"..ilv.."泰坦 " 
					end 
				end
				
				local corruptionRank = lh:GetCorruption(bonusIDs)
				if corruptionRank then  cr=cr..corruptionRank[1].." " end
				if corruption>0 then  cr=cr..corruption.."腐蚀 " end
		
		
				if socket>0 then cr=cr.."插槽 " end
				if speed>0 then cr=cr.."加速 " end
				if lifesteal>0 then cr=cr.."吸血 " end
				if avoidance>0 then cr=cr.."闪避 " end
				if studriness>0 then cr=cr.."永不磨损 " end
 
 
 
 
 
				lh:addTextLine(entry,v.time,level,link,cr)
 
				index = index + 1
			end
		end
	end
	
    frame:SetHeight(80+index*20) 
     frame:Show()
    
end


function lh:GetCorruption(bonuses)
    if #bonuses > 0 then
        for i, bonus_id in pairs(bonuses) do
            bonus_id = tostring(bonus_id)
            if R[bonus_id] ~= nil then
                local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(R[bonus_id][3])
                if R[bonus_id][2] ~= "" then
                    rank = R[bonus_id][2]
                else
                    rank = ""
                end 
                return {
                    name..rank,
                    icon,
                }
            end
        end
    end
end

function lh:addHeaderLine(parentframe)
	local frame = CreateFrame("Frame", nil, parentframe)
	frame:SetWidth(580) -- 设置宽度
	frame:SetHeight(20) -- 设置高度 
	frame:SetPoint("TOP",   0, -40)

	local txtTime = CreateFrame("Frame",nil,frame)
	txtTime:SetWidth(150) -- 设置宽度
	txtTime:SetHeight(20) -- 设置高度 
	txtTime:SetPoint("LEFT",   0, 0)
	txtTime.Text = txtTime:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtTime.Text:SetFont("Fonts\\1ZYHei.ttf", 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtTime.Text:SetText("时间") -- 设置材质路径 
	txtTime.Text:SetPoint("CENTER", txtTime, "CENTER", 0, 0)
	
	local txtLink= CreateFrame("Frame",nil,frame)
	txtLink:SetWidth(150) -- 设置宽度
	txtLink:SetHeight(20) -- 设置高度 
	txtLink:SetPoint("LEFT", 150, 0)
	txtLink.Text = txtLink:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtLink.Text:SetFont("Fonts\\1ZYHei.ttf", 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtLink.Text:SetText("装备") -- 设置材质路径 
	txtLink.Text:SetPoint("CENTER", txtLink, "CENTER", 0, 0)
	
	local txtLevel= CreateFrame("Frame",nil,frame)
	txtLevel:SetWidth(100) -- 设置宽度
	txtLevel:SetHeight(20) -- 设置高度 
	txtLevel:SetPoint("LEFT", 300, 0)
	txtLevel.Text = txtLevel:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtLevel.Text:SetFont("Fonts\\1ZYHei.ttf", 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtLevel.Text:SetText("装等") -- 设置材质路径 
	txtLevel.Text:SetPoint("CENTER", txtLevel, "CENTER", 0, 0)
	 
	
	local delButton= CreateFrame("Button",nil,frame, "UIPanelCloseButton")
	delButton:SetWidth(24) -- 设置宽度
	delButton:SetHeight(24) -- 设置高度 
	delButton:SetPoint("LEFT", 500, 0)
	delButton.Text = delButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	delButton.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	delButton.Text:SetText("清空数据") -- 设置材质路径 
	delButton.Text:SetPoint("LEFT", delButton, "LEFT", 24, 0)
	delButton:SetScript("OnClick", function()
		LootHistory_DB[pr]={}
	end)

end

 

function lh:addTextLine(frame,vt,level,link,cr)

	local txtTime = CreateFrame("Frame",nil,frame)
	txtTime:SetWidth(150) -- 设置宽度
	txtTime:SetHeight(20) -- 设置高度 
	txtTime:SetPoint("LEFT",   0, 0)
	txtTime.Text = txtTime:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtTime.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtTime.Text:SetText(date("%m-%d %H:%M:%S",vt)) -- 设置材质路径 
	txtTime.Text:SetPoint("CENTER", txtTime, "CENTER", 0, 0)
	
	
	
	
	local txtLink= CreateFrame("Button",nil,frame)
	txtLink:SetWidth(150) -- 设置宽度
	txtLink:SetHeight(20) -- 设置高度 
	txtLink:SetPoint("LEFT", 150, 0)
	txtLink.Text = txtLink:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtLink.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtLink.Text:SetText(link) -- 设置材质路径 
	txtLink.Text:SetPoint("CENTER", txtLink, "CENTER", 0, 0)
    txtLink:SetScript("OnMouseUp", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
     end)
	txtLink:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
     end)
	txtLink:SetScript("OnLeave", function(self) 
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:Hide()
     end) 
	 
	
	
	local txtLevel= CreateFrame("Frame",nil,frame)
	txtLevel:SetWidth(100) -- 设置宽度
	txtLevel:SetHeight(20) -- 设置高度 
	txtLevel:SetPoint("LEFT", 300, 0)
	txtLevel.Text = txtLevel:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtLevel.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtLevel.Text:SetText(level) -- 设置材质路径 
	txtLevel.Text:SetPoint("CENTER", txtLevel, "CENTER", 0, 0)


 
 
		local txtCR= CreateFrame("Frame",nil,frame)
		txtCR:SetWidth(200) -- 设置宽度
		txtCR:SetHeight(20) -- 设置高度 
		txtCR:SetPoint("LEFT", 400, 0)
		txtCR.Text = txtCR:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
		txtCR.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
		txtCR.Text:SetText(cr) -- 设置材质路径 
		txtCR.Text:SetPoint("CENTER", txtCR, "CENTER", 0, 0)

	 
end
 
function lh:tableSort(pretable)

	--for i in pairs(LootHistory_DB[pr]) do
		--print("直接输出："..i)
	--end
	local keyTest ={}
	for i in pairs(pretable) do
		table.insert(keyTest,i)  
	end
	table.sort(keyTest,function(a,b)return (tonumber(a) > tonumber(b)) end)  
	local result = { }
	for i,v in pairs(keyTest) do
		table.insert(result,pretable[v])
		--print("id："..v.."     data："..LootHistory_DB[pr][v].time)
	end
	--pretable = result
	return result
end


