local Version = "8.3b"
--local MyLocale		--"enUS" etc
--local MyLocaleFont

--Globals

local Event={}		--events
local E,D,A		--frames for events, main display, abilities
local S			--PetScan saved variables
--	x,y		coordinates of top-left corner
--	height		window-height
--	alpha		opacity
--	overlayJnl	whether pinned to pet-journal
--	visible		whether currently visible in pet-journal
--	fontHt		font-height in points
--	formula		whether to display formula in ability-tooltip
--	embedded	whether to display embedded functions in ability-tooltip
--	bpb		whether to check data against addon 'Battle Pet BreedID'
--	plus		whether to display debug-messages
--	merged		whether reporting merged breeds instead of all
--	sspid		whether to <Clear> to unowned unownable sorted by species#
--	species		ex SpeciesMenu
--	spid		clicked species
--	spec		pattern-match on pet-name
--	abil		pattern-match on ability-name
--	families	select these families
--	pets		select pets as in PetMenu
--	minSpeed	selected minimum pet-speed
--	level		selected pet-level
--	sources		selected sources
--	abilities	PetScanFormulas selections, nil if ALL, [j]=nil if NONE
--	ability		clicked ability
--	cooldowns	cooldowns of selected abilities
--	nturns		no of turns ..
--	dmgTypes	damage-types ..
--	variance	variances ..
--	hit		hit-chances ..
--	bomb		exclude bombs
--	dot		exclude dots
--	ot		over-time #rounds
--	petColumn	sort-column for pets
--	petReversed	whether sort-column reversed
--	topPet		top pet-line displayed (offset from 0)
--	abColumn	sort-column for abilities
--	abReversed	whether sort-column reversed
--	topAb		top ability-line displayed (offset from 0)

local LineCnt		--no of lines per page (=S.height/Line_HT)
local LoadPending	--if positive, then load database on next report-action

--lua

local YES = true
local NO = false

local function must(a,i)
	if not rawget(a,i) then rawset(a,i,{}) end
	return a[i]
end

local function roundFmt(r)
	return tonumber(string.format("%.0f", r))
end

local function round(r)
	return floor(r+.5)
end

local function roundp(r)
	return floor(r+.49)	--usually 0.5 is rounded down but occasionally it is rounded up (e.g. common 1711 PB SkyhornNestling)
end

local function round10(i)
	return floor(i/10)*10
end

local function enk(r)	--return 123 or 1.2K or 123K
	return	r == 0 and ""
	or	r < 1000 and round(r)
	or	r < 10000 and (round(r/100)/10).."K"
	or	round(r/1000).."K"
end

local function has(e,v,...)
	if v then
		return e==v or has(e,...)
	end
end

local function inside(t,v,...)
	if v then
		return t[v] or inside(t,...)
	end
end

local function posn(a,e)
	for k,v in ipairs(a) do
		if v==e then return k end
	end
end

local function tcopy(s,t)	--copy a table, possibly containing tables
	for k,v in pairs(s) do
		if type(v)=="table" then
			t[k] = {}
			tcopy(v,t[k])
		else
			t[k]=v
		end
	end
end

local function dumpArray(t)
	local s="{"
	for k,v in ipairs(t) do
		s = s..(k==1 and "" or ",")..v
	end
	return s.."}"
end

local function bif(p,x,y)	--if-then-else returning a value for simple boolean x,y
	if p then return x else return y end
end

local function tableCount(t)
	local n=0
	for _ in pairs(t) do
		n=n+1
	end
	return n
end

local function apply(t,x,...)	--t(x1..xn) = t[xn]..[x1]
	if x then
		return apply(t,...)[x]
	else
		return t
	end
end

--API

local RED=	"|cffff0000"
local LIGHTBLUE="|cff00ccff"

local CUNOWNED=	"|cffe6cc80"
local CUNOWNEDrgb= {r=0xe6/0xff,g=0xcc/0xff,b=0x80/0xff}
local CUNBRED=	"|cff292e37"

local NARROW_FONT="Fonts/ArialN.ttf"

local function warn(s)
	PlaySound(SOUNDKIT.RAID_WARNING)
	RaidNotice_AddMessage(RaidWarningFrame, s, ChatTypeInfo.RAID_WARNING)
end

local function prt(...)
	if S.plus then print(...) end
end

local function fromRGB(rgb)
	return string.format("|cff%02x%02x%02x", rgb.r*0xff, rgb.g*0xff, rgb.b*0xff)
end

local function toRGB(colour)
	local function f(i)
		local s = strsub(colour,i,i+1)
		if s~="" then return tonumber(s,0x10),f(i+2) end
	end
	return f(5)
end

local function qualityColour(quality)
	return quality and fromRGB(ITEM_QUALITY_COLORS[quality]) or CUNOWNED
end

local function qualityColourRGB(quality)
	local rgb = quality and ITEM_QUALITY_COLORS[quality] or CUNOWNEDrgb
	return rgb.r, rgb.g, rgb.b
end

local function tip(f,s)
        f:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
		GameTooltip:SetText(s)
		GameTooltip:Show()
	end)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

 --[[ Timer
More efficient than C_Timer.NewTimer since only one (C_Timer.after) timer is active,
but timeout-time may exceed request by 100%.  And much more efficient than OnUpdate.
--]]

local WaitFunc	--callback function if timer is active, else nil
local WaitSecs	--action on timeout - nil:cancel, 0:WaitFunc, >0:wait <WaitSecs>

local function OnExpiry()	--callback function on timer-expiry
	if not WaitSecs then
		WaitFunc = nil
	elseif WaitSecs==0 then
		local f = WaitFunc
		WaitFunc = nil
		f()
	else
		local sec = WaitSecs
		WaitSecs = 0
		C_Timer.After(sec, OnExpiry)
	end
end

local function wait(sec, f)	--extend time if already waiting, or schedule f otherwise
	if WaitFunc then
		WaitSecs = sec
		WaitFunc = f
	else
		WaitFunc = f
		WaitSecs = 0
		C_Timer.After(sec, OnExpiry)
	end
end

local function cancelWait()
	WaitSecs = nil
end

--[[ Menus

The following functions are exported:
frameMenu(menu)			--construct the menu-frames
popupMenu(menu,hasPoints)	--display popup-menu - at cursor unless already hasPoints
closeMenu(m)			--otherwise closes automatically on timeout
refreshMenu(menu)		--refresh the menu-lines (occasionally called explicitly)
subcheckedMenu(menu)		--whether all subordinates are checked
menuPath(m)			--the path from menu-line m back to root

Pass the function "frameMenu" an array of records with these fields (all but the first optional):
1	display-text (displayed grey if unclickable, purple if uncheckable, green/red if checked/unchecked)
2	check-action function (nil if unclickable info-only), with menuline-frame as argument
3	checked-test function (nil if uncheckable), with menuline-frame as argument
	(if inferred from subordinate checked lines then the 2nd return-element is YES if a subordinate is checked)
menu	submenu (displays arrow to popup-submenu)
icon	icon (displayed before text if specified)
tip	tooltip

The function "frameMenu" adds these static fields to each menu:
frame	its menu-frame
lparent	its parent menu-line (nil at top level)

.. and these static fields to each menu-line:
frame	its frame within its parent-menu
parent	its parent-menu
l	its line-number

.. and maintains these dynamic fields for each menu-line:
checked	whether the line is checked (if checkable) -> YES/NO/AMBER
ambi	whether the line is a submenu with both checked and unchecked sublines

UIDropDownMenu_AddButton/Easymenu taints UI, blocking BG-queuing.
--]]

local MENU_HT = 16	--add a 2-bit filler to UIDropDownMenu's 16 for clarity
local MTEXT,MCHECK,MCHECKED=1,2,3

local MenuList={}	--array of all menus created
local MenuShown		--outermost menu shown
local Menuline		--currently selected menu-line

local function menuPath(m)	--the path from menu-line m back to root
	if m then
		return m.l, menuPath(m.parent.lparent)
	end
end

local function hideMenu(m)	--hide any MenuShown-ancestor not parental to menu-m or Menuline
	local menu
	if m then
		menu = m.lparent and m.lparent.parent
	elseif Menuline then
		menu = Menuline.parent
	end
	while MenuShown do
		if MenuShown==menu then break end
		MenuShown.frame:Hide()
		MenuShown = MenuShown.lparent and MenuShown.lparent.parent
	end
end

local function closeMenu(m)
	cancelWait()
	hideMenu(m)
end

local function shadeMenupath(m)
	local mm = m or Menuline
	while mm do
		mm.bg:SetAlpha(m and .75 or 1)
		mm = mm.parent.lparent
	end
	Menuline = m
end

local function checkMenuline(m,checked)
	if checked then
		m.bg:SetColorTexture(0, .25, 0)
		m.box:SetTexture("Interface/Common/UI-DropDownRadioChecks")
		m.box:SetTexCoord(0,.5,0,.5)
	else
		m.bg:SetColorTexture(.5, 0, 0)
		m.box:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcon_7")
		m.box:SetTexCoord(0,1,0,1)
	end
	m.checked = checked
end

local function subcheckedMenu(menu)	--derive the menu's <checked,ambi> from its subordinate lines
	local function ch(menu)
		local checkedFound,uncheckedFound
		for _,m in ipairs(menu) do if m[MCHECKED] then
			if m.menu then
				local c,u = ch(m.menu)
				if c then checkedFound = YES end
				if u then uncheckedFound = YES end
			else
				if m[MCHECKED](m) then
					checkedFound = YES
				else
					uncheckedFound = YES
				end
			end
		end end
		return checkedFound,uncheckedFound
	end
	local checkedFound,uncheckedFound = ch(menu)
	return not uncheckedFound, checkedFound and uncheckedFound
end

local function refreshMenu(menu)	--refresh menu by calling MCHECKED functions
	for _,m in ipairs(menu) do if m[MCHECKED] then
		local checked,ambi = m[MCHECKED](m)
		if m.arrow and (ambi or NO) ~= (m.ambi or NO) then	--m.arrow nil after right-click Abilities when just one menu-suboption selected
			m.arrow:SetTexture(ambi
				and "Interface/Icons/ability_mount_whitedirewolf"
				or "Interface/ChatFrame/ChatFrameExpandArrow")
			m.ambi = ambi
		end
		checked = checked and YES or NO
		if checked ~= m.checked then
			checkMenuline(m, checked)
		end
	end end
end

local function popupMenu(menu,hasPoints)	--display popup <menu> - at cursor unless already hasPoints
	if not hasPoints then
		local x,y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		menu.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/scale+3, y/scale-3)
	end
	refreshMenu(menu)
	closeMenu(menu)
	MenuShown = menu
	menu.frame:Show()
end

