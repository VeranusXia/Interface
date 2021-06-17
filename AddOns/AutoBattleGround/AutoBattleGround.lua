 
local start = false  
local step = 0
local oldtime = nil

local groupassistantnumMin_config = 5   --最小A的数量 小于等于
local groupassistantnumMax_config = 9  --最大A的数量 小于等于
local groupmembersMin_config = 6   --最小团队人数 小于等于
local groupmembersMax_config = 9   --最大团队人数 小于等于
local difftime_config= 400  --等待秒数

local classSpell ={
	["WARRIOR"] = "/cast 死亡之愿\n/cast 血性狂暴\n",--Warrior 
	["PALADIN"] = "/targetfriendplayer\n/castsequence 殉道者之光,殉道者之光,神圣震击,殉道者之光,殉道者之光,神圣震击,殉道者之光,殉道者之光,神圣震击,殉道者之光,殉道者之光,神圣震击,正义盾击\n/cast [target=player]圣光道标\n",--Paladin
	["HUNTER"] = "/cast [nopet]召唤宠物 3\n/cast 意气风发\n", --Hunter
	["ROGUE"] = "/cast 猩红之瓶\n/cast [nostealth,nocombat] 潜行\n", --Rogue
	["PRIEST"] = "/targetenemy\n/cast 绝望祷言\n/cast 真言术：盾\n",--Priest
	["DEATHKNIGHT"] = "/cast 天灾契约\n/cast 亡者复生\n/castsequence 寒冬号角,牺牲契约\n", --DeathKnight
	["SHAMAN"] = "/cast 血肉铸造\n", --Shaman
	["MAGE"] = "/castsequence 寒冰护体,寒冰宝珠\n", --Mage
	["WARLOCK"] = "/castsequence 制造治疗石,黑暗契约\n/use 治疗石\n",--Warlock
	["MONK"] = "/cast 天神酒\n/cast 金创药\n",--Monk
	["DRUID"] = "/cast 血肉铸造\n",--Druid
	["DEMONHUNTER"] = "",--Demon Hunter
}
local _, className, index = UnitClass("player"); --检测职业
local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[className]
local pr= UnitName("player") .. "-" .. GetRealmName()
local macrotxt = ""
local groupLeaderName = ""
local rateFrame  
local loseNum=0
local readyCheck=false
local isSearching=false
local blackList={}

local piaobtn =  CreateFrame("BUTTON", "piaobtn", UIParent, "BackdropTemplate")
piaobtn:SetSize(50, 50)
piaobtn:SetBackdrop({bgFile = "Interface\\AddOns\\AutoBattleGround\\AutoBattleGround"})
piaobtn.Text = piaobtn:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
piaobtn.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
piaobtn.Text:SetText("评") -- 设置材质路径 
piaobtn.Text:SetPoint("CENTER", piaobtn)
piaobtn:SetClampedToScreen(true)
piaobtn:SetPoint("TOPLEFT", 300, 0)
piaobtn:SetBackdropColor(color.r, color.g, color.b)
piaobtn:SetMovable(true)
piaobtn:EnableMouse(true) 
piaobtn:RegisterForDrag("LeftButton")
piaobtn:SetScript("OnDragStart", piaobtn.StartMoving)
piaobtn:SetScript("OnDragStop", piaobtn.StopMovingOrSizing)
piaobtn:SetScript("OnClick", function() 
	AutoBattleGround:Toggle()
end)

