local Amilus = CreateFrame("Frame")
Amilus:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
Amilus:RegisterEvent("PLAYER_ENTERING_WORLD") 

local Corruptions = {
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
    
    --["4928"] = {"Test", "", 0},
}
local realmName
Amilus:SetScript("OnEvent", function(self, event, ...)
	if event=="ITEM_SEARCH_RESULTS_UPDATED" then 
		Amilus:ResultUpdate()
	end
	realmName = GetRealmName();
	if event=="PLAYER_ENTERING_WORLD" then
	Amilus_DB[realmName] = {}; 
	end
end)




local ticker 
function Amilus:ResultUpdate() 
	 if ticker then ticker:Cancel() end 
        ticker = C_Timer.NewTicker(0.1, processRows)
end
function  processRows()
    for rowIndex,row in pairs(AuctionHouseFrame.ItemBuyFrame.ItemList.tableBuilder.rows) do 
        if not row.corruption then  
            Amilus:createCorruption(row)   
        end             
			Amilus:rowUpdate(row)                                
    end    
end
function Amilus:createCorruption(row)
    row.corruption = row:CreateFontString(nil,"OVERLAY","GameFontNormal")
    local font,size,flags = row.corruption:GetFont()
    row.corruption:SetFont(font,12,flags)
    row.corruption:SetTextColor(149/255,109/255,201/255)
    row.corruption:SetPoint("LEFT",row, 300, 0);
    row.corruption:Hide()
    row.corruption:SetText("")
end
function Amilus:rowUpdate(row)
    if row and row.rowData then 
        local data = row.rowData
        --local itemIds = {strsplit(":", string.match(data.itemLink, "item:%d([:%d]+)"))}
		local bonusIDs = Amilus:GetbonusIDs(data.itemLink)
		local name, link, qa, level= GetItemInfo(data.itemLink)
		local corruptionRank =Amilus:GetCorruption(bonusIDs)
		if not Amilus_DB[realmName][name] then Amilus_DB[realmName][name]={} end
		if corruptionRank then  
			--local data= {corruptionRank[1],level,data.buyoutAmount}
			--table.insert(Amilus_DB[realmName][name],data)
			row.corruption:SetText(corruptionRank[1]) 
            row.corruption:Show()  
		else
            row.corruption:SetText("")
            row.corruption:Hide()			
		end
             
    end           
end
function Amilus:GetbonusIDs(itemLink)
	local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
		linkLevel, specializationID, upgradeId, instanceDifficultyId , numBonusIds, affixes = strsplit(":", string.match(itemLink, "item:%d([:%d]+)"),15)
		 
	local b = tonumber(numBonusIds) or 0
	local bonusIDs = bonusIDs or {}
	table.wipe(bonusIDs)
	if b then
		for i = 1, b do
			local bonusID = select(i, strsplit(":", affixes))
				table.insert(bonusIDs, bonusID)
		end
	end
	return bonusIDs
end
 function Amilus:GetCorruption(bonuses)
    if #bonuses > 0 then
        for i, bonus_id in pairs(bonuses) do
            bonus_id = tostring(bonus_id)
            if Corruptions[bonus_id] ~= nil then
                local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(Corruptions[bonus_id][3])
                if Corruptions[bonus_id][2] ~= "" then
                    rank = Corruptions[bonus_id][2]
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
--------------------------------------------------------------------

