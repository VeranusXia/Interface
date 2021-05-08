local Version = "9.0.2"
local tplayerClass; --= string.upper(select(2, UnitClass('player')))
local tnumTabs; --= GetNumTalentTabs();
local tmaintalent=1;
local tname1,tname2;
local tRank={}
local tTalentText={}
local tStance,Tclass
local mediaFolder = "Interface\\AddOns\\Veranus\\"	--..
local NameFont = GameTooltipTextLeft1:GetFont()
local NumbFont = mediaFolder.."impact.ttf"
local NameFS = 17
local NumbFS = 14
local FontF = "THINOUTLINE"
local StatuPoint,StatuRelay,StatuX,StatuY
local StatusToggle=false
local FrameScale=1
local Threshold=0.2
local ConfigData={}
--local LowValue=0
local StandardValue={}
function Monitor(name,value)
    if StandardValue[name] then
    else
        StandardValue[name] =0
    end
    if  StandardValue[name]> value and UnitAffectingCombat("player")  or StandardValue[name]==0 then
        StandardValue[name]=value
    end
    if (value-StandardValue[name])/StandardValue[name] >=tonumber(Threshold) then
        if value%1 ~=0 then value =  format("%.2f",value) end
        return "|cffff0000"..value
    else
        if value%1 ~=0 then value =  format("%.2f",value) end
        return value
    end
end

local backdrop = { --
bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
insets = {left = -1, right = -1, top = -1, bottom = -1},
                }

local PlayAs=2--1:SMelee DPS,2:Spells DPS,3:Healer,4:Plate Tank,5:Hunter,6:Monk Tank,7:Leather Tank,8:AMelee DPS

local enUS={
    ["AttactPower"]="AttactPower",
    ["SpellPower"]="SpellPower",
    ["AttackSpeed"]="AttactSpeed",
    ["Agility"]="Agility",
    ["Strength"]="Strength",
    ["Intellect"]="Intellect",
    ["Armor"]="Armor",
    ["Stagger"]="Stagger",
    ["Crit"]="Crit",
    ["Haste"]="Haste",
    ["Mastery"]="Mastery",
    ["Versatility"]="Versatility",
    ["ManaRegen"]="ManaRegen",
    ["Dodge"]="Dodge",
    ["Parry"]="Parry",
    ["Block"]="Block",
    ["Threshold"]="Threshold",
    ["OK"]="OK",
    }
local zhCN={
    ["AttactPower"]="攻强",
    ["SpellPower"]="法强",
    ["AttackSpeed"]="攻速",
    ["Agility"]="敏捷",
    ["Strength"]="力量",
    ["Intellect"]="智力",
    ["Armor"]="护甲",
    ["Stagger"]="醉拳",
    ["Crit"]="爆击",
    ["Haste"]="急速",
    ["Mastery"]="精通",
    ["Versatility"]="全能",
    ["ManaRegen"]="法力回复",
    ["Dodge"]="躲闪",
    ["Parry"]="招架",
    ["Block"]="格挡",
    ["Threshold"]="阈值",
    ["OK"]="确定",
    }
local L=zhCN