--主面板
local AutoBattleGround = CreateFrame("Frame", "AutoBattleGround", UIParent, "UIPanelDialogTemplate")
AutoBattleGround.Title:SetTextColor(1,1,1)
AutoBattleGround.Title:SetText("艾泽拉斯科学研究院自助评级小助手 by 微微")
AutoBattleGround.Title:SetFont(STANDARD_TEXT_FONT, 12, "THINOUTLINE")
AutoBattleGround:SetSize(350, 250) 
AutoBattleGround:SetClampedToScreen(true)
AutoBattleGround:SetFrameStrata("DIALOG")
AutoBattleGround:SetPoint("TOPLEFT", 300, 0)   
AutoBattleGround:SetMovable(true)
AutoBattleGround:EnableMouse(true) 
AutoBattleGround:RegisterForDrag("LeftButton")
AutoBattleGround:SetScript("OnDragStart", AutoBattleGround.StartMoving)
AutoBattleGround:SetScript("OnDragStop", AutoBattleGround.StopMovingOrSizing)
AutoBattleGround:SetScript("OnHide", function()
	--if ABG_CONFIG.modeck then 
		piaobtn:Show()
	--end
end) 
AutoBattleGround:SetScript("OnShow", function()
	if piaobtn:IsShown() then
		piaobtn:Hide()
	end
end) 

--主宏
local PVPBtn = CreateFrame("BUTTON", "HappyPVP", nil, "SecureActionButtonTemplate")
PVPBtn:SetSize(0,0)
PVPBtn:SetAttribute("*type*", "macro") 
 

--第一行
local line1 = CreateFrame("Frame", nil, AutoBattleGround)
line1:SetSize(330,40) 
line1:SetPoint("TOP",   0, -40)
--按钮1
local resetButton= CreateFrame("Button",nil,line1, "UIPanelButtonTemplate")
resetButton:SetSize(90, 30)
resetButton:SetPoint("LEFT", 10, 0)
resetButton.Text = resetButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
resetButton.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
resetButton.Text:SetText("启动插件") -- 设置材质路径 
resetButton.Text:SetPoint("CENTER", resetButton)
resetButton:SetScript("OnClick", function() 
	step=0
	oldtime=nil  
	
	local txt = resetButton.Text:GetText()
	if txt=="启动插件" then 
		start = true
		logText("评级小助手启动!")
		resetButton.Text:SetText("关闭插件")
	else
		start = false
		logText("评级小助手关闭!")
		resetButton.Text:SetText("启动插件")
	end
end)
--按钮2
local rlButton= CreateFrame("Button",nil,line1, "UIPanelButtonTemplate")
rlButton:SetSize(90, 30)
rlButton:SetPoint("LEFT", 110, 0)
rlButton.Text = rlButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
rlButton.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
rlButton.Text:SetText("重载UI") -- 设置材质路径 
rlButton.Text:SetPoint("CENTER", rlButton)
rlButton:SetScript("OnClick", function() 
	ReloadUI()
end)



---第二行
local line2 = CreateFrame("Frame", nil, AutoBattleGround)
line2:SetSize(330,40) 
line2:SetPoint("TOP",   0, -80) 




local itemwp = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
itemwp.text = itemwp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemwp.text:SetPoint("LEFT", itemwp, "RIGHT", 0, 1)
itemwp:SetPoint("LEFT", 5, 0)
itemwp.text:SetText("快乐法杖")
itemwp:SetScript("OnClick", function() 
	SaveConfig() 
end)


local itemtk = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
itemtk.text = itemtk:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemtk.text:SetPoint("LEFT", itemtk, "RIGHT", 0, 1)
itemtk:SetPoint("LEFT", 110, 0)
itemtk.text:SetText("快乐饰品")    
itemtk:SetScript("OnClick", function() 
	SaveConfig() 
end)


---第三行
local line3 = CreateFrame("Frame", nil, AutoBattleGround)
line3:SetSize(330,40) 
line3:SetPoint("TOP",   0, -120) 


---第四行


local line4 = CreateFrame("Frame", nil, AutoBattleGround)
line4:SetSize(330,40) 
line4:SetPoint("TOP",   0, -160) 
 




--第N行 显示log
local content = CreateFrame("Frame", nil, AutoBattleGround)
content:SetSize(330,40) 
content:SetPoint("TOP",  0, -200)
content.Text = content:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
content.Text:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
content.Text:SetPoint("LEFT", content, "LEFT", 15, 0)

function logText(text)
	content.Text:SetText(date("[%H:%M:%S] ")..text)  
	print(date("[%H:%M:%S] ")..text)
