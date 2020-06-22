 
local start = false  
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
	["WARLOCK"] = "/castsequence reset=15 黑暗契约,魔甲术,制造治疗石\n/use 治疗石\n",--Warlock
	["MONK"] = "",--Monk
	["DRUID"] = "",--Druid
	["DEMON HUNTER"] = "",--Demon Hunter
}
local _, className, index = UnitClass("player"); --检测职业
local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[className]
local pr= UnitName("player") .. "-" .. GetRealmName()
local curHour = tonumber(date("%H")) --当前时间 夜间模式判断用
local macrotxt = ""
local groupLeaderName = ""
local rateFrame  
local loseNum=0


local piaobtn =  CreateFrame("BUTTON", "piaobtn", UIParent)
piaobtn:SetSize(50, 50)
piaobtn:SetBackdrop({bgFile = "Interface\\AddOns\\AutoBattleGround\\AutoBattleGround"})
piaobtn.Text = piaobtn:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
piaobtn.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
piaobtn.Text:SetText("评") -- 设置材质路径 
piaobtn.Text:SetPoint("CENTER", piaobtn)
piaobtn:SetClampedToScreen(true)
piaobtn:SetPoint("LEFT", 300, 0)
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
AutoBattleGround:SetPoint("Left", 300, 0)   
AutoBattleGround:SetMovable(true)
AutoBattleGround:EnableMouse(true) 
AutoBattleGround:RegisterForDrag("LeftButton")
AutoBattleGround:SetScript("OnDragStart", AutoBattleGround.StartMoving)
AutoBattleGround:SetScript("OnDragStop", AutoBattleGround.StopMovingOrSizing)
AutoBattleGround:SetScript("OnHide", function()
	if ABG_CONFIG.modeck then 
		piaobtn:Show()
	end
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
--按钮3
local rateButton= CreateFrame("Button",nil,line1, "UIPanelButtonTemplate")
rateButton:SetSize(90, 30)
rateButton:SetPoint("LEFT", 210, 0)
rateButton.Text = rateButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
rateButton.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
rateButton.Text:SetText("车头数据") -- 设置材质路径 
rateButton.Text:SetPoint("CENTER", rateButton)
rateButton:SetScript("OnClick", function() 
	AddRateWindow()	 
	rateButton:SetEnabled(false)
end)



---第二行
local line2 = CreateFrame("Frame", nil, AutoBattleGround)
line2:SetSize(330,40) 
line2:SetPoint("TOP",   0, -80) 

local modeck = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
modeck.text = modeck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
modeck.text:SetPoint("LEFT", modeck, "RIGHT", 0, 1)
modeck:SetPoint("LEFT", 5, 0)
modeck.text:SetText("悬浮图标")
modeck:SetScript("OnClick", function() 
	SaveConfig() 
end)

local itemwp = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
itemwp.text = itemwp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemwp.text:SetPoint("LEFT", itemwp, "RIGHT", 0, 1)
itemwp:SetPoint("LEFT", 110, 0)
itemwp.text:SetText("快乐法杖")
itemwp:SetScript("OnClick", function() 
	SaveConfig() 
end)


local itemtk = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
itemtk.text = itemtk:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemtk.text:SetPoint("LEFT", itemtk, "RIGHT", 0, 1)
itemtk:SetPoint("LEFT", 215, 0)
itemtk.text:SetText("快乐饰品")    
itemtk:SetScript("OnClick", function() 
	SaveConfig() 
end)


---第三行
local line3 = CreateFrame("Frame", nil, AutoBattleGround)
line3:SetSize(330,40) 
line3:SetPoint("TOP",   0, -120) 

local boxck = CreateFrame("CheckButton", nil, line3, "UICheckButtonTemplate")
boxck.text = boxck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
boxck.text:SetPoint("LEFT", boxck, "RIGHT", 0, 1)
boxck:SetPoint("LEFT", 5, 0)
boxck.text:SetText("快乐宝箱")
boxck:SetScript("OnClick", function() 
	SaveConfig() 
end)

local fishck = CreateFrame("CheckButton", nil, line3, "UICheckButtonTemplate")
fishck.text = fishck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fishck.text:SetPoint("LEFT", fishck, "RIGHT", 0, 1)
fishck:SetPoint("LEFT", 110, 0)
fishck.text:SetText("快乐开鱼")
fishck:SetScript("OnClick", function() 
	SaveConfig() 
end)

local classSPck = CreateFrame("CheckButton", nil, line3, "UICheckButtonTemplate")
classSPck.text = classSPck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
classSPck.text:SetPoint("LEFT", classSPck, "RIGHT", 0, 1)
classSPck:SetPoint("LEFT", 215, 0)
classSPck.text:SetText("职业技能")
classSPck:SetScript("OnClick", function() 
	SaveConfig() 
end)

---第四行


local line4 = CreateFrame("Frame", nil, AutoBattleGround)
line4:SetSize(330,40) 
line4:SetPoint("TOP",   0, -160) 
 
local neckck = CreateFrame("CheckButton", nil, line4, "UICheckButtonTemplate")
neckck.text = neckck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
neckck.text:SetPoint("LEFT", neckck, "RIGHT", 0, 1)
neckck:SetPoint("LEFT", 5, 0)
neckck.text:SetText("火红烈焰")
neckck:SetScript("OnClick", function() 
	SaveConfig() 
end)

local blck = CreateFrame("CheckButton", nil, line4, "UICheckButtonTemplate")
blck.text = blck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
blck.text:SetPoint("LEFT", blck, "RIGHT", 0, 1)
blck:SetPoint("LEFT", 110, 0)
blck.text:SetText("部落模式")
blck:SetScript("OnClick", function() 
	SaveConfig() 
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
	logText("ABG配置成功")
	
	ABG_CONFIG.modeck = modeck:GetChecked()
	ABG_CONFIG.boxck = boxck:GetChecked()
	ABG_CONFIG.fishck = fishck:GetChecked()
	ABG_CONFIG.blck = blck:GetChecked()
	
	--print(macrotxt)
end

function AddRateWindow()

    rateFrame = CreateFrame("Frame", "rateFrame", UIParent, "UIPanelDialogTemplate")
    rateFrame.Title:SetTextColor(1,1,1)
	rateFrame.Title:SetText("车头胜率")
	
	--rateFrame:SetMovable(true)
	--rateFrame:EnableMouse(true) 
	--rateFrame:RegisterForDrag("LeftButton") 
	--rateFrame:SetScript("OnDragStart", rateFrame.StartMoving)
	--rateFrame:SetScript("OnDragStop", rateFrame.StopMovingOrSizing)
    rateFrame:SetSize(500,680)  
	rateFrame:SetPoint("TOP", 0, -150)  
	rateFrame:SetScript("OnHide",function() 
		rateButton:SetEnabled(true) 
	end)
	 
	
	local index = 1
	AddLine(rateFrame,"车头","场次","胜场","负场","胜率",index)
	for k,v in pairs(GetDrivers()) do
		if index<= 20 then
			index= index + 1
			AddLine(rateFrame,v.name,v.sum ,v.win,v.lose,v.rateStr,index)
		else
			break
		end
	end 
end
function AddLine(parentFrame,name,sum,win,lose,rate,index)
	
	local line = CreateFrame("Frame", nil, parentFrame)
	line:SetSize(490,20)
	line:SetPoint("TOP",   0, -30*index)

	local txtDriver= CreateFrame("Frame",nil,line)
	txtDriver:SetSize(150,20)
	txtDriver:SetPoint("LEFT", 50, 0)
	txtDriver.Text = txtDriver:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtDriver.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtDriver.Text:SetText(name) -- 设置材质路径 
	txtDriver.Text:SetPoint("CENTER", txtDriver, "CENTER", 0, 0)
	
	local txtSum = CreateFrame("Frame",nil,line)
	txtSum:SetSize(50,20)
	txtSum:SetPoint("LEFT",   200, 0)
	txtSum.Text = txtSum:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtSum.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtSum.Text:SetText(sum) -- 设置材质路径 
	txtSum.Text:SetPoint("CENTER", txtSum, "CENTER", 0, 0)
	
	local txtWin = CreateFrame("Frame",nil,line)
	txtWin:SetSize(50,20)
	txtWin:SetPoint("LEFT",   250, 0)
	txtWin.Text = txtWin:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtWin.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtWin.Text:SetText(win) -- 设置材质路径 
	txtWin.Text:SetPoint("CENTER", txtWin, "CENTER", 0, 0)
	
	local txtLose= CreateFrame("Frame",nil,line)
	txtLose:SetSize(50,20)
	txtLose:SetPoint("LEFT", 300, 0)
	txtLose.Text = txtLose:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtLose.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtLose.Text:SetText(lose) -- 设置材质路径 
	txtLose.Text:SetPoint("CENTER", txtLose, "CENTER", 0, 0)
	
	
	local txtRate= CreateFrame("Frame",nil,line)
	txtRate:SetSize(80,20)
	txtRate:SetPoint("LEFT", 350, 0)
	txtRate.Text = txtRate:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
	txtRate.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
	txtRate.Text:SetText(rate) -- 设置材质路径 
	txtRate.Text:SetPoint("CENTER", txtRate, "CENTER", 0, 0)

end

--主逻辑
function AutoBattleGround:Action()
	if not start then
		start = true
		logText("评级小助手启动!")
	end
	
	
 	local curHour = tonumber(date("%H")) 
	local daynightmode = blck:GetChecked() and true or (curHour>=22 or curHour<=9)
	local difftime_config= daynightmode and 300 or 120
	local groupmembers_config = daynightmode and 7 or 6 
	local groupassistantnum_config = daynightmode and 9 or 7



	  
	 
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
			if loseNum>=3 then
				LeaveParty()
				logText("连跪三把了 离队换个车头")
				return
			end
			if GetGroupAssistantNum()> groupassistantnum_config then
				LeaveParty()
				logText("这个队伍A太多了 果断换一个")
				return
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
		if  step==1 then
			logText("搜索队伍中...")
			C_Timer.After(3, function()
				C_LFGList.Search(9, 0, 19)
			end) 
		 
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

function GetDrivers()
	local drivers = {}
	for k1,v1 in pairs(ABG_DB) do  
        for k2,v2 in pairs(v1) do 
			if not drivers[k2] then
				drivers[k2] ={}
				drivers[k2].name= k2
				drivers[k2].win = 0
				drivers[k2].lose = 0
			end 
			drivers[k2].win = drivers[k2].win + v2.win
			drivers[k2].lose = drivers[k2].lose + v2.lose
			drivers[k2].sum = drivers[k2].win + drivers[k2].lose
			drivers[k2].rate = drivers[k2].win/drivers[k2].sum*100
			drivers[k2].rateStr = string.format("%.2f",drivers[k2].rate).."%"
		end
    end
	 
	local keyTest ={}
	for _,v in pairs(drivers) do
		table.insert(keyTest,v) 
	end 
	table.sort(keyTest,function(a,b)
		if tonumber(a.sum) > tonumber(b.sum) then
			return true
		end
		if tonumber(a.sum) < tonumber(b.sum) then
			return false
		end
		if tonumber(a.sum) == tonumber(b.sum) then
			return tonumber(a.win) > tonumber(b.win)
		end
	 
	end)  
	local result = { }
	for i,v in pairs(keyTest) do
		table.insert(result,drivers[v.name])
	end
	return result
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
	local num = 0 
	for i=1,10  do 
		name,_,_,_,_,_,_,online = GetRaidRosterInfo(i)
		if name~=nil then
			if UnitIsGroupAssistant(name)==true or UnitIsGroupLeader(name)==true or (not online) then 
				num = num + 1
			end
		end
	end
	logText("队伍A的数量:"..num)
	 
	return num
end


function GetRate()
	local winner=C_PvP.GetActiveMatchWinner()
	local fatcion = GetBattlefieldArenaFaction() 
	if  groupLeaderName =="" or groupLeaderName == nil then
		logText("统计车头数据失败")
	else
		if (not ABGCharacterDB[groupLeaderName]) then
			ABGCharacterDB[groupLeaderName] = {};
			ABGCharacterDB[groupLeaderName].win=0;
			ABGCharacterDB[groupLeaderName].lose=0;
		end 
		if winner == fatcion then
			loseNum = 0
			ABGCharacterDB[groupLeaderName].win= ABGCharacterDB[groupLeaderName].win +1
			logText(groupLeaderName.." 胜场+1")
		else
			loseNum = loseNum + 1
			ABGCharacterDB[groupLeaderName].lose= ABGCharacterDB[groupLeaderName].lose+1
			logText(groupLeaderName.." 负场+1")
		end
	end
	ABG_DB[pr] = ABGCharacterDB
	
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
	if ABG_DB.config then
		ABG_DB = {}
	end
	if ABG_DB.marco then
		ABG_DB = {}
	end
	if not ABG_CONFIG then
		ABG_CONFIG={}
		ABG_CONFIG.modeck=true
		ABG_CONFIG.boxck =true
		ABG_CONFIG.fishck = false
		ABG_CONFIG.blck = false
	end
	
	if (not ABG_DB[pr]) then
		ABG_DB[pr] = {}
	end 
	
	--存储数据优化
	if (not ABGCharacterDB) then
		ABGCharacterDB = ABG_DB[pr]
		ABG_DB[pr] = {}
	end
	
	if ABGCharacterDB then
		ABG_DB[pr] = ABGCharacterDB
	end
	 
	if  not GetMacroInfo("快乐评级") then
		CreateMacro("快乐评级", "1322720", "/click HappyPVP", nil, nil)
		logText("初始化评级宏")
	end
	modeck:SetChecked(ABG_CONFIG.modeck)
	boxck:SetChecked(ABG_CONFIG.boxck)
	fishck:SetChecked(ABG_CONFIG.fishck)
	blck:SetChecked(ABG_CONFIG.blck)
	
	itemwp:SetChecked(GetInventoryItemID("player", 16)==168973)
	itemtk:SetChecked(GetInventoryItemID("player", 13)==167866 or GetInventoryItemID("player", 14)==167866)
	neckck:SetChecked(classSpell[className]=="")
	classSPck:SetChecked(classSpell[className]~="")
	SaveConfig()
	AutoBattleGround_CreateMinimapButton()
	AutoBattleGround:Toggle()
end 

local abgEvent = CreateFrame("Frame")
abgEvent:RegisterEvent("PLAYER_LOGIN") 
abgEvent:SetScript("OnEvent", AutoBattleGround.Init) 



local abgPVPmatch = CreateFrame("Frame")
abgPVPmatch:RegisterEvent("PVP_MATCH_COMPLETE") 
--abgPVPmatch:RegisterEvent("GROUP_ROSTER_UPDATE") 
abgPVPmatch:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")  
function abgPVPmatch:OnEvent(event, arg1)  
	if start then
		local curHour = tonumber(date("%H")) 
		local daynightmode = blck:GetChecked() and true or (curHour>=22 or curHour<=9)
		local difftime_config= daynightmode and 300 or 120
		local groupmembers_config = daynightmode and 7 or 6 
		local groupassistantnum_config = daynightmode and 9 or 7
		
		if event == "PVP_MATCH_COMPLETE" then
			GetRate()
			logText("退出战场") 
			return
		end
		-- if event == "GROUP_ROSTER_UPDATE" then
			-- if GetGroupAssistantNum()> groupassistantnum_config   then
				-- LeaveParty()
				-- logText("这个队伍A太多了 果断换一个")
				-- return
			-- end
			-- if  GetNumGroupMembers()<=groupmembers_config and IsInGroup()   then
				-- LeaveParty()
				-- logText("人数过少 果断离队")
				-- return
			-- end
			-- oldtime = nil
		-- end
		if event=="LFG_LIST_SEARCH_RESULTS_RECEIVED" then
			numResults, resultIDTable = C_LFGList.GetSearchResults();
			local temp = {}
			if numResults> 0 then
				for k,v in pairs(resultIDTable) do
					local result  = C_LFGList.GetSearchResultInfo(v);
					local searchResultID = result.searchResultID
					--local activityID = result.activityID
					local leaderName = result.leaderName
					local name = result.name
					--local comment = result.comment
					--local voiceChat = result.voiceChat
					local requiredItemLevel = result.requiredItemLevel
					--local requiredHonorLevel = result.requiredHonorLevel
					local numMembers = result.numMembers
					local numBNetFriends = result.numBNetFriends
					--local numCharFriends = result.numCharFriends
					--local numGuildMates = result.numGuildMates
					--local isDelisted = result.isDelisted
					--local autoAccept = result.autoAccept
					local age = result.age
					--local questID = result.questID
					
					if numBNetFriends==0 and numGuildMates==0 and age<600 and requiredItemLevel>0 and requiredItemLevel<100 and numMembers>groupmembers_config     then
						table.insert(temp,result)
					end
					
					
				end 
				
				local num = math.random(#temp) 
				local item = temp[num]
				logText("随机选择:"..item.name.."("..num.."/"..#temp..")")
				logText("车头:"..GetWinRate(item.leaderName)) 
				LFGListApplicationDialog_Show(LFGListApplicationDialog,item.searchResultID)
					 
				  
			end
		end
	end
end
abgPVPmatch:SetScript("OnEvent", abgPVPmatch.OnEvent);
 
LFGListApplicationDialog:SetScript("OnShow",function() 
	if start then
		logText("申请加入队伍")
		LFGListApplicationDialogSignUpButton_OnClick(LFGListApplicationDialog.SignUpButton)
	end
end)

LFGListInviteDialog:SetScript("OnShow",function(self) 
	 if start then
		local _, status, _, _, role = C_LFGList.GetApplicationInfo(LFGListInviteDialog.resultID)
		if status=="invited" then
			groupLeaderName = ""
			LFGListInviteDialog_Accept(LFGListInviteDialog)
			logText("自动进组")
		end
		if status=="inviteaccepted" then
			LFGListInviteDialog_Acknowledge(LFGListInviteDialog)
			logText("关闭邀请框")
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


 
 
 