local function GetCurrentInfo()
    --print("Geting")
    tmaintalent=0
    tnumTabs = GetNumSpecializations();
    Stance=GetShapeshiftForm();
    tplayerClass = string.upper(select(2, UnitClass('player')));
    tmaintalent=GetSpecialization();
    if tplayerClass== "DRUID" then    --德鲁伊
        StatuFrame:RegisterEvent("UNIT_AURA")
        if tmaintalent==1 then
            PlayAs=2
        elseif tmaintalent==2 then
            PlayAs=8
        elseif tmaintalent==3 then
            PlayAs=7
        else
            PlayAs=3
        end
    elseif tplayerClass=="PALADIN" then    --圣骑士
        if tmaintalent==1 then
            PlayAs=3
        elseif tmaintalent==2 then
            PlayAs=4
        else
            PlayAs=1
        end
    elseif tplayerClass=="MONK" then    --武僧
        if tmaintalent==1 then
            PlayAs=6
        elseif tmaintalent==2 then
            PlayAs=3
        else
            PlayAs=8
        end
    elseif tplayerClass=="DEMONHUNTER" then    --恶魔猎手
        if tmaintalent==1 then
            PlayAs=8
        else
            PlayAs=7
        end
    elseif tplayerClass=="SHAMAN" then    --萨满祭司
        if tmaintalent==1 then
            PlayAs=2
        elseif tmaintalent==2 then
            PlayAs=8
        else
            PlayAs=3
        end
    elseif tplayerClass=="PRIEST" then    --牧师
        if tmaintalent==3 then
            PlayAs=2
        else
            PlayAs=3
        end
    elseif tplayerClass== "DEATHKNIGHT" then    --死亡骑士
        if tmaintalent==1 then
            PlayAs=4
        else
            PlayAs=1
        end
    elseif tplayerClass=="WARRIOR" then    --战士
        if tmaintalent==3 then
            PlayAs=4
        else
            PlayAs=1
        end
    elseif tplayerClass=="ROGUE" then    --潜行者
        PlayAs=8
    elseif tplayerClass=="HUNTER" then    --猎人
        if tmaintalent==3 then
            PlayAs=8
        else
            PlayAs=5
        end
    elseif tplayerClass=="MAGE" then    --法师
        PlayAs=2
    elseif tplayerClass=="WARLOCK" then    --术士
        PlayAs=2
    end
    -- print("StatuInfo Loaded   "..tplayerClass..","..PlayAs..","..tmaintalent)
end