local function frameMenu(menu,lparent)
	local mf = CreateFrame("Frame", nil, lparent and lparent.frame or D)
	if not lparent then
		mf:SetFrameLevel(D:GetFrameLevel()+10)	--ensure above all non-menu D-descendants
	end
	menu.frame = mf
	menu.lparent = lparent
	menu.bg = mf:CreateTexture()
	menu.bg:SetAllPoints()
	menu.bg:SetColorTexture(1,1,1)
	local max_width = 0
	for l,m in ipairs(menu) do
		m.parent = menu
		m.l = l
		local f = CreateFrame("Frame", nil, mf)
		m.frame = f
		f:SetPoint("TOPLEFT",1,-1-(l-1)*(MENU_HT+2))
		f:SetPoint("BOTTOMRIGHT",mf,"TOPRIGHT",-1,-1-l*(MENU_HT+2))
		m.bg = f:CreateTexture()
		m.bg:SetAllPoints()
		if not m[MCHECK] then
			m.bg:SetColorTexture(.125, .125, .125)
		elseif not m[MCHECKED] then
			m.bg:SetColorTexture(.125, 0, .125)
		end
		local width = 0
		if m[MCHECKED] then
			local box = CreateFrame("Frame",nil,f)
			box:SetPoint("LEFT", width+1, 0)
			box:SetSize(MENU_HT, MENU_HT)
			m.box = box:CreateTexture()
			m.box:SetAllPoints()
			width = width + MENU_HT+1
		end
		if m.icon then
			local f = CreateFrame("Frame",nil,f)
			f:SetPoint("LEFT", width+1, 0)
			f:SetSize(MENU_HT, MENU_HT)
			f = f:CreateTexture()
			f:SetAllPoints()
			f:SetTexture(m.icon)
			width = width + MENU_HT+1
		end
		if m[MTEXT] then
			local f = f:CreateFontString()
			f:SetFont(NARROW_FONT, 13)
			f:SetTextColor(1,1,1)
			f:SetPoint("LEFT", width+1, 0)
			f:SetText(m[MTEXT])
			width = width+1 + f:GetStringWidth()
		end
		if m.menu then
			local f = CreateFrame("Frame",nil,f)
			f:SetPoint("RIGHT",-1,0)
			f:SetSize(MENU_HT, MENU_HT)
			f = f:CreateTexture()
			f:SetAllPoints()
			f:SetTexture("Interface/ChatFrame/ChatFrameExpandArrow")
			width = width + MENU_HT+1
			frameMenu(m.menu,m)
		end
		f:SetScript("OnEnter",function()
			if Menuline then shadeMenupath() end	--just in case
			shadeMenupath(m)
			if m.tip then
				GameTooltip:SetOwner(f,"ANCHOR_RIGHT")
				GameTooltip:SetText(m.tip)
				GameTooltip:Show()
			end
			local mm = m.menu
			if mm then
				mm.frame:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, 1)
				popupMenu(mm,YES)
			elseif WaitSecs then
				closeMenu()
			end
		end)
		f:SetScript("OnLeave",function()
			shadeMenupath()
			GameTooltip:Hide()
			wait(.5,hideMenu)
		end)
		f:SetScript("OnMouseDown",function()
			if m[MCHECKED] then
				checkMenuline(m, not m.checked)
			end
			if m[MCHECK] then m[MCHECK](m) end
		end)
		max_width = max(max_width, width)
	end
	mf:SetSize(max_width+4,#menu*(MENU_HT+2)+2)
	MenuList[#MenuList+1] = menu
end

--[[ Two-colour Buttons

The button-frame is returned by newButton and modified by modButton.
It may be shaded green or red.

Button-fields which may be read by the caller:
frame		frame-id (initialized by "frameButton")
--]]

local function modButton(f,r)
--text=		display text (""=none)
--tip=		set tooltip (""=none)
--icon=		<icon>=icon to display, NO=none
--green=	YES=green NO=red
--arrow=	0=off 1=below 2=above
	if r.text then
		if not f.text then
			f.text = f:CreateFontString(nil,nil,"GameFontNormal")
			f.text:SetPoint("CENTER")
			f.text:SetFont(NARROW_FONT,14)
		end
		f.text:SetText(r.text)
	end
	if r.tip then
		f.tip = r.tip
	end
	if r.icon~=nil then
		if not f.icon then
			f.iconf = CreateFrame("Frame",nil,f)
			f.iconf:SetPoint("LEFT")
			f.iconf:SetSize(20,20)
			f.icon = f.iconf:CreateTexture()
			f.icon:SetAllPoints()
		end
		if r.icon then
			f.icon:SetTexture(r.icon)
			f.icon:Show()
			--if f.text then f.text:Hide() end
		else
			f.icon:Hide()
			--if f.text then f.text:Show() end
		end
	end
	if r.green~=nil then
		local green = r.green and YES or NO
		if green ~= f.green then
			if green then
				f.bg:SetColorTexture(0, .25, 0)
			else
				f.bg:SetColorTexture(.5, 0, 0)
			end
			f.green = green
		end
	end
	if r.arrow then
		if f.arrow ~= r.arrow then
			if not f.arrowf then f.arrowf={} end
			if r.arrow>0 and not f.arrowf[r.arrow] then
				f.arrowf[r.arrow] = f:CreateTexture()
				if r.arrow==1 then
					f.arrowf[r.arrow]:SetPoint("TOPLEFT",f,"BOTTOMLEFT")
				else
					f.arrowf[r.arrow]:SetPoint("BOTTOMLEFT",f,"TOPLEFT")
				end
				f.arrowf[r.arrow]:SetSize(f.width,2)
				f.arrowf[r.arrow]:SetColorTexture(1,0,1)
			end
			for k=1,2 do
				if k==r.arrow then
					f.arrowf[k]:Show()
				else
					if f.arrowf[k] then f.arrowf[k]:Hide() end
				end
			end
			f.arrow = r.arrow
		end
	end
end

local function newButton(width,parent,r)
	local f = CreateFrame("Frame",nil,parent)
	f.width = width
	f:SetSize(width, 18)
	f.bg = f:CreateTexture()
	f.bg:SetAllPoints()
	f.bg:SetColorTexture(.125,.125,.125)
        f:SetScript("OnEnter", function(self)
		if f.green then
			f.bg:SetColorTexture(0,.5,0)
		elseif f.green==NO then
			f.bg:SetColorTexture(.75,0,0)
		else
			f.bg:SetColorTexture(.25,.25,.25)
		end
		if f.tip then
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
			GameTooltip:SetText(f.tip)
			GameTooltip:Show()
		end
	end)
        f:SetScript("OnLeave", function()
		if f.green then
			f.bg:SetColorTexture(0,.25,0)
		elseif f.green==NO then
			f.bg:SetColorTexture(.5,0,0)
		else
			f.bg:SetColorTexture(.125,.125,.125)
		end
		GameTooltip:Hide()
		if MenuShown then
			wait(.5,hideMenu)
		end
	end)
	if r then modButton(f,r) end
	return f
end

--History

local History={}	--50-record history of S
local Hndx,Hfirst,Hlast

local function restoreH(delta)
	if Hndx then	--should always occur
		local hndx = Hndx+delta
		if hndx >= Hfirst and hndx <= Hlast then	--ditto
			Hndx = hndx
			PetScan={};  S = PetScan;  tcopy(History[Hndx],S)
			return YES
		end
	end
	return NO
end

local function saveH()
	if Hndx then
		Hndx = Hndx+1
	else
		Hndx,Hfirst,Hlast = 1,1,1
	end
	History[Hndx]={}; tcopy(S, History[Hndx])
	if Hndx < Hlast then
		for i=Hndx+1,Hlast do
			History[i]=nil
		end
	end
	Hlast = Hndx
	if Hlast-Hfirst > 50 then
		History[Hfirst] = nil
		Hfirst = Hfirst+1
	end
end

--Pet/Ability API

local PJ=C_PetJournal
local RARE=3
local MAX_LEVEL=25
local UnlockLevel={1,2,4,10,15,20}

local BASEH,BASEP,BASES,BREEDS=1,2,3,4	--ex PetScanSpecies
local NoHPS=2
local Breed={
	nil,
	{0,0,0,		"?"},	--NoHPS
	{.5,.5,.5,	"B"},	--3
	{0,2,0,		"PP"},	--4
	{0,0,2,		"SS"},	--5
	{2,0,0,		"HH"},	--6
	{.9,.9,0,	"HP"},	--7
	{0,.9,.9,	"PS"},	--8
	{.9,0,.9,	"HS"},	--9
	{.4,.9,.4,	"PB"},	--10
	{.4,.4,.9,	"SB"},	--11
	{.9,.4,.4,	"HB"}	--12
}
local function AllBreeds() return 3,4,5,6,7,8,9,10,11,12 end
local PHS={4,6,5,7,8,9,10,12,11,3,2}	--breeds ordered by P+H+S,P,H,S
local WILDH=1.2		--factor by which wild pet's health is reduced
local WILDP=1.25	--factor by which wild pet's power is reduced

local TypeToFamily={8,4,6,10,3,7,5,2,1,9}
local FamilyToType={9,8,5,2,7,3,6,1,10,4}

local Family={}		--array of family-names
local FamilyIcon={}	--.. and their icons (14x14, 20x20 OK)
local FamilyIcon2={}
local Source={}		--array of source-names
local SourceExDesc={	--lazy Blizz
	["NPC:"]="Quest",
	["Treasure:"]="Drop",
	["Skinning:"]="Profession",
	["Fishing:"]="Profession",
	["Zone:"]="Discovery",		--whatever...
}
local SourceExSpid={	--even lazier
	[802 ]="Achievement",
	[2621]="Achievement",
	[2721]="Drop",
	[2776]="Promotion",
}

local function getStats(sp,breed,level,quality)
	local lq=(level or MAX_LEVEL)*(1+(quality or RARE)/10)
	local hps = Breed[breed]
	local h = roundp((lq*(sp[BASEH]+hps[1])+20)*5)
	local p = roundp(lq*(sp[BASEP]+hps[2]))
	local s = roundp(lq*(sp[BASES]+hps[3]))
	if not sp.ownable and sp.wild then
		return roundp(h/WILDH), roundp(p/WILDP), s
	else
		return h,p,s
	end
end

local function approx(g,h)
	return abs(g-h) < .51
end

local function getBreed(sp,pet,...)
	local lq = pet.level*(1+pet.quality/10)
	local wild = NO		--irrelevant if pet.owned, and meaningful only for actual stats otherwise

	local breed,breeds
	local breedcnt = 0
	local i = 1
	local b = select(i,...)
 	while b do
		local hps = Breed[b]
		local health = (lq*(sp[BASEH]+hps[1])+20)*5/(wild and WILDH or 1)
		if approx(health, pet.maxhealth) then
			if roundp(health) ~= pet.maxhealth then
				prt(pet.spid,sp.name,health,"rounded UP to H=",pet.maxhealth)
			end
			local power = lq*(sp[BASEP]+hps[2])/(wild and WILDP or 1)
			if approx(power, pet.power) then
				if roundp(power) ~= pet.power then
					prt(pet.spid,sp.name,power,"rounded UP to P=",pet.power)
				end
				local speed = lq*(sp[BASES]+hps[3])
  				if approx(speed, pet.speed) then
					if roundp(speed) ~= pet.speed then
						prt(pet.spid,sp.name,speed,"rounded UP to S=",pet.speed)
					end
					breedcnt = breedcnt + 1
					if breedcnt == 1 then
						breed = b
					else
						if breedcnt == 2 then
							breeds = {breed}
							breed = nil
						end
						breeds[breedcnt] = b
					end
					if pet.level > 2 then break end
				end
			end
		end
		i = i + 1
		b = select(i,...)
	end
	return breed, breeds
end

local function removeJnlConstraints()	--save & remove PJ search-constraints
	local saved={
		search=nil,
		filters={},
		types={},
		sources={},
		event=nil,
	}
	saved.event = E:IsEventRegistered "PET_JOURNAL_LIST_UPDATE"
	if saved.event then
		E:UnregisterEvent "PET_JOURNAL_LIST_UPDATE"
	end
	saved.search = PetJournalSearchBox and PetJournalSearchBox:GetText()
	PJ.ClearSearchFilter()

	for _,v in ipairs{LE_PET_JOURNAL_FILTER_COLLECTED, LE_PET_JOURNAL_FILTER_NOT_COLLECTED} do
		saved.filters[v] = PJ.IsFilterChecked(v)
		PJ.SetFilterChecked(v,YES)
	end

	for k = 1,#Family do
		saved.types[k] = PJ.IsPetTypeChecked(k)
	end
	PJ.SetAllPetTypesChecked(YES)

	for k = 1,#Source do
		saved.sources[k] = PJ.IsPetSourceChecked(k)
	end
	PJ.SetAllPetSourcesChecked(YES)
	return saved
end

local function restoreJnlConstraints(saved)
	if saved.search then
		PJ.SetSearchFilter(saved.search)
	end
	for _,v in ipairs{LE_PET_JOURNAL_FILTER_COLLECTED, LE_PET_JOURNAL_FILTER_NOT_COLLECTED} do
		PJ.SetFilterChecked(v,saved.filters[v])
	end
	for k,v in ipairs(saved.types) do
		PJ.SetPetTypeFilter(k,v)
	end
	for k,v in ipairs(saved.sources) do
		PJ.SetPetSourceChecked(k,v)
	end
	if saved.event then
		E:RegisterEvent "PET_JOURNAL_LIST_UPDATE"
	end
end

local function breedMatrix(sp,full)
	local function colour(i)
		local breed = PHS[i]
		local q = sp.quality and sp.quality[breed]
		return	q and qualityColour(q)
			or has(breed,unpack(sp,BREEDS)) and CUNOWNED
			or CUNBRED
	end
	return string.format(
		full
			and "%sPP %sHH %sSS  %sHP %sPS %sHS  %sPB %sHB %sSB  %sB|r"
			or  "%s||%s||%s|| %s||%s||%s|| %s||%s||%s|| %s|||r",
		colour(1),
		colour(2),
		colour(3),
		colour(4),
		colour(5),
		colour(6),
		colour(7),
		colour(8),
		colour(9),
		colour(10)
	)
end

local function catBreeds(breeds)
	local s = ""
	for _,v in ipairs(breeds) do
		s = s..Breed[v][BREEDS].."?"
	end
	return s
end

local function shownBreed(pet)
	return	pet.breed and Breed[pet.breed][BREEDS]
		or pet.breeds and catBreeds(pet.breeds)
		or ""
end

local function assignedBreed(pet)
	return pet.breeds and pet.breeds[1] or pet.breed
end

--Pet/Ability Database

--PetScanSpecies
--	[1..3]		H,P,S (ex PetScanData)
--	[4...]		breeds (ex PetScanData)
--	name		e.g. "Magical Crawdad"
--	icon
--	family		1..10 (for Aquatic..Undead)
--	ownable		whether can be owned (not trainer-pet or test-pet)
--	wild		whether wild pet
--	battler		whether can pet-battle
--	tradeable	whether cageable
--	source		1=Drop, 2=Quest ...
--	owned		whether any breed is owned
--	own		own[i] = no of "breed-i"s owned
--	quality		quality[i] = highest quality of breed i owned
--	bred		breed assigned to unowned pet shown in PetJournal
--	itemID		used for TUJ api = itemID
--	tt3		TUJ 3-day price
--	tt14		TUJ 14-day price
--	ttglob		TUJ US/EU-wide price
--	abilities	list of abilities
--	abils		ASCII string of abilities for sorting by ability

local Ability={}	--table of Abilities, keyed on ability-id
local Pet		--array of Pets, in same order as Pet-Journal

local function buildFamily()
	for k=1,PJ.GetNumPetTypes() do
		local family = TypeToFamily[k]
		Family[family] = _G["BATTLE_PET_NAME_"..k]
		FamilyIcon[family] = "Interface/Icons/Pet_type_"..PET_TYPE_SUFFIX[k]
		FamilyIcon2[family] = "Interface/PetBattles/PetIcon-"..PET_TYPE_SUFFIX[k]
	end
end

local function buildSource()
	for k=1,PJ.GetNumPetSources() do
		Source[k] = _G["BATTLE_PET_SOURCE_"..k]
	end
	Source[#Source+1] = "Mission"
	Source[#Source+1] = "Order Hall"
	Source[#Source+1] = "PvP"
end

local TUJresult={}	--TUJ global easier on GC
local function addSpecies(spid,sp)
	local name, icon, typ, itemID, src, _, wild, battler, tradeable, _, ownable = PJ.GetPetInfoBySpeciesID(spid)
	if type(name) ~= "string" then return end

	if S.bpb and BPBID_Arrays and BPBID_Arrays.InitializeArrays then
		local function cmpArray(desc,s,base,t,n)
			if not t then
				prt(spid, name..":", "No BPB-ID", desc, dumpArray(s))
				return
			end
			for i=1,n do
			if t[i] ~= s[i+base] then
				prt(spid, name..":", desc, dumpArray(s), "vs BPB-ID", dumpArray(t))
				return
			end end
		end

		local bp_hps, bp_breeds
		if not BPBID_Arrays.BasePetStats then BPBID_Arrays.InitializeArrays() end
		if BPBID_Arrays.BasePetStats then
			bp_hps = BPBID_Arrays.BasePetStats[spid]
			if type(bp_hps) ~= "table" then bp_hps = nil end
		end
		if BPBID_Arrays.BreedsPerSpecies then
			bp_breeds = BPBID_Arrays.BreedsPerSpecies[spid]
			if type(bp_breeds) ~= "table" then bp_breeds = nil end
		end

		if sp[BASEH] then
			if bp_hps then cmpArray("stats", sp, 0, bp_hps, 3) end
		elseif bp_hps then
			sp[BASEH] = bp_hps[BASEH]
			sp[BASEP] = bp_hps[BASEP]
			sp[BASES] = bp_hps[BASES]
			prt(spid, name, "stats supplied by BPB-ID")
		end

		if sp[BREEDS] then
			if bp_breeds then cmpArray("breeds", sp, 3, bp_breeds, max(#sp-3,#bp_breeds)) end
		elseif bp_breeds then
			for k,v in ipairs(bp_breeds) do
				sp[BREEDS+k-1] = v
			end
			prt(spid, name, "breeds supplied by BPB-ID")
		end
	end

	if not sp[BASEH] then
		sp[BASEH],sp[BASEP],sp[BASES]=0,0,0
		if battler then
			prt(spid,name..": No stats")
		end
	end

	sp.name = name
	sp.icon = icon
	sp.family = TypeToFamily[typ]
	sp.itemID = itemID
	sp.wild = sp.w==nil and wild
	sp.battler = battler
	sp.tradeable = tradeable
	sp.ownable = ownable
	if sp.ownable then
		local hps = sp[BASEH]+sp[BASEP]+sp[BASES]
		if abs(hps-24) > .01 then
			prt(spid, sp.name..": Base H+P+S =", hps)
		end
	end

	for k=1,#Source do
		local p = strfind(src, Source[k], 1, YES)
		if p and p <= 11+16 then	--***16? why not 2?
			sp.source = k
			break
		end
	end
	if not sp.source and sp.ownable then
		for k,v in pairs(SourceExDesc) do
		if strfind(src,k,1,YES) == 11 then
			sp.source = posn(Source,v)
			break
		end end
		if not sp.source then
			local v = SourceExSpid[spid]
			if v then
				sp.source = posn(Source,v)
			else
				prt(spid,name,"-",src,": no source")
			end
		end
	end

	sp.abilities = PJ.GetPetAbilityList(spid)
	if sp.abilities then
		for _,a in pairs(sp.abilities) do
			local abil = Ability[a]
			local notabil = not abil
			if notabil then
				Ability[a] = {}
				abil = Ability[a]
			end
			if not PetScanFormula[a] then
				PetScanFormula[a] = ""
			end
		end
	end
	sp.abils = sp.abilities		--for sorting
		and string.format("%.4d%.4d%.4d%.4d%.4d%.4d",
			sp.abilities[1] or 0,
			sp.abilities[4] or 0,
			sp.abilities[2] or 0,
			sp.abilities[5] or 0,
			sp.abilities[3] or 0,
			sp.abilities[6] or 0)
		or ""

	if tradeable and TUJTooltip then
		local itemLink = string.format("%s|Hbattlepet:%d:%d:%d:%d:%d:%d:%s|h[%s]|h|r",
			NORMAL_FONT_COLOR_CODE, spid, 1, 1, 1, 1, 1, itemID, "xyz")
--		local itemLink = string.format("%s|Hbattlepet:%d:%d:%d:%d:%d:%d:%s|h[%s]|h|r",
--			ITEM_QUALITY_COLORS[pet.quality].hex,
--			spid,
--			pet.level,
--			pet.quality+1,
--			health,
--			power,
--			speed,
--			name,
--			pet.id)
		local o = TUJresult
		TUJMarketInfo(itemLink, o)
		if o.recent then
			sp.tt3 = o.recent/10000
		end
		if o.market then
			sp.tt14 = o.market/10000
		end
		if o.globalMedian then
			sp.ttglob = o.globalMedian/10000
		elseif o.globalMean then
			sp.ttglob = o.globalMean/10000
		end
	end
end

local function buildSpecies()
	for spid,sp in pairs(PetScanSpecies) do
		addSpecies(spid,sp)
	end
end

local default={
	family=0,
	powm=0,
	powf="",
	variance=0,
	hit=100,
	ot=0,
	nturns=1,
	cooldown=0,
	formula="",
}

local function buildAbility()
	Ability = {}
	for a,formula in pairs(PetScanFormula) do
		Ability[a] = {}
		local ab = Ability[a]
		if formula~="" then
			ab.formula = formula
		else
			prt("new ability",a,name)
		end

		local function scanFormula(ab,desc,r)		--check against r if non-nil formula
			if ab.formula and not r then
				ab.split = strfind(formula,"/@N",1,YES) and "/N" or ""
				local i = strfind(formula,"[%^%&]")
				if i then
					i=i+1
					local c = strsub(formula,i,i)
					if c == 'P' then
						ab.powm = 1
					else
						local x = strmatch(formula,"^([%d%.]+)%*P",i)
						if x then
							ab.powm = tonumber(x)
						else
							ab.powf = strmatch(formula,"^(.-)%*P",i)
							if ab.powf
								and ab.split==""
								and c=='('
								and strsub(ab.powf,-1,-1)==')'
							then
								ab.powf = strsub(ab.powf,2,-2)
							end
						end
					end
				end
				local s = strmatch(formula,"RM(%d*)")
				if s then
					ab.variance = tonumber(s)
				end
				for v in gmatch(formula, "([%d%.]+)%%Hit") do
					local hit = tonumber(v)
					if hit == default.hit then
						ab.phit = YES
					else
		 				ab.hit = hit
					end
				end
				local b,s = strmatch(formula,"([x+])([%d]*)[ {]")
				if s then
					ab.bomb = b == '+'
					ab.ot = tonumber(s)
				end
			else
				local function getParams(s)
					local _,i = strfind(desc, s, 1, YES)
					if i then
						local s = strmatch(desc,"%b()",i)
						if s then
							s = strsub(s,2,-2)	--remove brackets
							local i,j,k = strsplit(',',s)
							return tonumber(i),tonumber(j),k and tonumber(k)
						end
					end
				end

				local points
				local i,j,k = getParams("StandardDamage", 1, YES)
				if not i then i,j,k = getParams("SimpleDamage", 1, YES) end
				if not i then i,j,k = getParams("StandardHealing", 1, YES) end
				if i then
					points = C_PetBattles.GetAbilityEffectInfo(k or a, i, j, "points")
					if points then
						ab.powm = points/20
					end
					ab.variance = C_PetBattles.GetAbilityEffectInfo(k or a, i, j, "variance")
					if ab.variance then
						ab.variance = ab.variance/2
					end
				end

				local i,j,k = getParams("StandardAccuracy", 1, YES)
				if i then
					local hit = C_PetBattles.GetAbilityEffectInfo(k or a, i, j, "accuracy")
					if hit == default.hit then
						ab.phit = YES
					else
						ab.hit = hit
					end
				end

				local i,j,k = getParams("duration", 1, YES)
				if i then
					ab.ot = C_PetBattles.GetAbilityEffectInfo(k or a, i, j, "duration")
					if ab.ot==default.ot then ab.ot=nil end
				end

				ab.split = ""
				if r then	--comment out all but one of these; report (abilityID,name,Blizz value,formula value)
					local r_powm = r.powf and tonumber(strmatch(r.powf,"[^%d%.]*([%d%.]*)")) or r.powm
					if (points or 0) ~= (r_powm and round(20*r_powm) or 0) then
						prt(a,r.name,ab.powm,r_powm)
					end
					if (ab.variance or 0) ~= (r.variance or 0) then
						--print(a,r.name,ab.variance,r.variance)
					end
					if (ab.hit or default.hit) ~= (r.hit or default.hit) then
						--print(a,r.name,ab.hit,r.hit)
					end
					if (ab.ot or default.ot) ~= (r.ot or default.ot) then
						--print(a,r.name,ab.ot,r.ot)
					end
				end
			end
		end

		local id, name, icon, cooldown, desc, nturns, type, untyped = C_PetBattles.GetAbilityInfoByID(a)
		if not id then
			prt("Ability "..a.." not found")
		else
			ab.name = name
			ab.icon = icon
			ab.cooldown = cooldown ~= default.cooldown and cooldown
			if has(a,330,828,1354,598,247,1408) then	--sons/puppies of the root/flame,emerald dream,hibernate,reforge
				nturns=3
			end
			if not has(nturns,1,2,3) then
				prt(a,name,"nturns=",nturns)
			end
			ab.nturns = nturns ~= default.nturns and nturns
			if has(a,259,836,1015,1049,1087,1466,1545) then	--invis, baneling burst, blinding powder, blinding poison, toxic skin, stone form, preen
				untyped = YES
			elseif has(a,1517) then		--fel corruption
				untyped = NO
			elseif a==1006 then		--Goldskin
				type=7
				untyped=NO
			end
			ab.family = not untyped and TypeToFamily[type]
			if not ab.name then
				prt("ungettable ability",a)
			end
			if NO then	--YES if collating
				local n
				gsub(desc, "%b[]", function(s)
					s = strsub(s,2,-2)
					if not n then
						ab.fn = {}
						n = 0
					end
					n = n+1
					ab.fn[n] = s
					--if not S.fns then S.fns={} end
					--S.fns[s] = (S.fns[s] or 0) + 1
				end)
			end

			scanFormula(ab,desc)
			if NO and desc and ab.formula then	--YES to check formula against Blizz
				local r={}
				scanFormula(r,desc,ab)
			end
		end
	end
end

local function buildPet()
	Pet = {}
	for i = 1, PJ.GetNumPets() do
		local id, spid, owned, name, level, fav = PJ.GetPetInfoByIndex(i)
		Pet[i] = {}
		local pet = Pet[i]

		pet.spid = spid
		local sp=PetScanSpecies[pet.spid]
		if not sp then
			PetScanSpecies[pet.spid] = {}
			sp = PetScanSpecies[pet.spid]
			addSpecies(spid,sp)
--			prt("new species", spid, name)
		end

		pet.owned = owned
		if owned then
			pet.id = id
			pet.level = level
			pet.customName = name
			pet.fav = fav

			pet.health, pet.maxhealth, pet.power, pet.speed, pet.quality = PJ.GetPetStats(id)
			if type(pet.quality) ~= "number" or pet.quality<1 or pet.quality>6 then
				prt("Bizarre rarity ", pet.quality, " for ", pet.spid, sp.name)
				pet.quality = 1
			end
			pet.quality = pet.quality-1	--rarity->quality

			local function tryAll()
				pet.breed, pet.breeds = getBreed(sp, pet, AllBreeds())
				prt(pet.spid, sp.name, pet.maxhealth, pet.power, pet.speed, "has breed", assignedBreed(pet))
			end
			if sp[BREEDS] then
				pet.breed, pet.breeds = getBreed(sp, pet, unpack(sp,BREEDS))
				if not pet.breed and not pet.breeds then tryAll() end
			else
				tryAll()
			end
			if not pet.breed and not pet.breeds then
				pet.breed = NoHPS
			end
			local breed = pet.breed or NoHPS

			if not sp.own then sp.own={} end
			sp.own[breed] = sp.own[breed]
				and sp.own[breed]+1
				or 1

			if not sp.quality then sp.quality={} end
			sp.quality[breed] = sp.quality[breed]
				and max(pet.quality,sp.quality[breed])
				or pet.quality
		else
			pet.breed = sp[BREEDS] or NoHPS
			sp.bred = pet.breed	--exclude from extendPet
		end

		--for sorting
		pet.sp = sp
		pet.name = pet.customName or sp.name
	end
end

local function extendPet()	--add unowned & unownable breeds
	local n = #Pet
	for spid,sp in pairs(PetScanSpecies) do if sp.name then
		local function addPet(b)
			n = n+1
			Pet[n] = {spid=spid, breed=b, sp=sp, name=sp.name}
			if not sp.ownable then
				local pet = Pet[n]
				pet.level = sp.l or MAX_LEVEL
				pet.quality = sp.q or RARE
				pet.maxhealth, pet.power, pet.speed = getStats(sp, b, sp.l, sp.q)
			end
		end
		if not sp[BREEDS] then
			if not sp.bred then addPet(NoHPS) end
		else
			for k,b in ipairs(sp) do
			if k>=BREEDS and b~=sp.bred and not (sp.quality and sp.quality[b]) then
				addPet(b)
			end end
		end
	end end
end

--Select Ability

local SelectedAbilities
local function selectAbilities()
	if	not S.abil and
		not S.abilities and
		not S.dmgTypes and
		not S.variance and
		not S.hit and
		not S.bomb and
		not S.dot and
		not S.ot and
		not S.nturns and
		not S.cooldowns
	then
		SelectedAbilities = nil
		return
	end
	SelectedAbilities = {}
	local abil = S.abil and ".*"..strupper(S.abil)..".*"
	for a,ab in pairs(Ability) do if ab.name and ab.formula then
		local function ticked(menu,abilities)
			for k,v in pairs(abilities) do
				local m = menu[k][2]
				if type(m) == "table" then
					if ticked(m,v) then return YES end
				elseif type(m) == "function" then
					if m(ab.formula) then return YES end
				elseif strfind(ab.formula,m,1,not menu[k].wild) then
					return YES
				end
			end
			return NO
		end
		if
			(not abil or strfind(strupper(ab.name), abil)) and
			(not S.abilities or ticked(PetScanFormulas, S.abilities)) and
			(not S.dmgTypes or S.dmgTypes[ab.family]) and
			(not S.variance or S.variance[ab.variance or default.variance]) and
			(not S.hit or S.hit[ab.hit or default.hit]) and
			(not S.bomb or S.bomb == not ab.bomb) and
			(not S.dot or S.dot == ab.bomb) and
			(not S.ot or S.ot[ab.ot or default.ot]) and
			(not S.nturns or S.nturns[ab.nturns or default.nturns]) and
			(not S.cooldowns or S.cooldowns[ab.cooldown or default.cooldown])
		then
			SelectedAbilities[a] = YES
		end
	end end
end

local SortAb={
	family={"family","powm","powf"},
	ability={},
	powm={"powm","powf"},
	variance={"variance","powm","powf"},
	hit={"hit","powm","powf"},
	ot={"ot","powm","powf"},
	nturns={"nturns","powm","powf"},
	cooldown={"cooldown","powm","powf"},
}

local DescendAb={	--the better, the earlier
	powm=YES,
	hit=YES,
	ot=YES,
}

local AbNdx
local Acnt=0
local function sortAb()
 	sort(AbNdx, function(a,b)
		local function cmp(first,f,...)
			if not f then
				if first and S.abReversed then
					return a > b
				else
					return a < b
				end
			end
			local af = Ability[a][f] or default[f]
			local bf = Ability[b][f] or default[f]
			if type(af)=="table" then af=af[1] end
			if type(bf)=="table" then bf=bf[1] end
			local desc = DescendAb[f]
			if first and S.abReversed then desc = not desc end
			return	(desc and af>bf) or
				(not desc and af<bf) or
				(af==bf and cmp(NO,...))
		end
		return cmp(YES,unpack(SortAb[S.abColumn]))
	end)
end

--Select Pet

local SpeciesMenu = {
	"Ownable",
	"Unownable",
	"Battler",
	"Non-battler",
	"Cageable",
	"Uncageable",
}
local SP={
	OWNABLE=1,
	UNOWNABLE=2,
	BATTLER=3,
	NONBATTLER=4,
	TRAD=5,
	UNTRAD=6
}

local PetMenu = {
	"Owned",
	CUNOWNED.."Unowned|r",
	"Favorite",
	"Non-favorite",
	"Rare",
	"Non-rare",
	"Level 25",
	"Level<25",
	"Duplicate",
	"Distinct",
}
local PET={
	OWNED=1,
	UNOWNED=2,
	FAV=3,
	NONFAV=4,
	RARE=5,
	SUBRARE=6,
	L25=7,
	SUB25=8,
	DUP=9,
	UNDUP=10,
}

local ColumnHdg1={
	{"H",	"Health (click to sort)"},
	{"P",	"Power (click to sort)"},
	{"S",	"Speed (click to sort)"},
}
local ColumnHdg2={
	{"RW",	"Region-wide (US/EU) mean price (click to sort)"},
	{"2w",	"2-week realm-price (click to sort)"},
	{"3d",	"3-day realm-price (click to sort)"},
}
local ReportMenu = {
	{"Actual stats", "This pet's actual health-power-speed", ColumnHdg1},
	{"Max stats", "Health-power-speed at max level, max quality", ColumnHdg1},
	{"Min stats", "Base stats adjusted for breed", ColumnHdg1},
	{"Base stats", "Base stats unadjusted for breed", ColumnHdg1},
	{"AH Pricing", "'The Undermine Journal' addon required", ColumnHdg2},
}
local REPORT_HDG, REPORT_TIP, REPORT_COLUMNS = 1,2,3
local REPORT={
	ACTUAL=1,
	MAX=2,
	ADJBASE=3,
	BASE=4,
	PRICE=5,
}

local PetNdx
local SpeciesNdx
local Xcnt	--#PetNdx or #SpeciesNdx, whichever index is active
local function selectPets()
	local spec = S.spec and ".*"..strupper(S.spec)..".*"

	PetNdx = {}
	local n = 0
	for _,pet in ipairs(Pet) do
		local spid = pet.spid
		local sp = PetScanSpecies[spid]

		local function included()
			local function dup()
				return	pet.owned and
					pet.breed and pet.breed ~= NoHPS and
					sp.own[pet.breed] > 1
			end
			return
				(S.species[SP.OWNABLE] or not sp.ownable) and
				(S.species[SP.UNOWNABLE] or sp.ownable) and
				(S.species[SP.BATTLER] or not sp.battler) and
				(S.species[SP.NONBATTLER] or sp.battler) and
				(S.species[SP.TRAD] or not sp.tradeable) and
				(S.species[SP.UNTRAD] or sp.tradeable) and

				(not S.families or S.families[sp.family]) and
				(not S.sources or S.sources[sp.source]) and
				(not S.spid or spid == S.spid) and
				(not S.spec or
					strfind(strupper(sp.name), spec) or
					(pet.customName and strfind(strupper(pet.customName), spec))) and

				(S.pets[PET.OWNED] or not pet.owned) and
				(S.pets[PET.UNOWNED] or pet.owned) and
				(S.pets[PET.RARE] or not (pet.quality and pet.quality==RARE)) and
				(S.pets[PET.SUBRARE] or (pet.quality and pet.quality==RARE)) and
				(S.pets[PET.L25] or not (pet.level and pet.level==MAX_LEVEL)) and
				(S.pets[PET.SUB25] or pet.level==MAX_LEVEL) and
				(S.pets[PET.FAV] or not pet.fav) and
				(S.pets[PET.NONFAV] or pet.fav) and
				(S.pets[PET.DUP] or not dup()) and
				(S.pets[PET.UNDUP] or dup()) and

--				(not S.level or (pet.level and (sp.ownable
--					and pet.level==S.level
--					or  pet.level>=S.level))) and
				(not S.level or (pet.level and (
					(    sp.ownable and pet.level==S.level) or
					(not sp.ownable and pet.level>=S.level)))) and
				(not S.speed or (pet.speed and pet.speed >S.speed))
		end

		local function abilityIncluded()
			if not (S.ability or SelectedAbilities) then return YES end
			for _,a in pairs(sp.abilities) do
				if S.ability then
					if a==S.ability then return YES end
				else
					if SelectedAbilities and SelectedAbilities[a] then return YES end
				end
			end
			return NO
		end

		if included() and abilityIncluded() then
			n = n + 1
			PetNdx[n] = pet
			local breed = assignedBreed(pet)
			local hps = Breed[breed]

			if S.report==REPORT.ACTUAL then
				if not sp.ownable and S.level then
					pet.h, pet.p, pet.s = getStats(sp,breed,S.level)
				else
					pet.h, pet.p, pet.s = (pet.maxhealth or 0), (pet.power or 0), (pet.speed or 0)
				end
			elseif S.report==REPORT.MAX then
				if sp.ownable and sp.battler then
					pet.h, pet.p, pet.s = getStats(sp,breed)
				else
					pet.h, pet.p, pet.s = (pet.maxhealth or 0), (pet.power or 0), (pet.speed or 0)
				end
			elseif S.report==REPORT.ADJBASE then
				pet.h, pet.p, pet.s = sp[BASEH]+hps[1], sp[BASEP]+hps[2], sp[BASES]+hps[3]
			elseif S.report==REPORT.BASE then
				pet.h, pet.p, pet.s = sp[BASEH], sp[BASEP], sp[BASES]
			elseif S.report==REPORT.PRICE then
				pet.h, pet.p, pet.s = (sp.ttglob or 0), (sp.tt14 or 0), (sp.tt3 or 0)
			end
		end
	end
end

local SortPet={
	spid={"spid","breed"},
	name={"name","spid","breed"},
	family={"family","abils","p","h","s","spid"},
	ability={"abils","p","h","s","spid"},
	health={"h","p","s","spid"},
	power={"p","h","s","spid"},
	speed={"s","p","h","spid"},
}

local DescendPet={	--whether sorted by default in descending order
	spid=YES,
	h=YES,
	p=YES,
	s=YES,
}

local function sortPet()
	local ExSp={
		family=YES,
		abils=YES,
	}
 	sort(PetNdx, function(a,b)
		local function cmp(first,f,...)
			if not f then
				return (a.id or "") < (b.id or "")
			end
			local aa,bb
			if f=="breed" then
				aa = posn(PHS,assignedBreed(a))
				bb = posn(PHS,assignedBreed(b))
			else
				local exsp = ExSp[f]
				aa = (exsp and a.sp or a)[f]
				bb = (exsp and b.sp or b)[f]
			end
			local desc = DescendPet[f]
			if first and S.petReversed then desc = not desc end
			return	(desc and aa>bb) or
				(not desc and aa<bb) or
				(aa==bb and cmp(NO,...))
		end
		return cmp(YES,unpack(SortPet[S.petColumn]))
	end)
end

local function sortSpecies()
	SpeciesNdx={}
	local n=0
	local spun={}
	for i,pet in ipairs(PetNdx) do if not spun[pet.spid] then
		n=n+1
		SpeciesNdx[n] = pet
		spun[pet.spid]=YES
	end end
end

--Report Ability

local function renewAbHdr()
	A.count:SetText(Acnt==0 and "" or Acnt)

	for column,sortlist in pairs(SortAb) do
		local f = A[column]
		local r={arrow=0}
		if f.checkedfn then
			r.green = f.checkedfn()
		end
		if column == S.abColumn then
			r.arrow = (DescendAb[sortlist[1]] or NO) == (S.abReversed or NO) and 1 or 2
		end
		modButton(f,r)
	end
end

local function renewLab(d,abilityID)
	d.abilityID = abilityID
	local ab = Ability[abilityID]
	if ab.family then
		d.family:Show()
		d.family.icon:SetTexture(FamilyIcon[ab.family])
	else
		d.family:Hide()
	end
	d.ability.icon:SetTexture(ab.icon)
	if ab.powm then
		d.powm:SetText(ab.powm..ab.split)
		d.powm:SetTextColor(1,1,1)
	elseif ab.powf then
		d.powm:SetText(ab.powf..ab.split)
		d.powm:SetTextColor(toRGB(LIGHTBLUE))
	else
		d.powm:SetText("")
	end
	d.variance:SetText(ab.variance or "")
	d.hit:SetText(ab.hit and ab.hit.."%"..(ab.phit and "+" or "") or "")
	d.ot:SetText(ab.ot and (ab.bomb and "+" or "")..ab.ot or "")
	d.nturns:SetText(ab.nturns or "")
	d.cooldown:SetText(ab.cooldown or "")
	--d.formula:SetText(ab.formula or "")
end

local function fontLab(d)
	for _,f in ipairs{"powm","variance","hit","ot","nturns","cooldown"} do
		d[f]:SetFont(NARROW_FONT, S.fontHt-1)
	end
end

local function slideA()	--without inducing a change in topAb via OnValueChanged
	A.slider.topLineFrozen = YES
	A.slider:SetValue(S.topAb/max(0,Acnt-LineCnt))
	A.slider.topLineFrozen = NO
end

local formatLab		--forward declaration
local GO={		--action-field of "go"/"goA" parameter
	REPORT=1,
	MERGE=2,
	SORT=3,
	BUILD=4,
}
local function goA(r)
	local action = r.action or GO.BUILD

	if action >= GO.BUILD then
		Acnt=0
 		AbNdx={}
		for k in pairs(SelectedAbilities or Ability) do
			Acnt=Acnt+1
			AbNdx[Acnt] = k
		end
	end

	if action >= GO.SORT then
		if S.abColumn then sortAb() end

		if r.retrace then
			slideA()
		else
			if not r.sametop then
				A.slider:SetValue(0)
			end
		end
		renewAbHdr()
	end

	for l=1,LineCnt do
		local d = A.line[l]
		if d then
			if not d:IsShown() then d:Show() end
		else
			d=formatLab(l)
			fontLab(d)
		end

		if S.topAb+l > Acnt then
			d:Hide()
		else
			renewLab(d,AbNdx[S.topAb+l])
		end
	end
end

--Report Pet

local function renewHdr(preserveInputs)	--refresh variable parts of top 2 lines
	if Hndx == Hfirst then
		D.back:Hide()
	else
		D.back:Show()
	end

	if Hndx == Hlast then
		D.fwd:Hide()
	else
		D.fwd:Show()
	end

	modButton(D.report,{text=ReportMenu[S.report][REPORT_HDG]})

	modButton(D.breeds,S.merged
		and {green=YES, text="Merged", tip="Listing only the first breed per species (click to list all)"}
		or  {green=NO, text="Merge", tip="Listing all possible breeds per species (click to merge)"})

	D.count:SetText(Xcnt==0 and "" or Xcnt)

	if not preserveInputs then
		D.minSpeed:SetText(S.speed or "")
		D.level:SetText(S.level or "")
		D.spec:SetText(S.spec or "")
		D.abil:SetText(S.abil or "")
	end

	local hdg = ReportMenu[S.report][REPORT_COLUMNS]
	for i,v in ipairs{"health","power","speed"} do
		modButton(D[v], {
			text=hdg[i][1],
			tip=hdg[i][2]
		})
	end

	modButton(D.abwin, {green=
		not S.dmgTypes and
		not S.variance and
		not S.hit and
		not S.bomb and
		not S.dot and
		not S.ot and
		not S.nturns and
		not S.cooldowns
	})

	for column,sortlist in pairs(SortPet) do
		local f = D[column]
		local r = {icon=NO,arrow=0}
		if f.checkedfn then
			r.green = f.checkedfn()
		end
		if column=="ability" and S.ability then
			r.icon = Ability[S.ability].icon
		elseif column == S.petColumn then
			r.arrow = (DescendPet[sortlist[1]] or NO) == (S.petReversed or NO) and 2 or 1
		end
		modButton(f,r)
	end
end

local function renewLine(d,pet)
	d.pet = pet
	local sp = pet.sp
	d.breed:SetTextColor(qualityColourRGB(pet.owned and pet.quality))
	d.breed:SetText(shownBreed(pet))

	if S.merged then
		d.name:SetText(sp.name)
		local quality = pet.quality
		if sp.quality then
			for _,q in pairs(sp.quality) do
				if (not quality) or (q > quality) then
					quality = q
				end
			end
		end
		d.name:SetTextColor(qualityColourRGB(quality))
		d.breeds:SetText(breedMatrix(sp))
	else
		local fav = pet.fav and "*" or ""
		local level = pet.level and pet.level<MAX_LEVEL
			and " ("..pet.level..")"
			or ""
		d.name:SetText(pet.name..fav..level)
		d.name:SetTextColor(qualityColourRGB(pet.quality))
		d.breeds:SetText("")
		--d.breedsTip:Hide()
	end

	if sp.icon then
		d.spicon:SetTexture(sp.icon)
	else
		d.spicon:SetColorTexture(0,0,0)
	end
	d.family.icon:SetTexture(FamilyIcon[sp.family])

	if S.report==REPORT.PRICE then
		d.health:SetText(enk(pet.h))
		d.power:SetText(enk(pet.p))
		d.speed:SetText(enk(pet.s))
	else
		d.health:SetText(pet.h == 0 and "" or pet.h)
		d.power:SetText(pet.p == 0 and "" or pet.p)
		d.speed:SetText(pet.s == 0 and "" or pet.s)
	end

	for i = 1,6 do
		local daf = d.abilities[i]
		local a = sp.abilities and sp.abilities[i]
		if a then
			daf.icon:SetTexture(Ability[a].icon)
			daf.icon:SetDesaturated(not S.merged and pet.level and pet.level < UnlockLevel[i])
			local function show(on)
				if on then
					daf.bg:Show()
				else
					daf.bg:Hide()
				end
			end
			if S.ability then
				show(a==S.ability)
			else
				show(SelectedAbilities and SelectedAbilities[a])
			end
			daf:Show()
		else
			daf:Hide()
		end
	end
end

local function fontLine(d)
	d.name:SetFont(NARROW_FONT, S.fontHt)
	d.breeds:SetFont(NARROW_FONT, 22)
	for _,f in ipairs{"breed","health","power","speed"} do
		d[f]:SetFont(NARROW_FONT, S.fontHt-1)
	end
end

local function slideD()	--without inducing a change in topPet via OnValueChanged
	D.slider.topLineFrozen = YES
	D.slider:SetValue(S.topPet/max(0,Xcnt-LineCnt))
	D.slider.topLineFrozen = NO
end

local formatLine	--forward declaration
local function go(r)	--go run report, with r-fields:
--action		action to commence with
--sametop		stay on same page of report
--retrace		whether retracing history
--preserveInputs	whether to protect input-fields from refresh
--ab			whether to call goA

	if r.ab then
		selectAbilities()
		if A then goA(r) end
	end

	local action = r.action or GO.BUILD

	if action >= GO.BUILD then
		if LoadPending>0 then
			LoadPending = -1	--disregard next PET_JOURNAL_LIST_UPDATE triggered by filter-change
			modButton(D.go,{green=YES})
			for _,sp in pairs(PetScanSpecies) do
				sp.own = nil
				sp.quality = nil
			end
			local saved=removeJnlConstraints()
			buildPet()
			--initSource2()
			restoreJnlConstraints(saved)
			extendPet()
		end
		selectPets()
	end

	if action >= GO.SORT then
		if S.petColumn then sortPet() end
		SpeciesNdx = nil
	end

	if action >= GO.MERGE then
		if S.merged and not SpeciesNdx then sortSpecies() end
		Xcnt = S.merged and #SpeciesNdx or #PetNdx

		if r.retrace then
			slideD()
		else
			if not r.sametop then
				D.slider:SetValue(0)
			end
			saveH()
		end
		renewHdr(r.preserveInputs)
	end

	for l=1,LineCnt do
		local d = D.line[l]
		if d then
			if not d:IsShown() then d:Show() end
		else
			d=formatLine(l)
			fontLine(d)
		end

		if S.topPet+l > Xcnt then
			d:Hide()
		else
			renewLine(d,(S.merged and SpeciesNdx or PetNdx)[S.topPet+l])
		end
	end
end

--Format Ability

local LINE_HT = 24
local SCROLL_WIDTH = 16

local Dwidth = 600
local Dheight = 500	--if S.overlayJnl
local LINE_WIDTH = Dwidth-SCROLL_WIDTH

local Awidth=250
local LAB_WIDTH=Awidth-SCROLL_WIDTH

local xa={}
xa.family=0
xa.ability=30
xa.powm=60
xa.variance=90
xa.hit=120
xa.ot=150
xa.nturns=180
xa.cooldown=210
xa.formula=240

local SetAbility	--param to SharedPetBattleAbilityTooltip_SetAbility
local TipAbility={}	--set a,h,p,s to reduce overhead of redefining SetAbility functions
local function tipAbility(f)
	local tt = FloatingPetBattleAbilityTooltip
	if not (S.formula or S.embedded) or IsShiftKeyDown() then
		FloatingPetBattleAbility_Show(TipAbility.a, TipAbility.h, TipAbility.p, TipAbility.s)
	else
		if not SetAbility then
			SetAbility = SharedPetBattleAbilityTooltip_GetInfoTable()
			SetAbility.GetAbilityID = function() return TipAbility.a end
			SetAbility.IsInBattle = function() return NO end
			SetAbility.GetHealth = function() return TipAbility.h end
			SetAbility.GetMaxHealth = function() return TipAbility.h end
			SetAbility.GetAttackStat = function() return TipAbility.p end
			SetAbility.GetSpeedStat = function() return TipAbility.s end

  			tt.AdditionalText:SetFont(NARROW_FONT, select(2, tt.AdditionalText:GetFont()))
			tt.Background:SetColorTexture(0,0,0)	--opaque background please
		end
		local a = TipAbility.a
		local ab = Ability[a]
		local t = a
		if ab then
			if S.formula then
				t = string.format("%s %s%s|r", t, LIGHTBLUE, ab.formula or "")
			end
			if S.embedded then
				local desc = select(5,C_PetBattles.GetAbilityInfoByID(a))
				gsub(desc, "%b[]", function(s)
					s = strsub(s,2,-2)
					t = t..(t and "\n" or "")..s
					local function getParams(i)
						local t = strmatch(s,"%b()",i)
						if t then
							t = strsub(t,2,-2)
							local i,j,k = strsplit(',',t)
							return k and tonumber(k) or a,tonumber(i),tonumber(j)
						end
					end
					local function addSt(st,v,...)
						local _,i = strfind(s,st,1,YES)
						if i then
							local function add(v,...)
								if not v then return end
								local a,i,j = getParams(i)
								if i then
									local r = C_PetBattles.GetAbilityEffectInfo(a,i,j,v)
									if r then
										t = string.format("%s %s%s=%s|r", t, LIGHTBLUE, v, r)
									end
								end
								add(...)
							end
							add(v or st,...)
						end
					end
					if
						addSt("StandardDamage","points","variance") or
						addSt("SimpleDamage","points","variance") or
						addSt("StandardAccuracy","accuracy") or
						addSt("accuracy") or
						addSt("duration")
					then
					end
					--C_PetBattles.GetAbilityEffectInfo(a, i, j, "duration")
				end)
			end
		end
		SharedPetBattleAbilityTooltip_SetAbility(tt, SetAbility, t)
		tt:Show()
	end

	local dy = tt:GetHeight()
	tt:ClearAllPoints()
	if tt:GetTop() < GetScreenHeight()/2 then
		tt:SetPoint("BOTTOMRIGHT",f,"TOPLEFT")
	else
		tt:SetPoint("TOPRIGHT",f,"BOTTOMLEFT")
	end
	tt:SetHeight(dy)
end

local function focusAbility()	--scroll down to S.ability if AbilityWindow open
	local function pos(a,e)
		for k,v in ipairs(a) do
			if v==e then return k end
		end
	end
	if A and AbNdx then
		local i = pos(AbNdx,S.ability)
		if i then
			S.topAb = i-1
			slideA()
			goA{action=GO.REPORT}
		end
	end
end

formatLab = function(l)
	A.line[l] = CreateFrame("Frame", nil, A)
	local d = A.line[l]
	d:SetPoint("TOPLEFT",0,-l*LINE_HT)
	d:SetSize(LAB_WIDTH,LINE_HT)

	d.family = CreateFrame("Frame", nil, d)
	d.family:SetPoint("LEFT", xa.family+2, 0)
	d.family:SetSize(20,20)
	d.family:SetScript("OnMouseDown", function()
		local ab = Ability[d.abilityID]
		if ab.family then
			S.dmgTypes={}
			S.dmgTypes[ab.family]=YES
			go{ab=YES}
		end
	end)
	d.family.icon = d.family:CreateTexture()
	d.family.icon:SetAllPoints()

	d.ability = CreateFrame("Frame", nil, d)
	d.ability:SetPoint("LEFT", xa.ability+2, 0)
	d.ability:SetSize(20,20)
	d.ability:SetScript("OnEnter", function()
		TipAbility.a = d.abilityID
		TipAbility.h, TipAbility.p, TipAbility.s = getStats({8,8,8,ownable=YES}, 3)
		tipAbility(d.ability)
	end)
	d.ability:SetScript("OnLeave", function()
		FloatingPetBattleAbilityTooltip:Hide()
	end)
	d.ability:SetScript("OnMouseDown", function()
		S.ability = d.abilityID
		go{}
	end)
	d.ability.icon = d.ability:CreateTexture()
	d.ability.icon:SetAllPoints()

	d.powm = d:CreateFontString()
	d.powm:SetPoint("LEFT", xa.powm, 0)

	d.variance = d:CreateFontString()
	d.variance:SetPoint("LEFT", xa.variance+2, 0)

	d.hit = d:CreateFontString()
	d.hit:SetPoint("LEFT", xa.hit, 0)

	d.ot = d:CreateFontString()
	d.ot:SetPoint("LEFT", xa.ot+6, 0)

	d.nturns = d:CreateFontString()
	d.nturns:SetPoint("LEFT", xa.nturns+6, 0)

	d.cooldown = d:CreateFontString()
	d.cooldown:SetPoint("LEFT", xa.cooldown+6, 0)

	--d.formula = d:CreateFontString()
	--d.formula:SetPoint("LEFT", xa.formula+2, 0)

	return d
end

local function formatA()
	A = CreateFrame("Frame", "PetScanAbilityFrame", D)
	A:SetPoint("TOPLEFT", D, "TOPRIGHT")
	A:SetSize(Awidth, S.overlayJnl and Dheight or S.height)

	A.bg = A:CreateTexture(nil,"BACKGROUND")
	A.bg:SetAllPoints()
	A.bg:SetColorTexture(0,0,0)

	A.top = CreateFrame("Frame", nil, A)
	A.top:SetPoint("TOPLEFT", 0, LINE_HT)
	A.top:SetPoint("BOTTOMRIGHT", A, "TOPRIGHT")

	A.title = A.top:CreateFontString(nil, nil, "GameFontNormal")
	A.title:SetPoint("LEFT", 40, 0)
	A.title:SetText(LIGHTBLUE.."Abilities|r")

	A.count = A.top:CreateFontString(nil, nil, "GameFontNormal")
	A.count:SetPoint("RIGHT", A.title, "LEFT", -2, 0)
	A.count:SetFont(NARROW_FONT, S.fontHt)
	A.count:SetTextColor(1,1,1)

	A.top.bg = A.top:CreateTexture(nil,"BACKGROUND")
	A.top.bg:SetAllPoints()
	A.top.bg:SetColorTexture(0,0,0)

	A.cls = CreateFrame("Button", nil, A.top, "UIPanelCloseButton")
	A.cls:SetPoint("RIGHT", 2, 0)
	A.cls:SetSize(20,20)
	A.cls:SetScript("OnClick", function()
		A:Hide()
		D.resize:SetWidth(Dwidth)
	end)

	A.slider = CreateFrame("Slider", nil, A)
	A.slider:SetOrientation("VERTICAL");
	A.slider:SetPoint("TOPLEFT", A, "TOPRIGHT", -SCROLL_WIDTH, 0)
	A.slider:SetPoint("BOTTOMRIGHT")
	A.slider:SetMinMaxValues(0,1)
	A.slider:SetScript("OnValueChanged", function(self,f)
		if A.slider.topLineFrozen then return end
		local maxtop = Acnt-LineCnt
		if maxtop <= 0 then
			S.topAb = 0
		else
			local n = round(f*maxtop)
			if S.topAb ~= n then
				S.topAb = n
				if Hndx then History[Hndx].topAb = n end
				goA{action=GO.REPORT}
			end
		end
	end)

	A.slider.bg = A.slider:CreateTexture(nil,"BACKGROUND")
	A.slider.bg:SetAllPoints()
	A.slider.bg:SetColorTexture(.5,.5,.5)

	A.slider.thumb = A.slider:CreateTexture()
	A.slider.thumb:SetTexture("Interface/Buttons/UI-ScrollBar-Knob")
	A.slider.thumb:SetSize(25,25)
	A.slider:SetThumbTexture(A.slider.thumb)

	A:EnableMouseWheel(YES)
	A:SetScript("OnMouseWheel", function(self,delta)
		if delta~=0 then
			local maxtop = Acnt-LineCnt
			if maxtop > 0 then
				A.slider:SetValue((S.topAb+(delta < 0 and 1 or -1)*LineCnt)/maxtop)
			end
		end
	end)

	A.hdr = CreateFrame("Frame", nil, A)
	A.hdr:SetPoint("TOPLEFT")
	A.hdr:SetPoint("BOTTOMRIGHT", A, "TOPRIGHT", -SCROLL_WIDTH, -LINE_HT)

	A.hdr.bg = A.hdr:CreateTexture(nil,"BACKGROUND")
	A.hdr.bg:SetAllPoints()
	A.hdr.bg:SetColorTexture(0,0,0x40/0xff)

	local function initColumn(column, width, heading, tip, menu, checkfn, checkedfn)
		tip = tip..(menu
			and " (click to sort, right-click to de/select)"
			or  " (click to sort)")
 		local f = newButton(width, A.hdr, {text=heading, tip=tip})
		f.checkedfn = checkedfn
		f:SetScript("OnMouseDown", function(self,button)
			if button ~= "RightButton" then
				if S.abColumn==column then
					S.abReversed = not S.abReversed
				else
					S.abReversed = nil
				end
				S.abColumn=column
				goA{action=GO.SORT}
			elseif menu then
				if menu.frame:IsShown() then
					if checkfn then checkfn(not f.green) end
				else
					popupMenu(menu,YES)
				end
			end
		end)
		A[column] = f
		f:SetPoint("LEFT",xa[column],0)
		if menu then
			frameMenu(menu)
			local lr = column=="family" and "LEFT" or "RIGHT"
			menu.frame:SetPoint("TOP"..lr, f, "BOTTOM"..lr)
			menu.frame:Hide()
		end
	end

	A.dmgTypeMenu = {}
	for k=1,#Family do A.dmgTypeMenu[k] = {
		Family[k],
		function(m)
			if m.checked then
				if not S.dmgTypes then S.dmgTypes={} end
				S.dmgTypes[k] = YES
				if tableCount(S.dmgTypes) == #Family then
					S.dmgTypes=nil
				end
			else
				if not S.dmgTypes then
					S.dmgTypes={}
					for k=1,#Family do
						S.dmgTypes[k] = YES
					end
				end
				S.dmgTypes[k] = nil
			end
			go{ab=YES}
		end,
		function()
			return not S.dmgTypes or S.dmgTypes[k]
		end,
		icon = FamilyIcon[k],
	} end
	initColumn("family", 24, "T", "Damage-type", A.dmgTypeMenu,
		function(checked)
			if checked then
				S.dmgTypes = nil
			else
				S.dmgTypes = {}
			end
			refreshMenu(A.dmgTypeMenu)
			go{ab=YES}
		end,
		function()
			return not S.dmgTypes
		end
	)

	initColumn("ability", 24, "A", "Ability tooltip for a pet with base stats 8,8,8 and breed B")
	initColumn("powm", 24, "M", "Power-multiplier (Power = stated power + 20)")

	A.varianceMenu = {}
	do
		local variance = {0,10,15,20,30}
		for k,v in ipairs(variance) do A.varianceMenu[k] = {
			v==0 and "nil" or "+/- "..v.."%",
			function(m)
				if m.checked then
					if not S.variance then S.variance={} end
					S.variance[v] = YES
					if tableCount(S.variance) == #variance then
						S.variance=nil
					end
				else
					if not S.variance then
						S.variance={}
						for _,v in ipairs(variance) do
							S.variance[v] = YES
						end
					end
					S.variance[v] = nil
				end
				go{ab=YES}
			end,
			function()
				return not S.variance or S.variance[v]
			end,
		} end
	end
	initColumn("variance", 24, "V", "+/- % Variation", A.varianceMenu,
		function(checked)
			if checked then
				S.variance = nil
			else
				S.variance = {}
			end
			refreshMenu(A.varianceMenu)
			go{ab=YES}
		end,
		function()
			return not S.variance
		end
	)

	A.hitMenu = {}
	do
		local hit = {25,50,80,85,100,200}
		for k,v in ipairs(hit) do A.hitMenu[k] = {
			v.."%",
			function(m)
				if m.checked then
					if not S.hit then S.hit={} end
					S.hit[v] = YES
					if tableCount(S.hit) == #hit then
						S.hit=nil
					end
				else
					if not S.hit then
						S.hit={}
						for _,v in ipairs(hit) do
							S.hit[v] = YES
						end
					end
					S.hit[v] = nil
				end
				go{ab=YES}
			end,
			function()
				return not S.hit or S.hit[v]
			end,
		} end
	end
	initColumn("hit", 24, "H", "Hit-chance", A.hitMenu,
		function(checked)
			if checked then
				S.hit = nil
			else
				S.hit = {}
			end
			refreshMenu(A.hitMenu)
			go{ab=YES}
		end,
		function()
			return not S.hit
		end
	)

	A.otMenu = {
	{
		"Bomb", tip="Deferred event",
		function(m)
			S.bomb = not m.checked
			go{ab=YES}
		end,
		function()
			return not S.bomb
		end
	},
	{
		"DoT/HoT", tip="Recurring event",
		function(m)
			S.dot = not m.checked
			go{ab=YES}
		end,
		function()
			return not S.dot
		end
	}}
	do
		local ot={1,2,3,4,5,6,7,8,9,10,15,20}
		for k,v in ipairs(ot) do A.otMenu[k+2] = {
			v.."-round",
			function(m)
				if m.checked then
					if not S.ot then S.ot={} end
					S.ot[v] = YES
					if tableCount(S.ot) == #ot then
						S.ot=nil
					end
				else
					if not S.ot then
						S.ot={}
						for _,v in ipairs(ot) do
							S.ot[v] = YES
						end
					end
					S.ot[v] = nil
				end
				go{ab=YES}
			end,
			function()
				return not S.ot or S.ot[v]
			end,
		} end
	end
	initColumn("ot", 24, "D", "DoT/HoT/Bomb timer", A.otMenu,
		function(checked)
			if checked then
				S.bomb = nil
				S.dot = nil
				S.ot = nil
			else
				S.bomb = YES
				S.dot = YES
				S.ot = {}
			end
			refreshMenu(A.otMenu)
			go{ab=YES}
		end,
		function()
			return not (S.bomb or S.dot or S.ot)
		end
	)

	A.nturnsMenu = {}
	do
		local nturns = {1,2,3}
		for k,v in ipairs(nturns) do A.nturnsMenu[k] = {
			v.." turn"..(v==1 and "" or "s"),
			function(m)
				if m.checked then
					if not S.nturns then S.nturns={} end
					S.nturns[v] = YES
					if tableCount(S.nturns) == #nturns then
						S.nturns=nil
					end
				else
					if not S.nturns then
						S.nturns={}
						for _,v in ipairs(nturns) do
							S.nturns[v] = YES
						end
					end
					S.nturns[v] = nil
				end
				go{ab=YES}
			end,
			function()
				return not S.nturns or S.nturns[v]
			end,
		} end
	end
	initColumn("nturns", 24, "N", "Number of turns", A.nturnsMenu,
		function(checked)
			if checked then
				S.nturns = nil
			else
				S.nturns = {}
			end
			refreshMenu(A.nturnsMenu)
			go{ab=YES}
		end,
		function()
			return not S.nturns
		end
	)

	A.cooldownMenu = {}
	do
		local cooldown = {0,1,2,3,4,5,6,8,10,20}
		for k,v in ipairs(cooldown) do A.cooldownMenu[k] = {
			v==0 and "nil" or v.." turn"..(v==1 and "" or "s"),
			function(m)
				if m.checked then
					if not S.cooldowns then S.cooldowns={} end
					S.cooldowns[v] = YES
					if tableCount(S.cooldowns) == #cooldown then
						S.cooldowns=nil
					end
				else
					if not S.cooldowns then
						S.cooldowns={}
						for _,v in ipairs(cooldown) do
							S.cooldowns[v] = YES
						end
					end
					S.cooldowns[v] = nil
				end
				go{ab=YES}
			end,
			function()
				return not S.cooldowns or S.cooldowns[v]
			end,
		} end
	end
	initColumn("cooldown", 24, "C", "Cooldown", A.cooldownMenu,
		function(checked)
			if checked then
				S.cooldowns = nil
			else
				S.cooldowns = {}
			end
			refreshMenu(A.cooldownMenu)
			go{ab=YES}
		end,
		function()
			return not S.cooldowns
		end
	)

	A.line={}
end

--Format Pet

local dx={
	breed=22,
	spid=24,
	name=175,
	breeds=75,
	family=30,
	ability=160,
	health=35,
	power=35,
}

local xx={}
xx.breed = 20
xx.spid = dx.breed
xx.name = xx.spid + dx.spid
xx.breeds = xx.name + dx.name
xx.family = xx.breeds + dx.breeds
xx.ability = xx.family + dx.family
xx.health = xx.ability + dx.ability
xx.power = xx.health + dx.health
xx.speed = xx.power + dx.power

local function hideD()
	S.visible = NO
	D:Hide()
end

local function setAlpha()
	D.bg:SetAlpha(S.alpha)
	D.topleft.bg:SetAlpha(S.alpha)
	D.topright.bg:SetAlpha(S.alpha)
	D.hdr.bg:SetAlpha(S.alpha)
	D.slider.bg:SetAlpha(S.alpha)
	D.resize.bg:SetAlpha(S.alpha)
	if A then
		A.bg:SetAlpha(S.alpha)
		A.top.bg:SetAlpha(S.alpha)
		A.hdr.bg:SetAlpha(S.alpha)
		A.slider.bg:SetAlpha(S.alpha)
	end
	if INCLUDE_MENUS then
		local function me(menu)
			menu.bg:SetAlpha(S.alpha)
			for _,m in ipairs(menu) do
				m.bg:SetAlpha(S.alpha)
				if m.menu then me(m.menu) end
			end
		end
		for _,menu in ipairs(MenuList) do me(menu) end
	end
end

local function tipPet(d)
	local f = d.spid
	local pet = d.pet
	local sp = pet.sp

	local level,quality,h,p,s
	if pet.owned or not sp.ownable then
		level = pet.level
		quality = pet.quality
		h = pet.maxhealth
		p = pet.power
		s = pet.speed
	else
		level = MAX_LEVEL
		quality = RARE
		h,p,s = getStats(sp, pet.breed)
	end

	GameTooltip:SetOwner(f,"ANCHOR_RIGHT")
	BattlePetToolTip_Show(pet.spid, level, quality, h, p, s, sp.name)

	local tt = BattlePetTooltip
	tt.battlePetID = pet.id

	tt.Name:SetText(	--overwrite BPBID
		qualityColour(pet.owned and pet.quality).."("..shownBreed(pet)..") "..
		qualityColour(pet.quality)..sp.name.."|r")
	tt.Name:SetFont(NARROW_FONT, select(2, tt.Name:GetFont()))	--allow room for breed

	local collected = C_PetJournal.GetOwnedBattlePetString(pet.spid)
	tt.Owned:SetText(
		not sp.ownable and "Unownable" or
		not collected and "Unowned" or
		not pet.owned and "Unowned breed - "..collected or
		collected)

	if PetTracker_Sets and sp.ownable then return end	--else tooltip-clash

	local y = 136
	tt.Background:SetColorTexture(0,0,0)	--breeds hard to read unless background opaque
	tt.breeds = tt:CreateFontString()
	tt.breeds:SetFont(NARROW_FONT,14)
	tt.breeds:SetPoint("TOPLEFT",11,10-y)
	tt.breeds:SetText(breedMatrix(sp,YES))
	y = y + 16

	local _,_,_,_, src = PJ.GetPetInfoBySpeciesID(pet.spid)
	if src and #src>2 then
		tt.src = tt:CreateFontString()
		tt.src:SetFont(NARROW_FONT,12)
		tt.src:SetJustifyH("LEFT")
		tt.src:SetPoint("TOPLEFT",11,10-y)
		tt.src:SetText(src)
		local _,count = string.gsub(src,"|n","")
		if strsub(src,-2,-1) ~= "|n" then
			count = count+1
		end
		y = y + 12*(count or 0)
	end

	tt.id = tt:CreateFontString()
	tt.id:SetFont(NARROW_FONT,14)
	tt.id:SetPoint("TOPLEFT",11,8-y)
	tt.id:SetText(format("#%s %s", pet.spid, pet.id or ""))
	y = y + 16

	tt:SetSize(260,y)
end

formatLine = function(l)
	D.line[l] = CreateFrame("Frame", nil, D)
	local d = D.line[l]
	d:SetPoint("TOPLEFT",0,-l*LINE_HT)
	d:SetSize(LINE_WIDTH,LINE_HT)

	d.breed = d:CreateFontString()
	d.breed:SetPoint("RIGHT", xx.breed-LINE_WIDTH, 0)

	d.spid = CreateFrame("Frame", nil, d)
	d.spid:SetPoint("LEFT", xx.spid, 0)
	d.spid:SetSize(20,20)
	d.spid:SetScript("OnEnter", function()
		tipPet(d)
	end)
	d.spid:SetScript("OnLeave", function()
		local tt = BattlePetTooltip
		if tt then
			if tt.breeds then tt.breeds:Hide() end
			if tt.src then tt.src:Hide() end
			if tt.id then tt.id:Hide() end
			tt:Hide()
		end
	end)
	d.spid:SetScript("OnMouseDown", function(self,button)
		local pet = d.pet
		if button=="RightButton" then
			D.clickedPet = pet
			if BattlePetTooltip and BattlePetTooltip:IsShown() then
				BattlePetTooltip:Hide()
				GameTooltip:Hide()
				D.spidMenu.frame:SetPoint("TOPLEFT", d.spid, "TOPRIGHT")
				popupMenu(D.spidMenu,YES)
			else
				D.spidMenu[1][2]()	--double-rightclick handy here
				closeMenu()
				BattlePetTooltip:Show()
			end
		elseif S.spid ~= pet.spid then
			S.spid = pet.spid
			if S.merged then S.merged=No end
			go{}
		end
	end)
	d.spicon = d.spid:CreateTexture() --nil,"BACKGROUND")
	d.spicon:SetAllPoints()

	d.name = d:CreateFontString()
	d.name:SetPoint("LEFT", xx.name, 0)

	d.breeds = d:CreateFontString()
	d.breeds:SetPoint("LEFT",xx.breeds,1)

	d.breedsTip = CreateFrame("Frame", nil, d)
	d.breedsTip:SetPoint("LEFT",xx.breeds,1)
	d.breedsTip:SetSize(70,S.fontHt)
        d.breedsTip:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
		GameTooltip:SetText(breedMatrix(d.pet.sp, YES))
		GameTooltip:Show()
	end)
        d.breedsTip:SetScript("OnLeave", function() GameTooltip:Hide() end)

	d.family = CreateFrame("Frame", nil, d)
	d.family:SetPoint("LEFT", xx.family, 0)
	d.family:SetSize(20,20)
	d.family:SetScript("OnMouseDown", function()
		S.families={}
		S.families[d.pet.sp.family]=YES
		go{}
	end)
	d.family.icon = d.family:CreateTexture()
	d.family.icon:SetAllPoints()

	d.health = d:CreateFontString()
	d.health:SetPoint("LEFT", xx.health, 0)
	d.health:SetTextColor(1,1,1)	--white

	d.power = d:CreateFontString()
	d.power:SetPoint("LEFT", xx.power, 0)
	d.power:SetTextColor(1,1,0)	--yellow

	d.speed = d:CreateFontString()
	d.speed:SetPoint("LEFT", xx.speed, 0)
	d.speed:SetTextColor(1,1,1)	--white

	d.abilities = {}
	for i=1,6 do
		d.abilities[i] = CreateFrame("Frame", nil, d)
		local daf = d.abilities[i]
		local k = floor((i-0.5)/3)
		local j = i - (k==0 and 1 or 4)
		daf:SetPoint("LEFT", xx.ability+j*56+k*22, 0)
		daf:SetSize(20,20)
		daf:SetScript("OnEnter", function()
			local pet = d.pet
			local sp = pet.sp
			TipAbility.a = sp.abilities and sp.abilities[i]
			if pet.owned or not sp.ownable then
				TipAbility.h = pet.maxhealth or 0
				TipAbility.p = pet.power or 0
				TipAbility.s = pet.speed or 0
			else
				TipAbility.h, TipAbility.p, TipAbility.s = getStats(sp, pet.breed)
			end
			tipAbility(d.abilities[i])
		end)
		daf:SetScript("OnLeave", function()
			FloatingPetBattleAbilityTooltip:Hide()
		end)
		daf:SetScript("OnMouseDown", function()
			S.ability = d.pet.sp.abilities[i]
			focusAbility()
			go{}
		end)
		daf.bg = daf:CreateTexture(nil,"BACKGROUND")
		daf.bg:SetPoint("TOPLEFT",-1,1)
		daf.bg:SetPoint("BOTTOMRIGHT",1,-1)
		daf.bg:SetColorTexture(1,1,1)
		daf.icon = daf:CreateTexture()
		daf.icon:SetAllPoints()
	end
	return d
end

local function formatD()
	D = CreateFrame("Frame", "PetScanFrame", UIParent)

	D.topright = CreateFrame("Frame", nil, D)
	D.topright:SetPoint("TOPLEFT", 230, LINE_HT)
	D.topright:SetPoint("BOTTOMRIGHT", D, "TOPRIGHT")

	D.topleft = CreateFrame("Frame", nil, D)
	D.topleft:SetPoint("TOPLEFT", 0, LINE_HT)
	D.topleft:SetPoint("BOTTOMRIGHT", D.topright, "BOTTOMLEFT")

	D.bg = D:CreateTexture(nil,"BACKGROUND")
	D.bg:SetAllPoints()
	D.bg:SetColorTexture(0,0,0)

	D.topleft.bg = D.topleft:CreateTexture(nil,"BACKGROUND")
	D.topleft.bg:SetAllPoints()
	D.topleft.bg:SetColorTexture(0,0,0)

	D.topright.bg = D.topright:CreateTexture(nil,"BACKGROUND")
	D.topright.bg:SetAllPoints()
	D.topright.bg:SetColorTexture(0,0,0)

	D.title = D.topleft:CreateFontString(nil, nil, "GameFontNormal")
	D.title:SetPoint("LEFT", 16, 0)
	D.title:SetText(LIGHTBLUE.."PetScan v"..Version.."|r")

	D.settings = newButton(40,D.topright,{text="Clear",tip="Click to clear filters, or right-click to change settings"})
	D.settings:SetPoint("RIGHT", -284, 0)
	do
		local fontMenu = {}
		for k,v in ipairs{12,13,14,15,16} do fontMenu[k] = {
			v.."pt font",
			function(m)
				S.fontHt = v
				refreshMenu(m.parent)
				D.count:SetFont(NARROW_FONT,v)
				for _,d in pairs(D.line) do fontLine(d) end
				if A then
					A.count:SetFont(NARROW_FONT,v)
					for _,d in pairs(A.line) do fontLab(d) end
				end
				go{action=GO.REPORT}
			end,
			function()
				return S.fontHt==v
			end,
		} end

		local opacityMenu = {}
		for k,v in ipairs{1, .9, .75, .5, 0} do opacityMenu[k] = {
			v==0 and "transparent" or round(v*100).."% opaque",
			function(m)
				S.alpha=v
				refreshMenu(m.parent)
				setAlpha()
			end,
			function()
				return S.alpha==v
			end,
		} end

		local menu = {
		{
			"Font-size",
			menu = fontMenu,
		},
		{
			"Opacity",
			menu = opacityMenu,
		},
		{
			"Order by species#",
			function()
				S.sspid = not S.sspid
			end,
			function()
				return S.sspid
			end,
			tip = "[Clear] lists unowned unownable by species#, instead of owned pets in journal order"
		},
		{
			"Tip ability-formula",
			function()
				S.formula = not S.formula
			end,
			function()
				return S.formula
			end,
			tip = "Display formula in ability-tooltip",
		},
		{
			"Tip ability-functions",
			function()
				S.embedded = not S.embedded
			end,
			function()
				return S.embedded
			end,
			tip = "Display embedded functions in ability-tooltip",
		},
		{
			"Check with BPB-ID",
			function()
				S.bpb = not S.bpb
			end,
			function()
				return S.bpb
			end,
			tip = "Use new data from addon 'Battle Pet BreedID'",
		},
		{
			"Flag anomalies",
			function()
				S.plus = not S.plus
			end,
			function()
				return S.plus
			end,
			tip = "Display status-messages (mainly for debugging)",
		}}
		frameMenu(menu)
		D.settings:SetScript("OnMouseDown", function(self,button)
			if button=="RightButton" then
				popupMenu(menu)
			else
				S.merged = S.sspid
				for k in ipairs(SpeciesMenu) do
					S.species[k] = not S.sspid or k~=SP.UNOWNABLE
				end
				S.spid = nil
				S.spec = nil
				S.abil = nil
				S.families = nil
				for k in ipairs(PetMenu) do
					S.pets[k] = S.sspid or k~=PET.UNOWNED
				end
				S.level = nil
				S.speed = nil
				S.sources = nil
				S.abilities = nil
				S.ability = nil
				S.dmgTypes = nil
				S.hit = nil
				S.bomb = nil
				S.dot = nil
				S.ot = nil
				S.nturns = nil
				S.cooldowns = nil
				S.petColumn = S.sspid and "spid"
				S.petReversed = nil
				S.topPet = 0
				S.abColumn = nil
				S.abReversed = nil
				S.topAb = 0
				go{ab=YES}
			end
		end)
	end

	D.go = newButton(20,D.topright,{text="Go",tip="Rerun report on fresh data from Pet Journal"})
	D.go:SetPoint("LEFT", D.settings, "RIGHT", 3, 0)
	D.go:SetScript("OnMouseDown", function(self,button)
		LoadPending=1
		go{sametop=YES}
	end)

	D.back = newButton(20, D.topright, {
		icon="Interface/Icons/misc_arrowleft",
		tip="Go back to previous report"})
	D.back:SetPoint("LEFT",D.go,"RIGHT",3,0)
	D.back:SetScript("OnMouseDown", function()
		if restoreH(-1) then go{retrace=YES, ab=YES} end
	end)

	D.fwd = newButton(20, D.topright, {
		icon="Interface/Icons/misc_arrowright",
		tip="Go forward to next report"})
	D.fwd:SetPoint("LEFT",D.back,"RIGHT",3,0)
	D.fwd:SetScript("OnMouseDown", function()
		if restoreH(1) then go{retrace=YES, ab=YES} end
	end)

	D.report = newButton(95, D.topright, {tip="Click to select report"})
	D.report:SetPoint("RIGHT", -20, 0)
	D.reportMenu = {}
	for k,v in ipairs(ReportMenu) do D.reportMenu[k] = {
		v[REPORT_HDG],
		function()
			S.report = k
			go{sametop=YES}
		end,
		tip=v[REPORT_TIP],
	} end
	frameMenu(D.reportMenu)
	D.reportMenu.frame:SetPoint("TOP", D.report, "BOTTOM")
	D.reportMenu.frame:Hide()
	D.report:SetScript("OnMouseDown", function(self,button)
		popupMenu(D.reportMenu, YES)
	end)

 	D.minSpeed = CreateFrame("EditBox", "PetScan_Speed", D.topright, "InputBoxTemplate")
	D.minSpeed:SetSize(30,20)
	D.minSpeed:SetPoint("RIGHT",D.report,"LEFT",-12,0)
	D.minSpeed:SetBlinkSpeed(1)
	D.minSpeed:SetMaxLetters(3)
	D.minSpeed:SetFontObject("GameFontNormalSmall")
	D.minSpeed:SetTextColor(1,1,1)
	D.minSpeed:SetAutoFocus(NO)
	D.minSpeed:SetScript("OnKeyUp", function(self)
		local speed = self:GetText()
		S.speed = speed and tonumber(speed)
		go{preserveInputs=YES}
	end)
	D.minSpeed:SetScript("OnEscapePressed", function() hideD() end)
	tip(D.minSpeed, "List pets faster than this speed")
	D.minSpeed.txt = D.minSpeed:CreateFontString(nil, nil, "GameFontNormal")
	D.minSpeed.txt:SetPoint("RIGHT", D.minSpeed, "LEFT", -5, 0)
	D.minSpeed.txt:SetText("S")

 	D.level = CreateFrame("EditBox", "PetScan_Level", D.topright, "InputBoxTemplate")
	D.level:SetSize(20,22)
	D.level:SetPoint("RIGHT",D.minSpeed.txt,"LEFT",-6,0)
	D.level:SetBlinkSpeed(1)
	D.level:SetMaxLetters(2)
	D.level:SetFontObject("GameFontNormalSmall")
	D.level:SetTextColor(1,1,1)
	D.level:SetAutoFocus(NO)
	D.level:SetScript("OnKeyUp", function(self)
		local level = self:GetText()
		S.level = level and tonumber(level)
		go{preserveInputs=YES}
	end)
	D.level:SetScript("OnEscapePressed", function() hideD() end)
	tip(D.level, "List pets of this level, or of any level if blank")
	D.level.txt = D.level:CreateFontString(nil, nil, "GameFontNormal")
	D.level.txt:SetPoint("RIGHT", D.level, "LEFT", -5, 0)
	D.level.txt:SetText("L")

	D.cls = CreateFrame("Button", nil, D.topright, "UIPanelCloseButton")
	D.cls:SetPoint("RIGHT", 2, 0)
	D.cls:SetSize(20,20)
	D.cls:SetScript("OnClick", function() hideD() end)

	D.slider = CreateFrame("Slider", nil, D)
	D.slider:SetOrientation("VERTICAL");
	D.slider:SetPoint("TOPLEFT", D, "TOPRIGHT", -SCROLL_WIDTH, 0)
	D.slider:SetPoint("BOTTOMRIGHT")
	D.slider:SetMinMaxValues(0,1)
	D.slider:SetScript("OnValueChanged", function(self,f)
		if D.slider.topLineFrozen then return end
		local maxtop = Xcnt-LineCnt
		if maxtop <= 0 then
			S.topPet = 0
		else
			local n = round(f*maxtop)
			if S.topPet ~= n then
				S.topPet = n
				if Hndx then History[Hndx].topPet = n end
				go{action=GO.REPORT}
			end
		end
	end)

	D.slider.bg = D.slider:CreateTexture(nil,"BACKGROUND")
	D.slider.bg:SetAllPoints()
	D.slider.bg:SetColorTexture(.5,.5,.5)

	D.slider.thumb = D.slider:CreateTexture()
	D.slider.thumb:SetTexture("Interface/Buttons/UI-ScrollBar-Knob")
	D.slider.thumb:SetSize(25,25)
	D.slider:SetThumbTexture(D.slider.thumb)

	D:EnableMouseWheel(YES)
	D:SetScript("OnMouseWheel", function(self,delta)
		if delta~=0 then
			local maxtop = Xcnt-LineCnt
			if maxtop > 0 then
				D.slider:SetValue((S.topPet+(delta < 0 and 1 or -1)*LineCnt)/maxtop)
			end
		end
	end)

	D.resize = CreateFrame("Frame", nil, D)
	D.resize:SetPoint("TOPLEFT", D, "BOTTOMLEFT")
	D.resize:SetSize(Dwidth,2)
	D.resize:SetScript("OnEnter", function()
		SetCursor("INTERACT_CURSOR")
	end)
	D.resize:SetScript("OnLeave", function()
		ResetCursor()
	end)

	D.resize:EnableMouse(YES)
	D.resize:SetScript("OnMouseDown", function(self)
		D:StartSizing("BOTTOMRIGHT")
	end)
	D.resize:SetScript("OnMouseUp", function(self,button)
		D:StopMovingOrSizing()
	end)
	D.resize.bg = D.resize:CreateTexture(nil,"BACKGROUND")
	D.resize.bg:SetAllPoints()
	D.resize.bg:SetColorTexture(1,1,1)

	D:SetMinResize(Dwidth, LINE_HT)
	D:SetMaxResize(Dwidth, 0)
	D:SetScript("OnSizeChanged", function(self,width,height)
		if A then A:SetSize(Awidth,height) end
		if not S.overlayJnl then S.height = height end
		local lineCnt = floor((height - LINE_HT)/LINE_HT+.25)
		if lineCnt ~= LineCnt then
			if not LineCnt then
				LineCnt = lineCnt
				go{sametop=YES, retrace=YES, ab=YES}	--or renewHdr(YES) if don't want to jump in the deep end
			elseif lineCnt > LineCnt then
				LineCnt = lineCnt
				go{action=GO.REPORT, sametop=YES, ab=YES}
			else
				for l=lineCnt+1,LineCnt do
					local d = D.line[l]
					if d then d:Hide() end
					if A then
						local d = A.line[l]
						if d then d:Hide() end
					end
				end
				LineCnt = lineCnt
			end
			slideD()
			if A then slideA() end
		end
	end)

	D:SetResizable(YES)
	D:SetMovable(YES)
	for _,f in ipairs{D, D.topleft, D.topright} do
		f:SetScript("OnDragStart", function()
			if S.overlayJnl then return end
			D:StartMoving()
		end)
		f:SetScript("OnDragStop", function()
			if S.overlayJnl then return end
			D:StopMovingOrSizing()
			S.x = D:GetLeft()
			S.y = D:GetTop()
		end)
		if not InCombatLockdown() then f:EnableMouse(YES) end
		f:RegisterForDrag("LeftButton")
	end

	D.hdr = CreateFrame("Frame", nil, D)	--report-heading
	D.hdr:SetPoint("TOPLEFT")
	D.hdr:SetPoint("BOTTOMRIGHT", D, "TOPRIGHT", -SCROLL_WIDTH, -LINE_HT)

	D.hdr.bg = D.hdr:CreateTexture(nil,"BACKGROUND")
	D.hdr.bg:SetAllPoints()
	D.hdr.bg:SetColorTexture(0,0,0x40/0xff)

	D.line={}

	D.breeds = newButton(60,D.hdr,{text="Merged"})
	D.breeds:SetPoint("LEFT", xx.breeds+2, 0)
	D.breeds:SetScript("OnMouseDown", function()
		S.merged = not S.merged
		GameTooltip:Hide()
		go{action=GO.MERGE}
	end)

	local function slot(i)
		return {"Slot #"..i, tip="Place in battle-slot", function()
			local pet = D.clickedPet
			if not pet.owned then
				warn "You don't own this pet"
				return
			end
			if not PetJournal then
				warn "Pet-Journal not opened yet"
				return
			end
			local id,_,_,_,locked = PJ.GetPetLoadOutInfo(i)
			if locked then
				warn "Battle-slot is locked"
				return
			end
			PJ.SetPetLoadOutInfo(i, pet.id)
			PetJournal_UpdatePetLoadOut()
		end}
	end
	D.spidMenu = {
	{
		"View", tip="View in open Pet-journal or AH",
		function()
			local pet = D.clickedPet
			local sp = pet.sp
			if PetJournal and PetJournal:IsVisible() then
				if not sp or not sp.ownable then
					warn "Pet not ownable"
					return
				end
				if pet.owned then
					PetJournal_SelectPet(PetJournal,pet.id)
				else
					PetJournal_SelectSpecies(PetJournal,pet.spid)
				end
			elseif AuctionHouseFrame and AuctionHouseFrame:IsShown() then
				if not sp or not sp.ownable or not sp.tradeable then
					warn "Pet not tradeable"
					return
				end
--				C_AuctionHouse.ReplicateItems(sp.name)
				AuctionHouseFrame.SearchBar.SearchBox:SetText(sp.name)
				AuctionHouseFrame.SearchBar.SearchButton:Click()
			else
				warn "Neither Pet-journal nor AH is open"
			end
		end,
	},
	slot(1),
	slot(2),
	slot(3),
	{
		"Summon",
		function()
			local pet = D.clickedPet
			if not pet.owned then
				warn "You don't own this pet"
				return
			end
			if not PJ.PetIsSummonable(pet.id) then
				warn "Pet cannot be summoned"
				return
			end
			PJ.SummonPetByGUID(pet.id)
		end,
	},
	{
		"Cage", tip="Put in cage",
		function()
			local pet = D.clickedPet
			if not pet.owned then
				warn "You don't own this pet"
				return
			end
			local sp = pet.sp
			if not sp.tradeable then
				warn "Pet not cageable"
				return
			end
			if PJ.PetIsSlotted(pet.id) then
				warn "Pet is in battle-slot"
				return
			end
			PJ.CagePetByID(pet.id)
		end,
--	},
--	{
--		"Release",
--		function()
--			local pet = D.clickedPet
--			if not pet.owned then
--				warn "You don't own this pet"
--				return
--			end
--			if PJ.PetIsSlotted(pet.id) then
--				warn "Pet is in battle-slot"
--				return
--			end
--			if not PJ.PetCanBeReleased(pet.id) then
--				warn "Pet cannot be released"
--				return
--			end
--			PJ.ReleasePetByID(pet.id)	--too risky
--		end,
	}}
	frameMenu(D.spidMenu)

	local function initColumn(column, width, heading, tip, menu, point, checkfn, checkedfn, onRightClick)
		if tip then
			if menu or onRightClick then
				tip = tip.." (click to sort, right-click to de/select)"
			else
				tip = tip.." (click to sort)"
			end
		end
 		local f = newButton(width, D.hdr, {text=heading, tip=tip})
		f.checkedfn = checkedfn
		f:SetScript("OnMouseDown", function(self,button)
			if button ~= "RightButton" then
				if S.petColumn==column then
					S.petReversed = not S.petReversed
				else
					S.petReversed = nil
				end
				S.petColumn=column
				go{action=PetNdx and GO.SORT}
			else
				if onRightClick then onRightClick() end
				if menu then
					if menu.frame:IsShown() then
						if checkfn then checkfn(not f.green) end
					else
						popupMenu(menu,point)
					end
				end
			end
		end)
		D[column] = f
		f:SetPoint("LEFT",xx[column],0)
		if menu then
			frameMenu(menu)
			if point then menu.frame:SetPoint(
				point=="BOTTOMLEFT" and "TOPLEFT" or
				point=="BOTTOMRIGHT" and "TOPRIGHT" or
				point=="BOTTOM" and "TOP",
				f,
				point)
			end
			menu.frame:Hide()
		end
	end

	initColumn("spid", 22, "I", "Species-id", nil, nil, nil,
		function()
			return not S.spid
		end,
		function()
			if S.spid then
				S.spid = nil
				go{}
			end
		end
	)

	local PetSourceMenu = {}
	for k=1,#Source do PetSourceMenu[k] = {
		Source[k],
		function(m)
			if m.checked then
				if not S.sources then S.sources={} end
				S.sources[k] = YES
				if tableCount(S.sources) == #Source then
					S.sources=nil
				end
			else
				if not S.sources then
					S.sources={}
					for k=1,#Source do
						S.sources[k] = YES
					end
				end
				S.sources[k] = nil
			end
			go{}
		end,
		function()
			return not S.sources or S.sources[k]
		end,
	} end

	D.petMenu = {}
	for i,v in ipairs(PetMenu) do D.petMenu[i] = {
		v,
		function(m)
			S.pets[i] = m.checked
			go{}
		end,
		function()
			return S.pets[i]
		end,
	} end
	for i,v in ipairs(SpeciesMenu) do D.petMenu[#PetMenu+i] = {
		v,
		function(m)
			S.species[i] = m.checked
			go{}
		end,
		function()
			return S.species[i]
		end,
	} end
	D.petMenu[#D.petMenu+1] = {
		"Source",
		function(m)
			if m.checked then
				S.sources = nil
			else
				S.sources = {}
			end
			refreshMenu(m.menu)
			go{}
		end,
		function()
			return not S.sources
		end,
		menu=PetSourceMenu,
	}
	initColumn("name", 60, "Name", "Name", D.petMenu, nil, nil,
		function()
			for k in ipairs(PetMenu) do if k~=PET.UNOWNED then
				if not S.pets[k] then return NO end
			end end
			for k in ipairs(SpeciesMenu) do
				if not S.species[k] then return NO end
			end
			return not S.sources
		end
	)

 	D.spec = CreateFrame("EditBox", "PetScan_Spec", D.hdr, "InputBoxTemplate")
	D.spec:SetSize(60,20)
	D.spec:SetPoint("LEFT", D.name, "RIGHT", 6, 0)
	D.spec:SetBlinkSpeed(1)
	D.spec:SetMaxLetters(100)
	D.spec:SetFontObject("GameFontNormalSmall")
	D.spec:SetTextColor(1,1,1)
	D.spec:SetAutoFocus(NO)
	D.spec:SetScript("OnKeyUp", function()
		if S.spid then
			S.spid = nil
		end
		S.spec = D.spec:GetText()
		if S.spec=="" then
			S.spec=nil
		end
		go{preserveInputs=YES}
	end)
	D.spec:SetScript("OnEscapePressed", function() hideD() end)
	tip(D.spec,"Search by pet-name")

	D.count = D.hdr:CreateFontString(nil, nil, "GameFontNormal")
	D.count:SetPoint("LEFT", D.spec, "RIGHT", 2, 0)
	D.count:SetFont(NARROW_FONT, S.fontHt)
	D.count:SetTextColor(1,1,1)

	D.familyMenu = {}
	for k=1,#Family do D.familyMenu[k] = {
		Family[k],
		function(m)
			if m.checked then
				if not S.families then S.families={} end
				S.families[k] = YES
				if tableCount(S.families) == #Family then
					S.families=nil
				end
			else
				if not S.families then
					S.families={}
					for k=1,#Family do
						S.families[k] = YES
					end
				end
				S.families[k] = nil
			end
			go{}
		end,
		function()
			return not S.families or S.families[k]
		end,
		icon = FamilyIcon[k],
	} end
	initColumn("family", 20, "F", "Family", D.familyMenu, "BOTTOMRIGHT",
		function(checked)
			if checked then
				S.families = nil
			else
				S.families = {}
			end
			refreshMenu(D.familyMenu)
			go{}
		end,
		function()
			return not S.families
		end
	)

	do
		local function allTicked(menu,abilities)
			if not abilities then return NO end
			for k,v in ipairs(menu) do
				local m = v[2]
		  		if type(m) == "table" then
					if not allTicked(m,abilities[k]) then return NO end
				else
					if not abilities[k] then return NO end
				end
			end
			return YES
		end
		local function tickAll(menu,abilities,ticked)
			for k,v in ipairs(menu) do
				local m = v[2]
		  		if type(m) == "table" then
					if not abilities[k] then abilities[k]={} end
					tickAll(m,abilities[k],ticked)
				else
					abilities[k]=ticked
				end
			end
		end
		local function addmeta()	--so that S.abilities(k1,..,kn)=S.abilities[k1]..[kn]
			setmetatable(S.abilities, {__call=function(s,m)
				return apply(s, menuPath(m))
			end})
		end
		if S.abilities then addmeta() end
		local function init()
			if not S.abilities then
				S.abilities={}
				addmeta()
				tickAll(PetScanFormulas, S.abilities, YES)
			end
		end
		local function effect(menu)
			local submenu = {}
			local lines = menu[2]
			if lines then for k,v in ipairs(lines) do
				submenu[k] = type(v[2]) == "table" and effect(v) or {
					v[1],
					function(m)
						init()
						S.abilities(m.parent.lparent)[k] = m.checked or nil
						if m.checked and allTicked(PetScanFormulas, S.abilities) then
							S.abilities = nil
						end
						go{ab=YES}
					end,
					function(m)
						return not S.abilities or S.abilities(m)
					end,
					tip = v.tip
				}
			end end
			return {
				menu[1],
				lines and function(m)
					init()
					tickAll(menu[2], S.abilities(m), m.checked or nil)
					refreshMenu(m.menu)
					if m.checked and allTicked(PetScanFormulas, S.abilities) then
						S.abilities = nil
					end
					--for a in pairs(Ability) do if not SelectedAbilities[a] then print(a,Ability[a].name) end end
					go{ab=YES}
				end,
				lines and function(m)
					return subcheckedMenu(m.menu)
				end,
				tip = menu.tip,
				menu=submenu
			}
		end
		D.abilityMenu = effect{"", PetScanFormulas}.menu
		initColumn("ability", 60, "Abilities", "Abilities", D.abilityMenu, "BOTTOM",
			function(checked)
				if checked then
					S.abilities = nil
				else
					S.abilities={}
					addmeta()
					tickAll(PetScanFormulas, S.abilities, nil)
				end
				refreshMenu(D.abilityMenu)
				go{ab=YES}
			end,
			function()
				return not S.abilities
			end,
			function()
				if S.ability then
					S.ability = nil
					go{}
				end
			end
		)
	end

	D.abwin = newButton(16, D.hdr)
	modButton(D.abwin, {text=">>", tip="Abilities Window"})
	D.abwin:SetScript("OnMouseDown", function()
		if not A then
			formatA()
			D.resize:SetWidth(Dwidth+Awidth)
			goA{}
			if S.ability then focusAbility() end
		elseif not A:IsShown() then
			if S.ability then focusAbility() end
			A:Show()
			D.resize:SetWidth(Dwidth+Awidth)
		else
			A:Hide()
			D.resize:SetWidth(Dwidth)
		end
	end)
	D.abwin:SetPoint("LEFT", D.ability, "RIGHT", 2, 0)

 	D.abil = CreateFrame("EditBox", "PetScan_Abil", D.hdr, "InputBoxTemplate")
	D.abil:SetSize(64,20)
	D.abil:SetPoint("LEFT", D.abwin, "RIGHT", 6, 0)
	D.abil:SetBlinkSpeed(1)
	D.abil:SetMaxLetters(100)
	D.abil:SetFontObject("GameFontNormalSmall")
	D.abil:SetTextColor(1,1,1)
	D.abil:SetAutoFocus(NO)
	D.abil:SetScript("OnKeyUp", function()
		if S.ability then
			S.ability = nil
		end
		local s = D.abil:GetText()
		if s=="" then
			s=nil
		else
			local a = tonumber(s)
			if a then
				if not Ability[a] then return end
				S.ability = a
				focusAbility()
				go{preserveInputs=YES}
				return
			end
		end
		S.abil = s
		go{preserveInputs=YES, ab=YES}
	end)
	D.abil:SetScript("OnEscapePressed", function() hideD() end)
	tip(D.abil, "Search for ability by name or id")

	initColumn("health", 26)
	initColumn("power", 26)
	initColumn("speed", 26)
end

--Start

local function loadBP()	--load PetScanSpecies from BPB (debug only)
	s = {}
	for i,v in ipairs(BPBID_Arrays.BasePetStats) do		--incomplete if any element nil
		s[i] = v and {v[1],v[2],v[3],BPBID_Arrays.BreedsPerSpecies[i]}
	end
	--errata
	s[122][BASEP]=8
	s[1903][BASES]=0
	s[1978][BREEDS]=3
	s[1979][BREEDS]=3
	s[2114][BREEDS]=3
	s[2136][BREEDS]=3
	return s
end

local function saveBP()	--save BPB arrays (debug only)
	local t = "{"
	for i,v in ipairs(loadBP()) do
	if v then t = t .. "\t{"
		.. (v[1] or "nil")
		.. ",\t"
		.. (v[2] or "nil")
		.. ",\t"
		.. (v[3] or "nil")
		.. ",\t"
		.. (v[4] and (#v[4]==10 and "All" or dumpArray(v[4])) or "")
		.. "},\n"
	else
		t = t .. "\tnil,\n"
	end end
	S.PetScanSpecies = t
end

local function initS()
	PetScanInit()
	if not PetScan then PetScan={} end
	S = PetScan
	if not S.alpha then S.alpha=1 end
	if not S.height then S.height=21*LINE_HT end
	if not S.report then S.report=REPORT.ACTUAL end
	if not S.fontHt then S.fontHt=13 end	--10 = standard font-height for FrameFontNormalSmall
	if not S.species then
		S.species={}
		for k in ipairs(SpeciesMenu) do
			S.species[k] = k~=SP.NONBATTLER and k~=SP.UNOWNABLE
		end
	end
	if not S.pets then
		S.pets={}
		for k in ipairs(PetMenu) do
			S.pets[k] = k~=PET.UNOWNED
		end
	end
	if not S.topPet then S.topPet=0 end
	if not S.topAb then S.topAb=0 end
	if S.version ~= Version then
		S.version = Version
		S.abilities = nil
	end
	saveH()
end

function Event.PET_JOURNAL_LIST_UPDATE()
--Issued whenever any change is made to Pet Journal, e.g. filters, pet health-change.
--Also triggered whenever pass through a major portal.
--Schedules a database-reload on next report-request.
--Doesn't cater for PetJournalEnhanced because
--(1) it signals no event
--(2) its filters don't affect the PJ functions called below
	LoadPending = LoadPending+1
	if LoadPending>0 then modButton(D.go,{green=NO}) end
end

local function showD(overlayJnl)
	local function placeD()
		D:ClearAllPoints()
		S.overlayJnl = overlayJnl
		if overlayJnl then
			D:SetParent(PetJournal)
			D:SetFrameStrata("DIALOG")
			D:SetPoint("TOPLEFT",100,-88)
			D.topleft:Hide()
			D:SetSize(Dwidth,Dheight)	--launches report via OnSizeChanged
		else
			D:SetParent(UIParent)
			D:SetFrameStrata("DIALOG")	--could be "HIGH", but better on top of Collections-frame
			if S.x and S.y then
				D:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", S.x, S.y)
			else
				D:SetPoint("TOP", UIParent, "TOP", 0, -40)
			end
			D.topleft:Show()
			D:SetSize(Dwidth,S.height)	--launches report via OnSizeChanged
		end
	end
	S.visible = YES
	if D then
		D:Show()
		if overlayJnl ~= (S.overlayJnl or NO) then
			placeD()
		end
	else
		buildFamily()
		buildSource()
		buildSpecies()
		buildAbility()
		--saveBP()
		formatD()
		setAlpha()
		placeD()
		LoadPending=1
		E:RegisterEvent "PET_JOURNAL_LIST_UPDATE"
	end
end

local function playerLogin()
	print("PetScan v"..Version, "("..LIGHTBLUE.."/ps|r to start)")
	--MyLocale = GetLocale()
	--MyLocaleFont = STANDARD_TEXT_FONT

	SlashCmdList.PETSCAN = function()
		if not S then initS() end
		showD(NO)
	end
	SLASH_PETSCAN1 = "/PetScan"
	SLASH_PETSCAN2 = "/ps"

	local f = CreateFrame("Frame", "PetScanInterfaceOptionsPanel", InterfaceOptionsFramePanelContainer)
	f.name = "PetScan"
	InterfaceOptions_AddCategory(f)
	f.txt = f:CreateFontString(nil, nil, "GameFontNormal")
	f.txt:SetPoint("TOPLEFT",16,-16)
	f.txt:SetText("To start, key "..LIGHTBLUE.."/ps|r or "..LIGHTBLUE.."/PetScan|r or click the "..RED.."PS|r button on the Pet-journal")

	local bg = GameTooltip:CreateTexture(nil,"BACKGROUND",nil,1)	--make background opaque
	bg:SetPoint("TOPLEFT",3,-3)
	bg:SetPoint("BOTTOMRIGHT",-3,3)
	bg:SetColorTexture(0,0,0)
end

function Event.PLAYER_LOGIN()
	E:UnregisterEvent "PLAYER_LOGIN"
	playerLogin()
end

function Event.ADDON_LOADED(name)
	if name == "PetScan" then
		if IsLoggedIn() then
			playerLogin()
		else
			E:RegisterEvent "PLAYER_LOGIN"
		end
	elseif name == "Blizzard_Collections" then
		local f = CreateFrame("Button", nil, PetJournal, "UIPanelButtonTemplate")
		f:SetPoint("LEFT",PetJournalTutorialButton,"RIGHT",-20,0)
		f:SetSize(30,30)
		f:SetText("PS")
		f.tooltipText = "Left-click to toggle PetScan in Pet-journal, right-click to toggle it outside"
		f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		f:SetScript("OnClick", function(self,button)
			local lc = button ~= "RightButton"
			if D and D:IsVisible() and lc == (S.overlayJnl and YES or NO) then
				hideD()
			else
				showD(lc)
			end
		end)
		if not S then initS() end
		if S.overlayJnl and S.visible then
			showD(YES)
		end
	end
--	E:UnregisterEvent "ADDON_LOADED"	safe if always logged in when open collection-tab
end

E = CreateFrame ("Frame")
E:SetScript("OnEvent", function(self,e,...) Event[e](...) end)
E:RegisterEvent "ADDON_LOADED"

