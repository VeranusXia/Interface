
--主宏
local atsBtn = CreateFrame("BUTTON", "HappyATS", nil, "SecureActionButtonTemplate")
atsBtn:SetSize(0,0)
atsBtn:SetAttribute("*type*", "macro") 
function logText(text) 
	print(date("[%H:%M:%S] ")..text)
end
local AutoTradeSkill = CreateFrame("Frame", "AutoTradeSkill", UIParent, "UIPanelDialogTemplate")
local isSellOver = false
local lock = true
 

--主逻辑
function AutoTradeSkill:Action() 
	local free = AutoTradeSkill:checkBagFree()
	 if free > 0  then 
		if  lock and isSellOver then
		  local exAction = "/run C_TradeSkillUI.OpenTradeSkill(197)\n/run C_TradeSkillUI.CraftRecipe(310871,10)\n"
		  AutoTradeSkill:SaveConfig(exAction)
			print("制作中")
		  lock = false 
		 end
	 else
		lock =true
		isSellOver=false
	 end
	 AutoTradeSkill:SellItems()
	 
	 
end
--保存配置 重置宏 /run BuyMerchantItem(1,200)
function AutoTradeSkill:SaveConfig(exAction)
	local runAction = "/run AutoTradeSkill:Action()\n"  
	local macrotxt = runAction..exAction
	 
	atsBtn:SetAttribute("macrotext",macrotxt) 
	--print(macrotxt)
end

function AutoTradeSkill:SellItems()
	
	local free = AutoTradeSkill:checkBagFree()
	if free==0 and lock then
		AutoTradeSkill:SaveConfig("")
		lock = false 
	end


	if isSellOver==false then
		print("出售中")
		isSellOver = AutoTradeSkill:sellItem("173194") 
		if isSellOver then
			lock = true
		end
	end
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
				isOver = false
				UseContainerItem(bag,slot)
			end
		end
	end
	return isOver
end
   
function AutoTradeSkill:GoEvent(event, arg1)  
	if event == "PLAYER_LOGIN" then
		if  not GetMacroInfo("快乐赚钱") then
			CreateMacro("快乐赚钱", "133768", "/click HappyATS", nil, nil) --/dump GetItemIcon(173194)
			logText("初始化快乐赚钱宏")
		end
		if  not GetMacroInfo("半影线") then
			CreateMacro("半影线", "133768", "/run BuyMerchantItem(1,200)", nil, nil)
			logText("初始化购买半影线宏")
		end
	end 
	AutoTradeSkill:SaveConfig("")
end
AutoTradeSkill:RegisterEvent("PLAYER_LOGIN") 
AutoTradeSkill:SetScript("OnEvent", AutoTradeSkill.GoEvent) 

function SlashCmdList.AutoTradeSkill(msg) 

end
SLASH_AutoBattleGround1 = '/ATS'
    
   
    