function updateStatu(playas)
    if PlayAs==1 then    --"SMelee DPS/力量近战输出")
        local base, posBuff, negBuff = UnitAttackPower("player");
        local effective = base + posBuff + negBuff;
        local highHaste = UnitSpellHaste("player");
        local statS, effectiveStatS, posBuffS, negBuffS = UnitStat("player",1);
        statuMain:SetText("|cffff0000"..Monitor(L["AttactPower"],effective))
        statuMainDes:SetText(L["AttactPower"])
		statu2:SetText("|cffff00ff"..effectiveStatS)
        statu2Des:SetText(L["Strength"])
		mainSpeed, offSpeed = UnitAttackSpeed("player");
		if offSpeed then
            statu3:SetText(format("%.2f/%.2f",mainSpeed,offSpeed))
        else
            statu3:SetText(format("%.2f",mainSpeed))
        end
        statu3Des:SetText(L["AttackSpeed"])
        statu4:SetText(format("|cffffff80%.2f%%",GetCritChance()))
		statu4Des:SetText(L["Crit"])
        statu5:SetText(format("|cff00ffff%.2f%%",highHaste))
		statu5Des:SetText(L["Haste"])
        statu6:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
		statu6Des:SetText(L["Mastery"])
		if GetCombatRatingBonus(29)~=0 then
			statu7:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
            statu7Des:SetText(L["Versatility"])
		else
            statu7:SetText()
            statu7Des:SetText()
        end
        statu8:SetText()
        statu8Des:SetText()
    elseif PlayAs==2 then    --"Spells DPS/法术输出")
        local highestdamages = GetSpellBonusDamage(2)
        local highestcrit = GetSpellCritChance(2)
        local highHaste = UnitSpellHaste("player");
        local statA, effectiveStatA, posBuffA, negBuffA = UnitStat("player",4);
        for i=3,7 do
            if(GetSpellBonusDamage(i)>highestdamages) then
				highestdamages=GetSpellBonusDamage(i)
			end
            if(GetSpellCritChance(i)>highestcrit) then
				highestcrit=GetSpellCritChance(i)
			end
        end
        statuMain:SetText("|cffff0000"..Monitor(L["SpellPower"],highestdamages))
        statuMainDes:SetText(L["SpellPower"])
		statu2:SetText("|cffff00ff"..effectiveStatA)
        statu2Des:SetText(L["Intellect"])
        statu3:SetText(format("|cffffff80%.2f%%",highestcrit))
		statu3Des:SetText(L["Crit"])
        statu4:SetText(format("|cff00ffff%.2f%%",highHaste))
		statu4Des:SetText(L["Haste"])
        statu5:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
		statu5Des:SetText(L["Mastery"])
		if GetCombatRatingBonus(29)~=0 then
			statu6:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
			base, casting = GetManaRegen()
			highestdamages = nil
			highestcrit = nil
            statu6Des:SetText(L["Versatility"])
		else
            statu6:SetText()
            statu6Des:SetText()
        end
        statu7:SetText()
        statu7Des:SetText()
        statu8:SetText()
        statu8Des:SetText()
    elseif PlayAs==3 then    --"Healer/治疗")
        local base, casting = GetManaRegen();
        local highHaste = UnitSpellHaste("player");
        local statA, effectiveStatA, posBuffA, negBuffA = UnitStat("player",4);
        statuMain:SetText("|cff00ff00"..Monitor(L["SpellPower"],GetSpellBonusHealing()))
        statuMainDes:SetText(L["SpellPower"])
		statu2:SetText("|cffff00ff"..effectiveStatA)
        statu2Des:SetText(L["Intellect"])
        statu3:SetText(format("|cffffff80%.2f%%",GetSpellCritChance(7)))
        statu3Des:SetText(L["Crit"])
		statu4:SetText(format("|cff00ffff%.2f%%",highHaste))
        statu4Des:SetText(L["Haste"])
		statu5:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
        statu5Des:SetText(L["Mastery"])
		if GetCombatRatingBonus(29)~=0 then
			statu6:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
            statu6Des:SetText(L["Versatility"])
			statu7:SetText(format("|cff0066cc%d",GetManaRegen()*5))
			statu7Des:SetText(L["ManaRegen"])						
		else
			statu6:SetText(format("|cff0066cc%d",GetManaRegen()*5))
			statu6Des:SetText(L["ManaRegen"])
			statu7:SetText()
			statu7Des:SetText()
        end
		statu8:SetText()
		statu8Des:SetText()
    elseif PlayAs==4 then    --"Plate Tank/板甲坦克")
        local baseArmor , effectiveArmor, armor, posBuff, negBuff = UnitArmor("player");
        local statA, effectiveStatA, posBuffA, negBuffA = UnitStat("player",1);
        local highHaste = UnitSpellHaste("player");
        statuMain:SetText("|cff0066cc"..Monitor(L["Armor"],effectiveArmor))
        statuMainDes:SetText(L["Armor"])
        statu2:SetText("|cffff00ff"..Monitor(L["Strength"],effectiveStatA))
        statu2Des:SetText(L["Strength"])
        statu3:SetText(format("|cffcc99cc%.2f%%",GetParryChance()))
        statu3Des:SetText(L["Parry"])
        if GetBlockChance()~=0 then
            statu4:SetText(format("|cffffff33%.2f%%",GetBlockChance()))
            statu4Des:SetText(L["Block"])
            statu5:SetText(format("|cffffff80%.2f%%",GetCritChance()))
            statu5Des:SetText(L["Crit"])
            statu6:SetText(format("|cff00ffff%.2f%%",highHaste))
            statu6Des:SetText(L["Haste"])
            statu7:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
            statu7Des:SetText(L["Mastery"])
			if GetCombatRatingBonus(29)~=0 then
				statu8:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
				statu8Des:SetText(L["Versatility"])
			else
				statu8:SetText()
				statu8Des:SetText()
			end
        else
            statu4:SetText(format("|cffffff80%.2f%%",GetCritChance()))
            statu4Des:SetText(L["Crit"]) 
            statu5:SetText(format("|cff00ffff%.2f%%",highHaste))
            statu5Des:SetText(L["Haste"])
            statu6:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
            statu6Des:SetText(L["Mastery"])
			if GetCombatRatingBonus(29)~=0 then
				statu7:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
				statu7Des:SetText(L["Versatility"])
			else
				statu7:SetText()
				statu7Des:SetText()
			end
            statu8:SetText()
            statu8Des:SetText()
        end
    elseif PlayAs==5 then    --"Hunter/远程输出猎人")
        local base, posBuff, negBuff = UnitRangedAttackPower("player");
        local effective = base + posBuff + negBuff;
        local highHaste = UnitSpellHaste("player");
        local statA, effectiveStatA, posBuffA, negBuffA = UnitStat("player",2);
		statuMain:SetText("|cffff0000"..Monitor(L["AttactPower"],effective))
        statuMainDes:SetText(L["AttactPower"])
        statu2:SetText("|cffff00ff"..effectiveStatA)
        statu2Des:SetText(L["Agility"])
        speed, lowDmg, hiDmg, posBuff, negBuff, percent = UnitRangedDamage("player")
        statu3:SetText(format("%.2f",speed))
        statu3Des:SetText(L["AttackSpeed"])
        statu4:SetText(format("|cffffff80%.2f%%",GetRangedCritChance()))
        statu4Des:SetText(L["Crit"])
        statu5:SetText(format("|cff00ffff%.2f%%",highHaste))
        statu5Des:SetText(L["Haste"])
        statu6:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
        statu6Des:SetText(L["Mastery"])
		if GetCombatRatingBonus(29)~=0 then
			statu7:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
            statu7Des:SetText(L["Versatility"])
		else
            statu7:SetText()
            statu7Des:SetText()
        end
        statu8:SetText()
        statu8Des:SetText()
    elseif PlayAs==6 then    --"Monk Tank/武僧酒仙")
        local baseArmor , effectiveArmor, armor, posBuff, negBuff = UnitArmor("player");
        local statA, effectiveStatA, posBuffA, negBuffA = UnitStat("player",2);
        local highHaste = UnitSpellHaste("player");
        local unkonwnA, columnA = GetTalentTierInfo(7,1);
        local effectiveAg = 0;
        local BrewK1 = 1.0;
        local BrewK2 = 1.0;
        local BrewK3 = 1.0;
        local kn=1;
        local effective;
        local stagger = UnitStagger("player")
        local a,ar,kn =select(2,UnitArmor("player")),C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(select(2,UnitArmor("player")));
        local baseStagger, targetStagger = C_PaperDollInfo.GetStaggerPercentage("player");
        if UnitExists("target") then
			effective = targetStagger
        else
			effective = baseStagger
        end
        --       if ar then 
        --         kn = a/ar-a
        --       else 
        --         kn=6300
        --       end
        --       for i=1,40 do
        --         local nameB, iconB, _, _, _, etimeB = UnitBuff("player",i)
        --           if nameB == "铁骨酒" then
        --             BrewK1=3.5 --铁骨酒
        --           end
        --       end
        --       for i=1,40 do
        --         local nameC, iconC, _, _, _, etimeC = UnitBuff("player",i)
        --           if nameC == "壮胆酒" then
        --             BrewK2=1.5 --壮胆酒
        --           end
        --       end
        --       if columnA == 1 then
        --         BrewK3=1.4 --坚定不屈
        --       end
        --effectiveAg = 1.05*BrewK1*BrewK2*BrewK3*effectiveStatA;
        --local kn = 6300 --Kn值  --1423-110   2107-113  2595-116  6300-120
        --local effective = 100*effectiveAg / (effectiveAg+kn);
        statuMain:SetText(format("|cffffff33%.2f%%",effective))
        statuMainDes:SetText(L["Stagger"])
        statu2:SetText("|cff0066cc"..Monitor(L["Armor"],effectiveArmor))
        statu2Des:SetText(L["Armor"])
        statu3:SetText("|cffff00ff"..Monitor(L["Agility"],effectiveStatA))
        statu3Des:SetText(L["Agility"])
        statu4:SetText(format("|cffffffcc%.2f%%",GetDodgeChance()))
        statu4Des:SetText(L["Dodge"])
        statu5:SetText(format("|cffffff80%.2f%%",GetCritChance()))
        statu5Des:SetText(L["Crit"])
        statu6:SetText(format("|cff00ffff%.2f%%",highHaste))
        statu6Des:SetText(L["Haste"])
        statu7:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
        statu7Des:SetText(L["Mastery"])
		if GetCombatRatingBonus(29)~=0 then
			statu8:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
            statu8Des:SetText(L["Versatility"])
		else
            statu8:SetText()
            statu8Des:SetText()
        end
    elseif PlayAs==7 then    --"Leather Tank/皮甲坦克")
        local baseArmor , effectiveArmor, armor, posBuff, negBuff = UnitArmor("player");
        local statA, effectiveStatA, posBuffA, negBuffA = UnitStat("player",2);
        local highHaste = UnitSpellHaste("player");
		statuMain:SetText("|cff0066cc"..Monitor(L["Armor"],effectiveArmor))
        statuMainDes:SetText(L["Armor"])
        statu2:SetText("|cffff00ff"..Monitor(L["Agility"],effectiveStatA))
        statu2Des:SetText(L["Agility"])
        statu3:SetText(format("|cffffffcc%.2f%%",GetDodgeChance()))
        statu3Des:SetText(L["Dodge"])
        if GetParryChance()~=0 then
            statu4:SetText(format("|cffcc99cc%.2f%%",GetParryChance()))
            statu4Des:SetText(L["Parry"])
            statu5:SetText(format("|cffffff80%.2f%%",GetCritChance()))
            statu5Des:SetText(L["Crit"])
            statu6:SetText(format("|cff00ffff%.2f%%",highHaste))
            statu6Des:SetText(L["Haste"])
            statu7:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
            statu7Des:SetText(L["Mastery"])
			if GetCombatRatingBonus(29)~=0 then
				statu8:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
				statu8Des:SetText(L["Versatility"])
			else
				statu8:SetText()
				statu8Des:SetText()
			end
        else
            statu4:SetText(format("|cffffff80%.2f%%",GetCritChance()))
            statu4Des:SetText(L["Crit"]) 
            statu5:SetText(format("|cff00ffff%.2f%%",highHaste))
            statu5Des:SetText(L["Haste"])
            statu6:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
            statu6Des:SetText(L["Mastery"])
			if GetCombatRatingBonus(29)~=0 then
				statu7:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
				statu7Des:SetText(L["Versatility"])
			else
				statu7:SetText()
				statu7Des:SetText()
			end
            statu8:SetText()
            statu8Des:SetText()
        end
    elseif PlayAs==8 then    --"AMelee DPS/敏捷近战输出")
        local base, posBuff, negBuff = UnitAttackPower("player");
        local effective = base + posBuff + negBuff;
        local highHaste = UnitSpellHaste("player");
        local statA, effectiveStatA, posBuffA, negBuffA = UnitStat("player",2);
        statuMain:SetText("|cffff0000"..Monitor(L["AttactPower"],effective))
        statuMainDes:SetText(L["AttactPower"])
		statu2:SetText("|cffff00ff"..effectiveStatA)
        statu2Des:SetText(L["Agility"])
		mainSpeed, offSpeed = UnitAttackSpeed("player");
        if offSpeed then
            statu3:SetText(format("%.2f/%.2f",mainSpeed,offSpeed))
        else
            statu3:SetText(format("%.2f",mainSpeed))
        end
		statu3Des:SetText(L["AttackSpeed"])
		statu4:SetText(format("|cffffff80%.2f%%",GetCritChance()))
        statu4Des:SetText(L["Crit"])
		statu5:SetText(format("|cff00ffff%.2f%%",highHaste))
        statu5Des:SetText(L["Haste"])
		statu6:SetText(format("|cff8080ff%.2f%%",GetMasteryEffect()))
        statu6Des:SetText(L["Mastery"])
		if GetCombatRatingBonus(29)~=0 then
			statu7:SetText(format("|cffff8000%.2f%%",GetCombatRatingBonus(29)))
            statu7Des:SetText(L["Versatility"])
		else
            statu7:SetText()
            statu7Des:SetText()
        end
        statu8:SetText()
        statu8Des:SetText()
    end
