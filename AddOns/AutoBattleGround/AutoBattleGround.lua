--local AutoBattleGround = CreateFrame("Frame")

local frame = CreateFrame("Frame", "AutoBattleGround", UIParent, "UIPanelDialogTemplate")
frame.Title:SetTextColor(1,1,1)
frame.Title:SetText("自动评级小插件")
frame:SetWidth(240)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("DIALOG")
frame:SetPoint("Left", 400, -200)  
frame:SetHeight(80) 
--frame:Show()
frame:Hide()

local actionButton= CreateFrame("Button",nil,frame, "UIPanelButtonTemplate")
actionButton:SetSize(80, 30)
actionButton:SetPoint("LEFT", 20, -10)
actionButton.Text = actionButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
actionButton.Text:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
actionButton.Text:SetText("初始化") -- 设置材质路径 
actionButton.Text:SetPoint("LEFT", actionButton, "LEFT", 24, 0)
actionButton:SetScript("OnClick", function() 
	step=0;
end)

local hideButton= CreateFrame("Button",nil,frame, "UIPanelButtonTemplate")
hideButton:SetSize(80, 30)
hideButton:SetPoint("LEFT", 120, -10)
hideButton.Text = hideButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
hideButton.Text:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
hideButton.Text:SetText("隐藏") -- 设置材质路径 
hideButton.Text:SetPoint("LEFT", hideButton, "LEFT", 24, 0)
hideButton:SetScript("OnClick", function() 
	frame:Hide()
end)



local step = 0;

function frame:Action()
	local MeetingStone = LibStub('AceAddon-3.0'):GetAddon('MeetingStone')
	local BrowsePanel = MeetingStone:GetModule('BrowsePanel')
	local MainPanel =MeetingStone:GetModule('MainPanel')
	local item = BrowsePanel.ActivityList:GetItem(1) 
			 
	if IsInGroup() then
		step = 0
		if GetNumGroupMembers()<=7 then
			LeaveParty()
			print("人数小于8 果断离队")
		end
		
		if StaticPopup1Button2:IsShown() then
			StaticPopup1Button2:Click() 
			--print("StaticPopup1Button2.click")
		end
		if LFGListInviteDialog:IsShown() then  
			LFGListInviteDialog.AcknowledgeButton:Click()
			print("关闭邀请框")			
		end
		if LFDRoleCheckPopup:IsShown() then
			LFDRoleCheckPopupAcceptButton:Click() 
			print("选择职责")
		end  
		if PVPMatchResults:IsShown() then
			PVPMatchResults["leaveButton"]:Click() 
			print("退出战场")
		end 
		return 
	else
		if step==0 then
			if MainPanel:IsShown() then
				print("集合石已打开")
			else
				MeetingStone:Toggle()
				print("打开集合石")
			end
			if BrowsePanel.RefreshButton:IsEnabled() then
				BrowsePanel:DoSearch() 
				BrowsePanel.ActivityList:SetSortHandler(function(activity)
					return activity:GetMaxMembers() - activity:GetNumMembers()
				end)
				step=1;
				print("搜索集合石队伍")
			end

			return
		end
			
		if step==1 then 
			local num = math.random(5)  
			BrowsePanel.ActivityList:Sort()
			local item = BrowsePanel.ActivityList:GetItem(num) 
			print("随机选择第"..num.."队")
			BrowsePanel:SignUp(item)
			step=2
			return
		end
			
		if step==2 then 
			if  LFGListApplicationDialog:IsShown() then 
				LFGListApplicationDialog.SignUpButton:Click() 
				step=3				
				print("申请加入队伍")
			end 
			return 
		end 
		
		if step==3 then  
			if  LFGListInviteDialog:IsShown() then 
				LFGListInviteDialog.AcceptButton:Click() 
				print("自动进组")
			else
				step=1
			end 
			return 
		end
		 
	end
  
end
	
	