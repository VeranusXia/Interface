 
local start = false  
local classSpell ={
		["WARRIOR"] = "/cast 死亡之愿\n/cast 血性狂暴\n",--Warrior 
	["PALADIN"] = "/targetfriendplayer\n/castsequence 神圣震击,圣光闪现,圣光闪现,神圣震击,圣光闪现,圣光闪现,神圣震击,圣光闪现,圣光闪现,神圣震击,正义盾击\n/cast [target=player]圣光道标\n",--Paladin
	["HUNTER"] = "/cast 意气风发\n", --Hunter
	["ROGUE"] = "/cast 猩红之瓶\n/cast [nostealth,nocombat] 潜行\n", --Rogue
	["PRIEST"] = "/targetenemy\n/cast 绝望祷言\n/cast 真言术：盾\n",--Priest
	["DEATHKNIGHT"] = "/cast 天灾契约\n/cast 亡者复生\n/castsequence 寒冬号角,牺牲契约\n", --DeathKnight
	["SHAMAN"] = "/cast 血肉铸造\n", --Shaman
	["MAGE"] = "/castsequence 寒冰护体,寒冰宝珠\n", --Mage
	["WARLOCK"] = "/castsequence 黑暗契约,制造治疗石\n/use 治疗石\n",--Warlock
	["MONK"] = "/cast 天神酒\n/cast 金创药\n",--Monk
	["DRUID"] = "/cast 血肉铸造\n",--Druid
	["DEMONHUNTER"] = "",--Demon Hunter
}
local _, className, index = UnitClass("player"); --检测职业
local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[className]
local pr= UnitName("player") .. "-" .. GetRealmName()
local macrotxt = ""
local readyCheck=false
local queueCheck=true

local piaobtn =  CreateFrame("BUTTON", "piaobtn", UIParent, "BackdropTemplate")
piaobtn:SetSize(50, 50)
piaobtn:SetBackdrop({bgFile = "Interface\\AddOns\\AutoArena\\AutoArena"})
piaobtn.Text = piaobtn:CreateFontString(nil, "OVERLAY") -- 为Frame创建一个新的文字层
piaobtn.Text:SetFont(STANDARD_TEXT_FONT, 14, "THINOUTLINE") -- 设置字体路径, 大小, 描边
piaobtn.Text:SetText("竞") -- 设置材质路径 
piaobtn.Text:SetPoint("CENTER", piaobtn)
piaobtn:SetClampedToScreen(true)
piaobtn:SetPoint("TOPLEFT", 350, 0)
piaobtn:SetBackdropColor(color.r, color.g, color.b)
piaobtn:SetMovable(true)
piaobtn:EnableMouse(true) 
piaobtn:RegisterForDrag("LeftButton")
piaobtn:SetScript("OnDragStart", piaobtn.StartMoving)
piaobtn:SetScript("OnDragStop", piaobtn.StopMovingOrSizing)
piaobtn:SetScript("OnClick", function() 
	AutoArena:Toggle()
end)

--主面板
local AutoArena = CreateFrame("Frame", "AutoArena", UIParent, "UIPanelDialogTemplate")
AutoArena.Title:SetTextColor(1,1,1)
AutoArena.Title:SetText("艾泽拉斯科学研究院自助竞技场小助手 by 微微")
AutoArena.Title:SetFont(STANDARD_TEXT_FONT, 12, "THINOUTLINE")
AutoArena:SetSize(350, 250) 
AutoArena:SetClampedToScreen(true)
AutoArena:SetFrameStrata("DIALOG")
AutoArena:SetPoint("TOPLEFT", 300, 0)   
AutoArena:SetMovable(true)
AutoArena:EnableMouse(true) 
AutoArena:RegisterForDrag("LeftButton")
AutoArena:SetScript("OnDragStart", AutoArena.StartMoving)
AutoArena:SetScript("OnDragStop", AutoArena.StopMovingOrSizing)
AutoArena:SetScript("OnHide", function()
	piaobtn:Show()
end) 
AutoArena:SetScript("OnShow", function()
	if piaobtn:IsShown() then
		piaobtn:Hide()
	end
end) 

--主宏
local PVPBtn = CreateFrame("BUTTON", "HappyArena", nil, "SecureActionButtonTemplate")
PVPBtn:SetSize(0,0)
PVPBtn:SetAttribute("*type*", "macro") 
 

--第一行
local line1 = CreateFrame("Frame", nil, AutoArena)
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
		logText("竞技场小助手启动!")
		resetButton.Text:SetText("关闭插件")
	else
		start = false
		logText("竞技场小助手关闭!")
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
local line2 = CreateFrame("Frame", nil, AutoArena)
line2:SetSize(330,40) 
line2:SetPoint("TOP",   0, -80) 

 


local itemsk = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")
local item22 = CreateFrame("CheckButton", nil, line2, "UICheckButtonTemplate")