end

StatusSave_Default={
    ["Point"]="CENTER",
    ["Relay"]="CENTER",
    ["Xpos"]="-260",
    ["Ypos"]="0",
    ["Scale"]="1",
    ["Threshold"]="0.2",
    ["Version"]=Version,
    }

local StatuFrame=CreateFrame("Frame", "StatuFrame", UIParent, "BackdropTemplate")
	StatuFrame:SetWidth(100)
	StatuFrame:SetHeight(60)
	--StatuFrame:SetAlpha(0.9)
	--StatuFrame:SetPoint("CENTER",-260,0)
	--StatuFrame:SetBackdrop(backdrop)
	--StatuFrame:SetBackdropColor(0, 0, 0, 1)
	StatuFrame:Show()
	StatuFrame:SetScale(1)
	statuMain=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statuMain:SetFont(NumbFont, NumbFS*1.8, FontF)
	statuMain:SetPoint('TOPRIGHT', StatuFrame, 'TOPRIGHT', 0, 20)
	statuMain:SetJustifyH('RIGHT')
	statu2=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu2:SetFont(NameFont, NumbFS*1.1, FontF)
	statu2:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, 54)
	statu2:SetJustifyH('RIGHT')
	statu3=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu3:SetFont(NameFont, NumbFS*1.1, FontF)
	statu3:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, 36)
	statu3:SetJustifyH('RIGHT')
	statu4=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu4:SetFont(NameFont, NumbFS*1.1, FontF)
	statu4:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, 18)
	statu4:SetJustifyH('RIGHT')
	statu5=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu5:SetFont(NameFont, NumbFS*1.1, FontF)
	statu5:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, 0)
	statu5:SetJustifyH('RIGHT')
	statu6=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu6:SetFont(NameFont, NumbFS*1.1, FontF)
	statu6:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, -18)
	statu6:SetJustifyH('RIGHT')
	statu7=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu7:SetFont(NameFont, NumbFS*1.1, FontF)
	statu7:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, -36)
	statu7:SetJustifyH('RIGHT')
	statu8=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu8:SetFont(NameFont, NumbFS*1.1, FontF)
	statu8:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, -54)
	statu8:SetJustifyH('RIGHT')
	statu9=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu9:SetFont(NameFont, NumbFS*1.1, FontF)
	statu9:SetPoint('TOPRIGHT', StatuFrame, 'BOTTOMRIGHT', 10, -72)
	statu9:SetJustifyH('RIGHT')
	--Describe--
	statuMainDes=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statuMainDes:SetFont(NameFont, NumbFS*1.4, FontF)
	statuMainDes:SetPoint('BOTTOMLEFT', statuMain, 'BOTTOMRIGHT', 0, 0)
	statuMainDes:SetJustifyH('LEFT')
	statu2Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu2Des:SetFont(NameFont, NumbFS*1, FontF)
	statu2Des:SetPoint('BOTTOMLEFT', statu2, 'BOTTOMRIGHT', 0, 0)
	statu2Des:SetJustifyH('LEFT')
	statu3Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu3Des:SetFont(NameFont, NumbFS*1, FontF)
	statu3Des:SetPoint('BOTTOMLEFT', statu3, 'BOTTOMRIGHT', 0, 0)
	statu3Des:SetJustifyH('LEFT')
	statu4Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu4Des:SetFont(NameFont, NumbFS*1, FontF)
	statu4Des:SetPoint('BOTTOMLEFT', statu4, 'BOTTOMRIGHT', 0, 0)
	statu4Des:SetJustifyH('LEFT')
	statu5Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu5Des:SetFont(NameFont, NumbFS*1, FontF)
	statu5Des:SetPoint('BOTTOMLEFT', statu5, 'BOTTOMRIGHT', 0, 0)
	statu5Des:SetJustifyH('LEFT')
	statu6Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu6Des:SetFont(NameFont, NumbFS*1, FontF)
	statu6Des:SetPoint('BOTTOMLEFT', statu6, 'BOTTOMRIGHT', 0, 0)
	statu6Des:SetJustifyH('LEFT')
	statu7Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu7Des:SetFont(NameFont, NumbFS*1, FontF)
	statu7Des:SetPoint('BOTTOMLEFT', statu7, 'BOTTOMRIGHT', 0, 0)
	statu7Des:SetJustifyH('LEFT')
	statu8Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu8Des:SetFont(NameFont, NumbFS*1, FontF)
	statu8Des:SetPoint('BOTTOMLEFT', statu8, 'BOTTOMRIGHT', 0, 0)
	statu8Des:SetJustifyH('LEFT')
	statu9Des=StatuFrame:CreateFontString(nil, 'OVERLAY')
	statu9Des:SetFont(NameFont, NumbFS*1, FontF)
	statu9Des:SetPoint('BOTTOMLEFT', statu9, 'BOTTOMRIGHT', 0, 0)
	statu9Des:SetJustifyH('LEFT')
	--StatuFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED",GetCurrentInfo())
	--StatuFrame:RegisterEvent("PLAYER_TALENT_UPDATE",GetCurrentInfo())
	StatuFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	StatuFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
	StatuFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	StatuFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	StatuFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	StatuFrame:RegisterEvent("ADDON_LOADED")
	StatuFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	StatuFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	--StatuFrame:RegisterEvent("UNIT_AURA")
	StatuFrame:SetScript("OnEvent", function(self, event)
    if  event=="UNIT_AURA" or event == "PLAYER_ENTERING_WORLD"then
        if  not StatusSave or not StatusSave["Version"] or StatusSave["Version"]~= Version then
            StatusSave=StatusSave_Default;
            for i =1,5 do
                StatusSave[i]={}
            for j = 1,5 do
                StatusSave[i][j]=1;
            end
        end
    end
    GetCurrentInfo()
    elseif event=="ACTIVE_TALENT_GROUP_CHANGED" or event=="PLAYER_TALENT_UPDATE"or event=="PLAYER_EQUIPMENT_CHANGED" or event=="UPDATE_SHAPESHIFT_FORM"   then
        for k, v in pairs(StandardValue) do
			StandardValue[k]=0
        end
    GetCurrentInfo()
--    FreshStatuLine()--662行报错暂时解决
    elseif event=="PLAYER_REGEN_DISABLED" then
        UIFrameFadeOut(StatuFrame, 1, 0.2, 0.8)
    elseif event=="PLAYER_REGEN_ENABLED" then
        UIFrameFadeOut(StatuFrame, 1, 0.8, 0.5)
    elseif event=="ADDON_LOADED" then
        if  not StatusSave or not StatusSave["Version"] or StatusSave["Version"]~= Version then
            StatusSave=StatusSave_Default;
            for i =1,5 do
                StatusSave[i]={}
            for j = 1,5 do
                StatusSave[i][j]=1;
            end
        end
    end
        StatuPoint=StatusSave["Point"]
        StatuRelay=StatusSave["Relay"]
        StatuX=StatusSave["Xpos"]
        StatuY=StatusSave["Ypos"]
        Lang=StatusSave["language"]
        FrameScale=StatusSave["Scale"]
        Threshold=StatusSave["Threshold"]
	if ( GetLocale() == "zhCN" ) then
        L=zhCN
    else
		L=enUS
    --GetCurrentInfo()
    end
        --print(StatuPoint,StatuRelay,StatuX,StatuY)
        StatuFrame:SetPoint(StatuPoint,nil,StatuRelay,StatuX,StatuY)
        StatuFrame:SetScale(FrameScale)
        StatuFrame:Show()
    end
end);
local TimeSinceLastUpdate=0;
local f = CreateFrame("frame",nil, UIParent);
    f:SetScript("OnUpdate", function(self, elapsed)
    TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
    if (TimeSinceLastUpdate > 0.5) then
        if tnumTabs==0 then
			GetCurrentInfo()
		end
        updateStatu(PlayAs or 1)
        TimeSinceLastUpdate = 0;
    end
end);
--GetCurrentInfo()
    SLASH_STATUSMOVE1 = "/status"
    SlashCmdList["STATUSMOVE"] = function(msg)