end

--保存配置 重置宏
function SaveConfig(normal)
	local usewptxt = itemwp:GetChecked() and "/use 16\n" or ""
	local usetktxt =itemtk:GetChecked() and "/use 13\n/use 14\n" or ""
	local useclassSpell =  classSpell[className]  
	local runAction = "/run AutoBattleGround:Action()\n"
	local enterMarco = readyCheck and "/click PVPReadyDialogEnterBattleButton\n" or ""
	macrotxt= useclassSpell..usewptxt..usetktxt..runAction..enterMarco
	PVPBtn:SetAttribute("macrotext",macrotxt)
	if normal==nil then
		logText("ABG配置成功")
	end

	
	--print(macrotxt)
end

  

--主逻辑
function AutoBattleGround:Action()
	if not start then
		-- start = true
		logText("插件未启动,请在主面板启动插件!")
		return
	end
	
	 
	 
	 if LFGListInviteDialog:IsShown() then
		if start then
			local _, status, _, _, role = C_LFGList.GetApplicationInfo(LFGListInviteDialog.resultID)
			if status=="invited" then
				groupLeaderName = ""
				LFGListInviteDialog.AcceptButton:Click()
				logText("自动进组")
				--return
			end
			if status=="inviteaccepted" then
				LFGListInviteDialog.AcknowledgeButton:Click()
				logText("关闭邀请框")
				--return
			end
		end
	end	 
 
	if IsInGroup() then
		step = 0
		local _, instanceType = IsInInstance()
		local IsInBG = instanceType=="pvp"
		if groupLeaderName=="" then groupLeaderName = GetGroupLeader() end
		if not IsInBG then
			if oldtime ==nil  then
				oldtime = time()
			end
			local newtime = time()
			local difftime=newtime-oldtime 
			logText("等待时间:"..difftime.."秒") 
			 
			if difftime>difftime_config then
				C_PartyInfo.LeaveParty()
				logText("整整"..difftime.."秒没开打 果断离队")
				return
			end
			if  GetNumGroupMembers()<=groupmembersMin_config then
				C_PartyInfo.LeaveParty()
				logText("人数过少 果断离队")
				return
			end
			if UnitIsGroupLeader("player") then
				C_PartyInfo.LeaveParty()
				logText("我怎么变团长了? 果断离队")
			end
			if loseNum>=3 then
				C_PartyInfo.LeaveParty()
				logText("连跪N把了 离队换个车头")
				return
			end
			local gaNum=GetGroupAssistantNum()
			if gaNum> groupassistantnumMax_config  then
				C_PartyInfo.LeaveParty()
				blackList[groupLeaderName]=1
				logText("队伍A的数量:"..gaNum)
				logText("这个队伍A太多了 果断换一个")
				return
			end
			if gaNum <= groupassistantnumMin_config  then
				if string.find(groupLeaderName,"活树") or string.find(groupLeaderName,"小超")  or string.find(groupLeaderName,"漠然") then
					logText("熟人队伍 观望一下")
				else
					blackList[groupLeaderName]=1
					--ABG_DB.BLACKLIST = blackList
					C_PartyInfo.LeaveParty()
					logText("队伍A的数量:"..gaNum)
					logText("这个队伍活人队 果断换一个")
				return
				end
			end
		else
			oldtime =nil 
		end		
		return 
	else
	
		oldtime = nil 
		loseNum = 0
	 
		if step==0 then
			C_LFGList.SetSearchToActivity(19)
			step=1; 
			return
		end
		if  step==1 and isSearching==false then
			isSearching=true
			logText("搜索队伍中...")
			--C_LFGList.Search(9, 0, 19)
			C_LFGList.Search(9, 0, 8)
	
		 
		end
			
 

	 
		 
	end
  
end

function AutoBattleGround:Toggle()
	if AutoBattleGround:IsShown() then
		AutoBattleGround:Hide()  
	else
		AutoBattleGround:Show()  
		
	end

end
 
 


