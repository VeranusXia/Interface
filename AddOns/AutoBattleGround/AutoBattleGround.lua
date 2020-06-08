--local AutoBattleGround = CreateFrame("Frame")

local AutoBattleGround = CreateFrame("Frame", "AutoBattleGround", UIParent, "UIPanelDialogTemplate")
AutoBattleGround.Title:SetTextColor(1,1,1)
AutoBattleGround.Title:SetText("艾泽拉斯科学研究院自动评级小助手")
AutoBattleGround.Title:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE")
AutoBattleGround:SetSize(300, 150) 
AutoBattleGround:SetClampedToScreen(true)
AutoBattleGround:SetFrameStrata("DIALOG")
AutoBattleGround:SetPoint("Left", 400, -200)   
AutoBattleGround:Show() 

AutoBattleGround:SetMovable(true)
AutoBattleGround:EnableMouse(true) 
AutoBattleGround:RegisterForDrag("LeftButton")
AutoBattleGround:SetScript("OnDragStart", AutoBattleGround.StartMoving)
AutoBattleGround:SetScript("OnDragStop", AutoBattleGround.StopMovingOrSizing)

local header = CreateFrame("Frame", nil, AutoBattleGround)
header:SetSize(250,40) 
header:SetPoint("TOP",   0, -40)

local actionButton= CreateFrame("Button",nil,header, "UIPanelButtonTemplate")
actionButton:SetSize(80, 30)
actionButton:SetPoint("LEFT", 20, 0)
actionButton.Text = actionButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
actionButton.Text:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
actionButton.Text:SetText("初始化") -- 设置材质路径 
actionButton.Text:SetPoint("LEFT", actionButton, "LEFT", 15, 0)
actionButton:SetScript("OnClick", function() 
	step=0
	oldtime=nil
end)

local hideButton= CreateFrame("Button",nil,header, "UIPanelButtonTemplate")
hideButton:SetSize(80, 30)
hideButton:SetPoint("LEFT", 100, 0)
hideButton.Text = hideButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
hideButton.Text:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
hideButton.Text:SetText("ReloadUI") -- 设置材质路径 
hideButton.Text:SetPoint("LEFT", hideButton, "LEFT", 15, 0)
hideButton:SetScript("OnClick", function() 
	ReloadUI()
end)



local content = CreateFrame("Frame", nil, AutoBattleGround)
content:SetSize(250,40) 
content:SetPoint("TOP",  0, -80)
content.Text = content:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
content.Text:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
content.Text:SetPoint("LEFT", content, "LEFT", 24, 0)

function logText(text)
	content.Text:SetText(date("[%H:%M:%S] ")..text)  
	print(date("[%H:%M:%S] ")..text)
end




local timeico = CreateFrame("Frame", nil, header)
timeico:SetSize(80, 30)
timeico:SetPoint("LEFT", 180, 0)
timeico.Text = timeico:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
timeico.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
timeico.Text:SetPoint("LEFT", timeico, "LEFT", 24, 0)

function logTime(difftime)
	timeico.Text:SetText(difftime)  
end


local step = 0;
local oldtime = nil

function AutoBattleGround:Action()
	local MeetingStone = LibStub('AceAddon-3.0'):GetAddon('MeetingStone')
	local BrowsePanel = MeetingStone:GetModule('BrowsePanel')
	local MainPanel =MeetingStone:GetModule('MainPanel')
	local item = BrowsePanel.ActivityList:GetItem(1) 
			 
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
			if difftime>120 then
				LeaveParty()
				logText("长时间没开打 果断离队")
			end
			if  GetNumGroupMembers()<=7 then
				LeaveParty()
				logText("人数过少 果断离队")
			end
		else
			oldtime =nil
			logTime("")
		end
		
		 
		
		if StaticPopup1Button2:IsShown() then
			StaticPopup1Button2:Click() 
			--logText("StaticPopup1Button2.click")
		end
		if LFGListInviteDialog:IsShown() then  
			LFGListInviteDialog.AcknowledgeButton:Click()
			logText("关闭邀请框")			
		end
		if LFDRoleCheckPopup:IsShown() then
			LFDRoleCheckPopupAcceptButton:Click() 
			logText("选择职责")
		end  
		if PVPMatchResults:IsShown() then
			PVPMatchResults["leaveButton"]:Click() 
			logText("退出战场")
		end 
		return 
	else
		oldtime =nil
		logTime("")
		if step==0 then
			if MainPanel:IsShown() then
				logText("集合石已打开")
			else
				MeetingStone:Toggle()
				logText("打开集合石")
			end
			if BrowsePanel.RefreshButton:IsEnabled() then
				BrowsePanel:DoSearch() 
				BrowsePanel.ActivityList:SetSortHandler(function(activity)
					return activity:GetMaxMembers() - activity:GetNumMembers()
				end)
				step=1;
				logText("搜索集合石队伍")
			end

			return
		end
			
		if step==1 then 
			local num = math.random(5)  
			BrowsePanel.ActivityList:Sort()
			local item = BrowsePanel.ActivityList:GetItem(num) 
			logText("随机选择第"..num.."队")
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
			end 
			return 
		end
		 
	end
  
end
	
	
function SlashCmdList.AutoBattleGround(msg)
	AutoBattleGround:Show() 
end
SLASH_AutoBattleGround1 = '/AutoBattleGround'
SLASH_AutoBattleGround2 = '/abg'