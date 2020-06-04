local AutoBattleGround = CreateFrame("Frame")

frame = CreateFrame("Frame", "AutoBattleGround", UIParent, "UIPanelDialogTemplate")
frame.Title:SetTextColor(1,1,1)
frame.Title:SetText("自动评级小插件")
frame:SetWidth(240)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("DIALOG")
frame:SetPoint("Left", -100, 0)  
frame:SetHeight(80) 
frame:Show()

local actionButton= CreateFrame("Button",nil,frame, "UIPanelButtonTemplate")
actionButton:SetSize(100, 30)
actionButton:SetPoint("LEFT", 20, -10)
actionButton.Text = actionButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
actionButton.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
actionButton.Text:SetText("初始化") -- 设置材质路径 
actionButton.Text:SetPoint("LEFT", actionButton, "LEFT", 24, 0)
actionButton:SetScript("OnClick", function() 
	step=0;
end)

local hideButton= CreateFrame("Button",nil,frame, "UIPanelButtonTemplate")
hideButton:SetSize(100, 30)
hideButton:SetPoint("LEFT", 120, -10)
hideButton.Text = hideButton:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
hideButton.Text:SetFont("Fonts\\1ZYHei.ttf", 11, "THINOUTLINE") -- 设置字体路径, 大小, 描边
hideButton.Text:SetText("隐藏") -- 设置材质路径 
hideButton.Text:SetPoint("LEFT", hideButton, "LEFT", 24, 0)
hideButton:SetScript("OnClick", function() 
	frame:Hide()
end)



local step = 0;

function frame:Action()
local MeetingStone = LibStub('AceAddon-3.0'):GetAddon('MeetingStone')
	local BrowsePanel = MeetingStone:GetModule('BrowsePanel')
	local item = BrowsePanel.ActivityList:GetItem(1) 
			
	if IsInGroup() then
		step = 0
		if StaticPopup1Button2:IsShown() then StaticPopup1Button2:Click() end
		if LFDRoleCheckPopupAcceptButton:IsShown() then LFDRoleCheckPopupAcceptButton:Click() end  
		if PVPMatchResults:IsShown() then PVPMatchResults["leaveButton"]:Click() end 
		return 
	else
		if(step==0) then
			MeetingStone:Toggle()
			BrowsePanel:DoSearch() 
			BrowsePanel.ActivityList:SetSortHandler(function(activity)
               return activity:GetMaxMembers() - activity:GetNumMembers()
			end)
			step=1;
			return
		end
			
		if(step==1) then 
			BrowsePanel.ActivityList:Sort()
			local item = BrowsePanel.ActivityList:GetItem(1) 
			BrowsePanel:SignUp(item)
			step=2
			return
		end
			
		if(step==2) then 
			if  LFGListApplicationDialog.SignUpButton:IsShown() then LFGListApplicationDialog.SignUpButton:Click()  end
			if  LFGListInviteDialog:IsShown() then LFGListInviteDialog.AcceptButton:Click() LFGListInviteDialog.AcknowledgeButton:Click()  end 
			return 
		end 
		 
	end
  
end
	
	