function SlashCmdList.AutoBattleGround(msg)
	AutoBattleGround:Toggle()
end
SLASH_AutoBattleGround1 = '/AutoBattleGround'
SLASH_AutoBattleGround2 = '/abg'

function GetGroupLeader()
	if GetNumGroupMembers() >=5 and  (not UnitIsGroupLeader("player"))  then
		for i=1,10  do 
			name = GetRaidRosterInfo(i);   
			if UnitIsGroupLeader(name)==true then 
				if not string.find(name,"-") then
					name = name.."-"..GetRealmName() 
				end
				logText("当前车头:"..name)
				return name
			end
		end
	end
end

function GetGroupAssistantNum()
	if(UnitIsGroupAssistant("player")) then
		return 10
	end
	
	
	
	local num = 0 
	for i=1,10  do 
		name,_,_,_,_,_,_,online = GetRaidRosterInfo(i)
		if name~=nil then
			if UnitIsGroupAssistant(name)==true or UnitIsGroupLeader(name)==true or (not online) then 
				num = num + 1
			end
		end
	end
	--logText("队伍A的数量:"..num)
	 
	return num
end


function GetRate()
	local winner=C_PvP.GetActiveMatchWinner()
	local fatcion = GetBattlefieldArenaFaction() 
	if  groupLeaderName =="" or groupLeaderName == nil then
		logText("统计车头数据失败")
	else
		
		if winner == fatcion then
			loseNum = 0
		else
			loseNum = loseNum + 1
		end
	end
	
	if loseNum>=2 then
		logText("连跪"..loseNum.."把了")
	end
	
	ConfirmOrLeaveBattlefield()	 
 end
 
 
function AutoBattleGround_CreateMinimapButton()
	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("AutoBattleGround", {
        type = "launcher",
        label = "快乐评级",
        icon = 1322720,
        iconCoords = {0.08, 0.92, 0.08, 0.92},
        OnClick = function(s,b) AutoBattleGround:Toggle() end,
		OnTooltipShow = function(tooltip) tooltip:AddLine("快乐评级", 1, 1, 1, 1) end
    })
    LibStub("LibDBIcon-1.0"):Register("AutoBattleGround", ldb);
end
 
function AutoBattleGround:Init() 
	if (not ABG_DB) then
		ABG_DB = {}
	end 
	 
	if not ABG_CONFIG then
		ABG_CONFIG={}
	end
	  
	if not ABG_DB.BLACKLIST then
		ABG_DB.BLACKLIST={}
	else
		--blackList = ABG_DB.BLACKLIST
	end
	if  not GetMacroInfo("快乐评级") then
		CreateMacro("快乐评级", "1322720", "/click HappyPVP", nil, nil)
		logText("初始化评级宏")
	end
	itemwp:SetChecked(GetInventoryItemID("player", 16)==168973)
	itemtk:SetChecked(GetInventoryItemID("player", 13)==167866 or GetInventoryItemID("player", 14)==167866 or GetInventoryItemID("player", 13)==178783 or GetInventoryItemID("player", 14)==178783)

	SaveConfig()
	AutoBattleGround_CreateMinimapButton()
	AutoBattleGround:Toggle()
end 

local abgEvent = CreateFrame("Frame")
abgEvent:RegisterEvent("PLAYER_LOGIN") 
abgEvent:SetScript("OnEvent", AutoBattleGround.Init) 


function signUp(searchResultInfo)
	if ( searchResultInfo.activityID ~= LFGListApplicationDialog.LFGListApplicationDialog ) then
		C_LFGList.ClearApplicationTextFields();
	end
	local _, tank, healer, dps = GetLFGRoles(); 
	C_LFGList.ApplyToGroup(searchResultInfo.searchResultID, tank, healer, dps);
	
end


