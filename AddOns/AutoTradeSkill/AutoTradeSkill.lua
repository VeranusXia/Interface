local itemId = "310871"
--主宏
local atsBtn = CreateFrame("BUTTON", "HappyATS", nil, "SecureActionButtonTemplate")
atsBtn:SetSize(0,0)
atsBtn:SetAttribute("*type*", "macro") 
function logText(text) 
	print(date("[%H:%M:%S] ")..text)
end
local AutoTradeSkill =   = CreateFrame("Frame", "AutoTradeSkill", UIParent, "UIPanelDialogTemplate")
local isSellOver = true
--主逻辑
function AutoTradeSkill:Action()
	 if AutoTradeSkill:checkBagFree() > 0 then 
		if isSellOver then
			PickupSpell(itemId)
		end
	 else
		isSellOver = AutoTradeSkill:sellItem(itemId) 
	 end
  
end
--保存配置 重置宏
function AutoTradeSkill:SaveConfig()
	local runAction = "/run AutoTradeSkill:Action()\n" 
	local macrotxt = runAction
	atsBtn:SetAttribute("macrotext",macrotxt)
end
function AutoTradeSkill:checkBagFree()
		-- Check for free bag space 
	local free=0
	for bag=0,NUM_BAG_SLOTS do
		local bagFree,bagFam = GetContainerNumFreeSlots(bag)
		if bagFam==0 then
			free = free + bagFree
		end
	end 
	return free
end
function AutoTradeSkill:sellItem(itemId)
	local isOver = true
	for bag=0,4 do 
		for slot=1,50 do 
			local i=GetContainerItemLink(bag,slot)
			if i and i:sub(18,23)==itemId then 
				UseContainerItem(bag,slot)
				isOver = false
			end
		end
	end
	return isOver
end
   
function AutoTradeSkill:GoEvent(event, arg1)  
	if event == "PLAYER_LOGIN" then
		if  not GetMacroInfo("快乐赚钱") then
			CreateMacro("快乐赚钱", "310871", "/click HappyATS", nil, nil)
			logText("初始化快乐赚钱宏")
		end
	end 
	AutoTradeSkill:SaveConfig()
end
AutoTradeSkill:RegisterEvent("PLAYER_LOGIN") 
AutoTradeSkill:SetScript("OnEvent", AutoTradeSkill.Init) 

function SlashCmdList.AutoTradeSkill(msg) 

end
SLASH_AutoBattleGround1 = '/ATS'
    
   
    

