 
-- Addon 
local wf = CreateFrame("Frame");  
--插件配置
local keymsg = "123"
local second = 5 --密语间隔秒数 超过2次触发
local startBlack = 0 --开启黑名单功能 0:关闭 1:开启


local pr ;
wf:RegisterEvent("ADDON_LOADED");
wf:RegisterEvent("PLAYER_LOGOUT");
wf:RegisterEvent("PLAYER_ENTERING_WORLD") 
function wf:OnEvent(event, arg1)
    wf.SetupNameInfo();
	if (addon ~= modName) then
		return;
	end
	if (not WhisperFirewall_DB) then
		WhisperFirewall_DB = {};
	end 
end
wf:SetScript("OnEvent", wf.OnEvent);
wf.SetupNameInfo = function()
	playerName = UnitName("player");
	realmName = GetRealmName();
	 pr= playerName .. "-" .. realmName
end
 
function MsgFilter_Item( self, event, msg, author, ... ) 
    local t = time()
	if (not WhisperFirewall_DB[author]) then 
		local initdata ={}
		initdata.count = 0
		initdata.pcount = 0
		initdata.last =t
		initdata.name = author
		WhisperFirewall_DB[author] = initdata 
	end     
	
	local newdata = WhisperFirewall_DB[author]
  
	if msg==keymsg and  tonumber(newdata.last) < tonumber(t)  then
		timediff =  (t - newdata.last)/1
		if timediff >= second then 
			newdata.pcount  = 1
		else 
			newdata.pcount  = tonumber(newdata.pcount) + 1 
		end
		newdata.count = tonumber(newdata.count) + 1
		newdata.last = t
		newdata.name = author
		WhisperFirewall_DB[author] = newdata
		
		if newdata.pcount>2 or (startBlack==1 and newdata.black==1) then
			WhisperFirewall_DB[author].black = 1
			return true
		else 
			InviteUnit(author)
		end
	end
	
	
end

  
 
 
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", MsgFilter_Item) 
 
 
function SlashCmdList.WhisperFirewall(msg) 
	wf:AddWin() 
end
SLASH_WhisperFirewall1 = '/whisperfirewall'
SLASH_WhisperFirewall2 = '/wf'



function wf:AddWin()
    local frame, button  
    frame = CreateFrame("Frame", "lhFrame", UIParent, "UIPanelDialogTemplate")
    frame.Title:SetTextColor(1,1,1)
	frame.Title:SetText("Whisper Firewall")
    frame:SetWidth(600)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
	frame:SetPoint("TOP", 0, -200)  
    local index = 1
	wf:addHeaderLine(frame)  
	 
	
	
    for k, v in pairs(wf:tableSort(WhisperFirewall_DB)) do 
		if index<=30 and (v.black == 1 or startBlack==0)  then   
				local entry = CreateFrame("Frame", nil, frame)
				entry:SetWidth(480) 
				entry:SetHeight(20) 
				entry:SetPoint("TOP",   0, -50-index*20) 
				wf:addTextLine(entry,k ,v)
 
				index = index + 1 
		end
	end
	
	
    frame:SetHeight(80+index*20) 
    frame:Show()
    
end