local gnumBase = 0;
local abgPVPmatch = CreateFrame("Frame")
abgPVPmatch:RegisterEvent("PVP_MATCH_COMPLETE") 
abgPVPmatch:RegisterEvent("GROUP_ROSTER_UPDATE") 
abgPVPmatch:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")  
abgPVPmatch:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")  
function abgPVPmatch:OnEvent(event, arg1)  
	if start then
	
		
		if event == "PVP_MATCH_COMPLETE" then
			GetRate()
			logText("退出战场") 
			return
		end
		if event == "GROUP_ROSTER_UPDATE" then
			local tempGnum= GetNumGroupMembers()
			if gnumBase<tempGnum then
				oldtime = nil
				gnumBase = tempGnum
			end
		end
		if event=="LFG_LIST_SEARCH_RESULTS_RECEIVED" and isSearching then
			StaticPopupSpecial_Hide(LFGListApplicationDialog);
		
			numResults, resultIDTable = C_LFGList.GetSearchResults();
			local temp = {}
			if numResults> 0 then
				for k,v in pairs(resultIDTable) do
					local result  = C_LFGList.GetSearchResultInfo(v);
					
					local searchResultID = result.searchResultID
					--local activityID = result.activityID
					local leaderName = result.leaderName
					local name = result.name
					local comment = result.comment
					local voiceChat = result.voiceChat
					local requiredItemLevel = result.requiredItemLevel
					--local requiredHonorLevel = result.requiredHonorLevel
					local numMembers = result.numMembers
					local numBNetFriends = result.numBNetFriends
					--local numCharFriends = result.numCharFriends
					local numGuildMates = result.numGuildMates
					--local isDelisted = result.isDelisted
					--local autoAccept = result.autoAccept
					local age = result.age
					--local questID = result.questID
					if leaderName and not string.find(leaderName,"-") then
						leaderName = leaderName.."-"..GetRealmName() 
					end 
					
					if #comment>0 and #voiceChat==0 and numBNetFriends==0 and numGuildMates==0 and age<300 and requiredItemLevel>=0 and requiredItemLevel<100 and numMembers>=groupmembersMin_config and numMembers<=groupmembersMax_config and leaderName and blackList[leaderName]==nil  then
						table.insert(temp,result)
						if string.find(leaderName,"活树") or string.find(leaderName,"小超")  or string.find(groupLeaderName,"漠然") then
							logText("偶遇熟人:"..leaderName)
							signUp(result)
						end 
					end 
					
				end 
				logText("本次搜索到评级队伍"..#resultIDTable.."个,疑似脚本队"..#temp.."个")
			    if #temp>0 then
					local num = math.random(#temp) 
						local item = temp[num]
					logText("随机选择:"..item.name.."("..item.comment..")") 
					logText("车头:"..item.leaderName) 
					signUp(item)
					 
				end 
					isSearching=false
				  
			end
		end
		if event=="UPDATE_BATTLEFIELD_STATUS" then
			local status = GetBattlefieldStatus(arg1);
			if status=="confirm" and readyCheck==false then
				readyCheck=true
				SaveConfig(0)
			else
				if status =="queued" then
					oldtime = nil
				end
				if readyCheck then
					readyCheck=false
					SaveConfig(0)
				end
			end
			
		end
	end
end
abgPVPmatch:SetScript("OnEvent", abgPVPmatch.OnEvent);
 


LFGListInviteDialog:SetScript("OnShow",function(self) 
	 if start then
		local _, status, _, _, role = C_LFGList.GetApplicationInfo(LFGListInviteDialog.resultID)
		if status=="invited" then
			groupLeaderName = ""
			LFGListInviteDialog_Accept(LFGListInviteDialog)
			--logText("自动进组")
		end
		if status=="inviteaccepted" then
			LFGListInviteDialog_Acknowledge(LFGListInviteDialog)
			--logText("关闭邀请框")
		end
	 end
end)
LFDRoleCheckPopup:SetScript("OnShow",function() 
	if start then
		LFDRoleCheckPopupAccept_OnClick()
		logText("确认职责")
	end
end)
BonusRollFrame:SetScript("OnShow",function() 
	if start then
		DeclineSpellConfirmationPrompt(BonusRollFrame.spellID)
		logText("关闭ROLL币框")
	end
end)

