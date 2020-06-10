 


  
  
local step = 0;
local oldtime = nil
local classSpell ={
	["WARRIOR"] = "/cast 死亡之愿\n",--Warrior 
	["PALADIN"] = "/targetfriendplayer\n/cast 殉道者之光\n",--Paladin
	["HUNTER"] = "/cast 意气风发\n", --Hunter
	["ROGUE"] = "", --Rogue
	["PRIEST"] = "/cast 绝望祷言\n/castsequence reset=6 真言术：耀,预兆\n",--Priest
	["DEATHKNIGHT"] = "/cast 天灾契约\n", --DeathKnight
	["SHAMAN"] = "", --Shaman
	["MAGE"] = "", --Mage
	["WARLOCK"] = "/cast 黑暗契约\n/use 治疗石\n/cast 制造治疗石\n",--Warlock
	["MONK"] = "",--Monk
	["DRUID"] = "",--Druid
	["DEMON HUNTER"] = "",--Demon Hunter
}
local _, className, index = UnitClass("player"); --检测职业
local pr= UnitName("player") .. "-" .. GetRealmName()
local curHour = tonumber(date("%H")) --当前时间 夜间模式判断用
local macrotxt = ""
local signUpNum = 5
local groupLeaderName = ""
 


local piaobtn =  CreateFrame("BUTTON", nil, UIParent, "UIPanelButtonTemplate")
piaobtn:SetSize(100, 40)
piaobtn.Text = piaobtn:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
piaobtn.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
piaobtn.Text:SetText("评级小助手") -- 设置材质路径 
piaobtn.Text:SetPoint("CENTER", piaobtn)
piaobtn:SetClampedToScreen(true)
piaobtn:SetPoint("LEFT", 300, 0)
piaobtn:SetMovable(true)
piaobtn:EnableMouse(true) 
piaobtn:RegisterForDrag("LeftButton")
piaobtn:SetScript("OnDragStart", piaobtn.StartMoving)
piaobtn:SetScript("OnDragStop", piaobtn.StopMovingOrSizing)
piaobtn:SetScript("OnClick", function() 
	piaobtn:Hide()
end)
piaobtn:SetScript("OnHide", function()
	AutoBattleGround:Show() 
end)