function wf:addHeaderLine(parentframe)
	local frame = CreateFrame("Frame", nil, parentframe)
	frame:SetWidth(480) 
	frame:SetHeight(20) 
	frame:SetPoint("TOP",   0, -40)

	local txtName = CreateFrame("Frame",nil,frame)
	txtName:SetWidth(150)
	txtName:SetHeight(20)
	txtName:SetPoint("LEFT",   0, 0)
	txtName.Text = txtName:CreateFontString(nil, "OVERLAY") 
	txtName.Text:SetFont("Fonts\\1ZYHei.ttf", 14, "THINOUTLINE")
	txtName.Text:SetText("角色名") 
	txtName.Text:SetPoint("CENTER", txtName, "CENTER", 0, 0)
	
	local txtCount= CreateFrame("Frame",nil,frame)
	txtCount:SetWidth(100) 
	txtCount:SetHeight(20) 
	txtCount:SetPoint("LEFT", 150, 0)
	txtCount.Text = txtCount:CreateFontString(nil, "OVERLAY") 
	txtCount.Text:SetFont("Fonts\\1ZYHei.ttf", 14, "THINOUTLINE") 
	txtCount.Text:SetText("次数") 
	txtCount.Text:SetPoint("CENTER", txtCount, "CENTER", 0, 0)
	
 
	local txtTime= CreateFrame("Frame",nil,frame)
	txtTime:SetWidth(150)
	txtTime:SetHeight(20)  
	txtTime:SetPoint("LEFT", 250, 0)
	txtTime.Text = txtTime:CreateFontString(nil, "OVERLAY")
	txtTime.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") 
	txtTime.Text:SetText("最后时间") 
	txtTime.Text:SetPoint("CENTER", txtTime, "CENTER", 0, 0)
 
 
	
	local delButton= CreateFrame("Button",nil,frame, "UIPanelCloseButton")
	delButton:SetWidth(24) 
	delButton:SetHeight(24)
	delButton:SetPoint("LEFT", 400, 0)
	delButton.Text = delButton:CreateFontString(nil, "OVERLAY") 
	delButton.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE")
	delButton.Text:SetText("清空数据") 
	delButton.Text:SetPoint("LEFT", delButton, "LEFT", 24, 0)
	delButton:SetScript("OnClick", function()
		WhisperFirewall_DB={}
	end)

end

 

function wf:addTextLine(frame,k,v)

	local txtName = CreateFrame("Frame",nil,frame)
	txtName:SetWidth(150) 
	txtName:SetHeight(20)  
	txtName:SetPoint("LEFT",   0, 0)
	txtName.Text = txtName:CreateFontString(nil, "OVERLAY")
	txtName.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE")
	txtName.Text:SetText(v.name) 
	txtName.Text:SetPoint("CENTER", txtName, "CENTER", 0, 0)
	
	
 
	
	
	local txtCount= CreateFrame("Frame",nil,frame)
	txtCount:SetWidth(100) 
	txtCount:SetHeight(20)  
	txtCount:SetPoint("LEFT", 150, 0)
	txtCount.Text = txtCount:CreateFontString(nil, "OVERLAY") 
	txtCount.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") 
	txtCount.Text:SetText(v.count)
	txtCount.Text:SetPoint("CENTER", txtCount, "CENTER", 0, 0)


 
 
	local txtTime= CreateFrame("Frame",nil,frame)
	txtTime:SetWidth(150) 
	txtTime:SetHeight(20) 
	txtTime:SetPoint("LEFT", 250, 0)
	txtTime.Text = txtTime:CreateFontString(nil, "OVERLAY")
	txtTime.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") 
	txtTime.Text:SetText(date("%m-%d %H:%M:%S",v.last)) 
	txtTime.Text:SetPoint("CENTER", txtTime, "CENTER", 0, 0)


	local delButton= CreateFrame("Button",nil,frame)
	delButton:SetWidth(200) 
	delButton:SetHeight(24)
	delButton:SetPoint("LEFT", 400, 0)
	delButton.Text = delButton:CreateFontString(nil, "OVERLAY") 
	delButton.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE")
	delButton.Text:SetText("移出黑名单") 
	delButton.Text:SetPoint("LEFT", delButton, "LEFT", 24, 0)
	delButton:SetScript("OnClick", function()
		 WhisperFirewall_DB[v.name].black=0
		 frame:Hide()
		 
	end)
	 
end
 
function wf:tableSort(pretable)

	--for i in pairs(LootHistory_DB[pr]) do
		--print("直接输出："..i)
	--end
	local keyTest ={}
	for i in pairs(pretable) do
		table.insert(keyTest,i)  
	end
	table.sort(keyTest,function(a,b) return (tonumber(pretable[a].count) > tonumber(pretable[b].count)) end)  
	local result = { }
	for i,v in pairs(keyTest) do
		table.insert(result,pretable[v])
		--print("id："..v.."     data："..LootHistory_DB[pr][v].time)
	end
	--pretable = result
	return result
end