itemsk.text = itemsk:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemsk.text:SetPoint("LEFT", itemsk, "RIGHT", 0, 1)
itemsk:SetPoint("LEFT", 5, 0)
itemsk.text:SetText("练习赛")
itemsk:SetScript("OnClick", function() 
	item22:SetChecked(false)
	SaveConfig() 
end)

item22.text = item22:CreateFontString(nil, "OVERLAY", "GameFontNormal")
item22.text:SetPoint("LEFT", item22, "RIGHT", 0, 1)
item22:SetPoint("LEFT", 110, 0)
item22.text:SetText("竞技场")    
item22:SetScript("OnClick", function() 
	itemsk:SetChecked(false)
	SaveConfig() 
end)



---第三行
local line3 = CreateFrame("Frame", nil, AutoArena)
line3:SetSize(330,40) 
line3:SetPoint("TOP",   0, -120) 
 


local line4 = CreateFrame("Frame", nil, AutoArena)
line4:SetSize(330,40) 
line4:SetPoint("TOP",   0, -160) 
 




--第N行 显示log
local content = CreateFrame("Frame", nil, AutoArena)
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
	if UnitAffectingCombat("player") then  return end
	local useclassSpell =  classSpell[className]  
	local runAction = "/run AutoArena:Action()\n"
	local enterMarco = readyCheck and "/click PVPReadyDialogEnterBattleButton\n" or ""
	local skirmish = itemsk:GetChecked() and "/run JoinSkirmish(4)\n" or ""
	local btn2v2 = item22:GetChecked() and "/run TogglePVPUI()\n/click PVPQueueFrameCategoryButton2\n/click ConquestJoinButton\n" or ""
	
	local queued =  queueCheck and  skirmish..btn2v2 or ""
	macrotxt=  queued..useclassSpell..runAction..enterMarco
	PVPBtn:SetAttribute("macrotext",macrotxt)
	if normal==nil then
		logText("AutoArena配置成功")
	end 
	--print(macrotxt)
end

 

--主逻辑
function AutoArena:Action()
	if not start then
		-- start = true
		logText("插件未启动,请在主面板启动插件!")
		return
	end
	
	local _, instanceType = IsInInstance()
	local IsInBG = instanceType=="arena"
	if IsinBG then 
		readyCheck = false
	elseif queueCheck then
		SetPVPRoles(false,true,true)
		-- if itemsk:GetChecked() then
			-- JoinSkirmish(4)
		-- end
		
	end
		SaveConfig(0)
end

function AutoArena:Toggle()
	if AutoArena:IsShown() then
		AutoArena:Hide()  
	else
		AutoArena:Show()  
	end

end






function SlashCmdList.AutoArena(msg)
	AutoArena:Toggle()
end
SLASH_AutoArena1 = '/AutoArena'
SLASH_AutoArena2 = '/aa'




 
 
function AutoArena_CreateMinimapButton()
	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("AutoArena", {
        type = "launcher",
        label = "快乐竞技场",
        icon = 1322720,
        iconCoords = {0.08, 0.92, 0.08, 0.92},
        OnClick = function(s,b) AutoArena:Toggle() end,
		OnTooltipShow = function(tooltip) tooltip:AddLine("快乐竞技场", 1, 1, 1, 1) end
    })
    LibStub("LibDBIcon-1.0"):Register("AutoArena", ldb);
end
 
function AutoArena:Init() 
 
	if  not GetMacroInfo("快乐竞技场") then
		CreateMacro("快乐竞技场", "1322720", "/click HappyArena", nil, nil)
		logText("初始化快乐竞技场宏")
	end

	SaveConfig()
	AutoArena_CreateMinimapButton()
	AutoArena:Toggle()
end 

local aaEvent = CreateFrame("Frame")
aaEvent:RegisterEvent("PLAYER_LOGIN") 
aaEvent:SetScript("OnEvent", AutoArena.Init) 





local gnumBase = 0;
local aaPVPmatch = CreateFrame("Frame")
aaPVPmatch:RegisterEvent("PVP_MATCH_COMPLETE") 
aaPVPmatch:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")  
function aaPVPmatch:OnEvent(event, arg1)  
	if start then
		
		
		if event == "PVP_MATCH_COMPLETE" then
			ConfirmOrLeaveBattlefield()	
			logText("退出竞技场") 
			queueCheck = true
			return
		end
		
		
		if event=="UPDATE_BATTLEFIELD_STATUS" then
			local status = GetBattlefieldStatus(arg1);
			if status=="confirm" and readyCheck==false then
				readyCheck=true
				SaveConfig(0)
			else
				if status =="queued" then
					queueCheck=false
					SaveConfig(0)
				end
				if readyCheck then
					readyCheck=false
					SaveConfig(0)
				end
			end
			
		end
	end
end
aaPVPmatch:SetScript("OnEvent", aaPVPmatch.OnEvent);
 


LFDRoleCheckPopup:SetScript("OnShow",function() 
	if start then
		LFDRoleCheckPopupAccept_OnClick()
		logText("确认职责")
	end
end)