--    msg = strtrim(msg or "")
    if StatusToggle then
        StatuPoint,relativeTo,StatuRelay,StatuX,StatuY	=StatuFrame:GetPoint()
        StatusSave["Point"]=StatuPoint
        StatusSave["Relay"]=StatuRelay
        StatusSave["Xpos"]=StatuX
        StatusSave["Ypos"]=StatuY
        StatusSave["Scale"]=FrameScale
        StatuFrame:EnableMouse(false)
        StatuFrame:SetMovable(false)
        StatuFrame:SetBackdropColor(0, 0, 0, 0)
        UIFrameFadeOut(StatuFrame, 1, 0.8, 0.2)
        StatusToggle=false
        StatuFrame:EnableMouseWheel(false);
        StatuFrame:SetScript("OnMouseWheel", nil);
    else
        StatuFrame:EnableMouse(true)
        StatuFrame:SetMovable(true)
        StatuFrame:SetBackdrop(backdrop)
        StatuFrame:SetBackdropColor(0, 0, 0, 1)
        UIFrameFadeOut(StatuFrame, 1, 0.2, 1)
        StatuFrame:SetScript("OnMouseDown", StatuFrame.StartMoving)
        StatuFrame:SetScript("OnMouseUp", StatuFrame.StopMovingOrSizing)
        StatusToggle=true
        StatuFrame:EnableMouseWheel();
        StatuFrame:SetScript("OnMouseWheel", function(self, direction)
        if(direction > 0) then
            FrameScale=FrameScale+0.05
            StatuFrame:SetScale(FrameScale)
        else
            FrameScale=FrameScale-0.05
            StatuFrame:SetScale(FrameScale)
        end
    end);
end
end
--MainMenuBarArtFrame.LeftEndCap:SetTexture("") 
--MainMenuBarArtFrame.RightEndCap:SetTexture("")