--主面板
local AutoBattleGround = CreateFrame("Frame", "AutoBattleGround", UIParent, "UIPanelDialogTemplate")
AutoBattleGround.Title:SetTextColor(1,1,1)
AutoBattleGround.Title:SetText("艾泽拉斯科学研究院自助评级小助手 by 微微")
AutoBattleGround.Title:SetFont(STANDARD_TEXT_FONT, 12, "THINOUTLINE")
AutoBattleGround:SetSize(350, 250) 
AutoBattleGround:SetClampedToScreen(true)
AutoBattleGround:SetFrameStrata("DIALOG")
AutoBattleGround:SetPoint("Left", 400, -200)   
AutoBattleGround:SetMovable(true)
AutoBattleGround:EnableMouse(true) 
AutoBattleGround:RegisterForDrag("LeftButton")
AutoBattleGround:SetScript("OnDragStart", AutoBattleGround.StartMoving)
AutoBattleGround:SetScript("OnDragStop", AutoBattleGround.StopMovingOrSizing)
AutoBattleGround:SetScript("OnHide", function()
	piaobtn:Show()
end)
AutoBattleGround:Hide()


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
resetButton.Text:SetText("初始化") -- 设置材质路径 
resetButton.Text:SetPoint("CENTER", resetButton)
resetButton:SetScript("OnClick", function() 
	step=0
	oldtime=nil 
	logText("重置step:"..step)
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

--显示待机时间

local timeico = CreateFrame("Frame", nil, line1)
timeico:SetSize(80, 30)
timeico:SetPoint("LEFT", 190, 0)
timeico.Text = timeico:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
timeico.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
timeico.Text:SetPoint("LEFT", timeico, "LEFT", 24, 0)

function logTime(difftime)
	if difftime>0 then
		timeico.Text:SetText("等待时间: "..difftime)  
	else
		timeico.Text:SetText("")
	end
end

---第二行
local line2 = CreateFrame("Frame", nil, AutoBattleGround)
line2:SetSize(330,40) 
line2:SetPoint("TOP",   0, -80) 

local modeck = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
modeck.text = modeck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
modeck.text:SetPoint("LEFT", modeck, "RIGHT", 0, 1)
modeck:SetPoint("LEFT", 5, 0)
modeck.text:SetText("开启夜间")

local itemwp = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
itemwp.text = itemwp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemwp.text:SetPoint("LEFT", itemwp, "RIGHT", 0, 1)
itemwp:SetPoint("LEFT", 110, 0)
itemwp.text:SetText("快乐法杖")

local itemtk = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
itemtk.text = itemtk:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemtk.text:SetPoint("LEFT", itemtk, "RIGHT", 0, 1)
itemtk:SetPoint("LEFT", 215, 0)
itemtk.text:SetText("快乐饰品")    


---第三行
local line3 = CreateFrame("Frame", nil, AutoBattleGround)
line3:SetSize(330,40) 
line3:SetPoint("TOP",   0, -120) 

local boxck = CreateFrame("CheckButton", nil, line3, "UICheckButtonTemplate")
boxck.text = boxck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
boxck.text:SetPoint("LEFT", boxck, "RIGHT", 0, 1)
boxck:SetPoint("LEFT", 5, 0)
boxck:SetChecked(true)
boxck.text:SetText("快乐宝箱")

local fishck = CreateFrame("CheckButton", nil, line3, "UICheckButtonTemplate")
fishck.text = fishck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fishck.text:SetPoint("LEFT", fishck, "RIGHT", 0, 1)
fishck:SetPoint("LEFT", 110, 0)
fishck:SetChecked(false)
fishck.text:SetText("快乐开鱼")

local classSPck = CreateFrame("CheckButton", nil, line3, "UICheckButtonTemplate")
classSPck.text = classSPck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
classSPck.text:SetPoint("LEFT", classSPck, "RIGHT", 0, 1)
classSPck:SetPoint("LEFT", 215, 0)
classSPck:SetChecked(classSpell[className]~="")
classSPck.text:SetText("职业技能")


---第四行


local line4 = CreateFrame("Frame", nil, AutoBattleGround)
line4:SetSize(330,40) 
line4:SetPoint("TOP",   0, -160) 
 
local neckck = CreateFrame("CheckButton", nil, line4, "UICheckButtonTemplate")
neckck.text = neckck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
neckck.text:SetPoint("LEFT", neckck, "RIGHT", 0, 1)
neckck:SetPoint("LEFT", 5, 0)
neckck:SetChecked(classSpell[className]=="")
neckck.text:SetText("火红烈焰")


--配置按钮
local configButton= CreateFrame("Button",nil,line4, "UIPanelButtonTemplate")
configButton:SetSize(80, 30)
configButton:SetPoint("LEFT", 110, 0)
configButton.Text = configButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
configButton.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
configButton.Text:SetText("更新设置") -- 设置材质路径 
configButton.Text:SetPoint("CENTER", configButton)
configButton:SetScript("OnClick", function()  
	SaveConfig() 
	logText("修改配置")
	print(macrotxt)
end)



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
function SaveConfig()
	local usewptxt = itemwp:GetChecked() and "\n/use 16\n" or ""
	local usetktxt = itemtk:GetChecked() and "/use 13\n/use 14\n" or ""
	local usebox = boxck:GetChecked() and "/use 黄金保险箱\n/use 钢铁保险箱\n" or ""
	local usefish = fishck:GetChecked() and "/use 淡紫刺鳐\n/use 软泥鲭鱼\n/use 洋流鲷鱼\n/use 狂乱的利齿青鱼\n/use 赤尾泥鳅\n/use 海砂变色鱼\n/use 提拉加德鲈鱼\n/use 蝰鱼\n/use 无尽之海鲶鱼\n" or ""
	local useneck = neckck:GetChecked() and "/targetenemy\n/cast 火红烈焰\n" or ""
	local useclassSpell = classSPck:GetChecked() and classSpell[className] or ""
	macrotxt= usewptxt..usetktxt..usebox..usefish..useneck..useclassSpell.."/run AutoBattleGround:Action()\n/click PVPReadyDialogEnterBattleButton\n"
	PVPBtn:SetAttribute("macrotext",macrotxt)
end



--主逻辑
function AutoBattleGround:Action()
	local MeetingStone = LibStub('AceAddon-3.0'):GetAddon('MeetingStone')
	local BrowsePanel = MeetingStone:GetModule('BrowsePanel')
	local MainPanel =MeetingStone:GetModule('MainPanel')
	local item = BrowsePanel.ActivityList:GetItem(1) 
	
	local difftime_config= 120
	local groupmembers_config = 6
	
	
	local auto = modeck:GetChecked()
	if auto then
		local curHour = tonumber(date("%H")) 
		difftime_config= (curHour>=24 or curHour<=7) and 300 or 120
		groupmembers_config = modeck:GetChecked() and 7 or 6 
	end
 
	if IsInGroup() then
		step = 0
		local _, instanceType = IsInInstance()
		local IsInBG = instanceType=="pvp"
		if not IsInBG then
			if oldtime ==nil  then
				oldtime = time()
			end
			local newtime = time()
			local difftime=newtime-oldtime
			logTime(difftime) 
			if difftime>difftime_config then
				LeaveParty()
				logText("整整"..difftime.."秒没开打 果断离队")
				return
			end
			if  GetNumGroupMembers()<=groupmembers_config then
				LeaveParty()
				logText("人数过少 果断离队")
				return
			end
			if UnitIsGroupLeader("player") then
				LeaveParty()
				logText("我怎么变团长了? 果断离队")
			end
		else
			oldtime =nil
			logTime(0)
		end
		
		  
		
		if StaticPopup1Button2:IsShown() then
			StaticPopup1Button2:Click() 
		end
		if LFGListInviteDialog:IsShown() then  
			LFGListInviteDialog.AcknowledgeButton:Click()
			logText("关闭邀请框")	
			return
		end
		if LFDRoleCheckPopup:IsShown() then
			LFDRoleCheckPopupAcceptButton:Click() 
			logText("选择职责")
			return
		end  
		  
		
		if PVPMatchResults:IsShown() then
			PVPMatchResults["leaveButton"]:Click() 
			--GetRate()
			logText("退出战场")
		else
			groupLeaderName = GetGroupLeader()
			--logText("当前车头:"..groupLeaderName)
		end 
		
		if BonusRollFrame:IsShown() then
			DeclineSpellConfirmationPrompt(BonusRollFrame.spellID)
			logText("关闭ROLL币框")
			return
		end
		
		return 
	else

	
		oldtime =nil
		logTime(0)
		
		
		if step>0 and not MainPanel:IsShown() then
			MeetingStone:Toggle()
				logText("打开集合石")
			return
		end
		
		
		if step==0 then
			if MainPanel:IsShown() then
				--logText("集合石已打开")
			else
				MeetingStone:Toggle()
				logText("打开集合石")
			end 
			
			if  MainPanel:GetSelectedTab()~=nil and MainPanel:GetSelectedTab()>1 then
			     MainPanel:SelectTab(1)
			end
			
			
			if BrowsePanel.RefreshButton:IsEnabled() then
				BrowsePanel:DoSearch() 
				BrowsePanel.ActivityList:SetSortHandler(function(activity)
					return activity:GetMaxMembers() - activity:GetNumMembers()
				end)
				step=1;
				logText("搜索集合石队伍")
			else
				logText("集合石刷新中请稍等")
			end

			return
		end
			
		if step==1 then 
			local num = math.random(signUpNum)  
			BrowsePanel.ActivityList:Sort()
			local item = BrowsePanel.ActivityList:GetItem(num) 
			
			local info = C_LFGList.GetSearchResultInfo(item:GetID()) -- info.leaderName info.name  info.comment
			local winrate = GetWinRate(info.leaderName)
			if item:IsAnyFriend() then
				return
			end
			--activity:IsAnyFriend()
			--activity:GetTitle() 
			logText("随机选择第"..num.."队 "..winrate) 
			BrowsePanel:SignUp(item)
			step=2 
			return
		end
			
		if step==2 then 
			if  LFGListApplicationDialog:IsShown() then 
				LFGListApplicationDialog.SignUpButton:Click() 
				step=3				
				logText("申请加入队伍")
			end 
			return 
		end 
		
		if step==3 then  
			if  LFGListInviteDialog:IsShown() then 
				LFGListInviteDialog.AcceptButton:Click() 
				logText("自动进组")
			else
				step=1
				BrowsePanel:DoSearch() 
			end 
			return 
		end
		 
	end
  
end

function AutoBattleGround:Toggle()
	if AutoBattleGround:IsShown() then
		AutoBattleGround:Hide() 
		piaobtn:Show()
	else
		AutoBattleGround:Show() 
		piaobtn:Hide()
	end
end

function GetWinRate(leaderName)
	local win = 0
	local lose =0  
	for k1,v1 in pairs(ABG_DB) do  
        for k2,v2 in pairs(v1) do
			if k2==leaderName then
				win = win + v2.win
				lose = lose + v2.lose
			end
		end
    end
	if lose==0 and win==0 then
		return leaderName.."(暂无胜率)"
	else
		return leaderName.."("..string.format("%.2f",win/(win+lose)*100).."%)"
	end
end


function SlashCmdList.AutoBattleGround(msg)
	AutoBattleGround:Toggle()
end
SLASH_AutoBattleGround1 = '/AutoBattleGround'
SLASH_AutoBattleGround2 = '/abg'

function GetGroupLeader()
	for i=1,10  do 
		name = GetRaidRosterInfo(i);   
		if UnitIsGroupLeader(name)==true then 
			return name
		end
	end
end


function GetRate()
	local winner=C_PvP.GetActiveMatchWinner()
	local fatcion = GetBattlefieldArenaFaction()
	 
	name = groupLeaderName
	if (not ABG_DB[pr][name]) then
		ABG_DB[pr][name] = {};
		ABG_DB[pr][name].win=0;
		ABG_DB[pr][name].lose=0;
	end 
	if winner == fatcion then
		ABG_DB[pr][name].win= ABG_DB[pr][name].win +1
	else
		ABG_DB[pr][name].lose= ABG_DB[pr][name].lose+1
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

local abg = CreateFrame("Frame"); 
abg:RegisterEvent("PLAYER_ENTERING_WORLD");
function abg:OnEvent(event, arg1) 
	if (not ABG_DB) then
		ABG_DB = {};
	end 
	if ABG_DB.config then
		ABG_DB = {};
	end
	if (not ABG_DB[pr]) then
		ABG_DB[pr] = {};
	end 
	if not GetMacroInfo("快乐评级") then
		ABG_DB.marco = CreateMacro("快乐评级", "1322720", "/click HappyPVP", nil, nil)
	end
	modeck:SetChecked(true)
	itemwp:SetChecked(GetInventoryItemID("player", 16)==168973)
	itemtk:SetChecked(GetInventoryItemID("player", 13)==167866 or GetInventoryItemID("player", 14)==167866)
	SaveConfig()
	AutoBattleGround_CreateMinimapButton()
	--print(GetWinRate("奶爸空间-白银之手"))
end
abg:SetScript("OnEvent", abg.OnEvent);

local abgPVPmatch = CreateFrame("Frame")
abgPVPmatch:RegisterEvent("PVP_MATCH_COMPLETE")
function abgPVPmatch:OnEvent(event, arg1) 
	GetRate()
end
abgPVPmatch:SetScript("OnEvent", abgPVPmatch.OnEvent);

 