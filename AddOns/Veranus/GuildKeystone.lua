----------------------
-- 显示公会大米记录
----------------------
local dungeonframe

local function AddFontString(self, fontSize, text, anchor)
	local fs = self:CreateFontString(nil, "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
	fs:SetText(text)
	fs:SetWordWrap(false)
	fs:SetPoint(unpack(anchor))

	return fs
end

local function UpdateTooltip(self)
	local leaderInfo = self.leaderInfo
	if not leaderInfo then return end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local name = C_ChallengeMode.GetMapUIInfo(leaderInfo.mapChallengeModeID)
	GameTooltip:SetText(name, 1, 1, 1)
	GameTooltip:AddLine(CHALLENGE_MODE_POWER_LEVEL:format(leaderInfo.keystoneLevel))
	for i = 1, #leaderInfo.members do
		local classColorStr = RAID_CLASS_COLORS[leaderInfo.members[i].classFileName].colorStr
		GameTooltip:AddLine(CHALLENGE_MODE_GUILD_BEST_LINE:format(classColorStr,leaderInfo.members[i].name));
	end
	GameTooltip:Show()
end

local function CreateBoard()
	dungeonframe = CreateFrame("Frame", nil, ChallengesFrame)
	dungeonframe:SetPoint("BOTTOMRIGHT", -6, 80)
	dungeonframe:SetSize(170, 90)
	local bg = dungeonframe:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetAtlas("ChallengeMode-guild-background")
	bg:SetAlpha(.3)
	local header = AddFontString(dungeonframe, 14, CHALLENGE_MODE_THIS_WEEK, {"TOPLEFT", 16, -6})
	header:SetTextColor(1, .8, 0)

	dungeonframe.entries = {}
	for i = 1, 4 do
		local entry = CreateFrame("Frame", nil, dungeonframe)
		entry:SetPoint("LEFT", 10, 0)
		entry:SetPoint("RIGHT", -10, 0)
		entry:SetHeight(14)
		entry.CharacterName = AddFontString(entry, 12, "", {"LEFT", 6, 0})
		entry.CharacterName:SetPoint("RIGHT", -30, 0)
		entry.CharacterName:SetJustifyH("LEFT")
		entry.Level = AddFontString(entry, 12, "", {"LEFT", entry, "RIGHT", -22, 0})
		entry.Level:SetTextColor(1, .8, 0)
		entry.Level:SetJustifyH("LEFT")
		entry:SetScript("OnEnter", UpdateTooltip)
		entry:SetScript("OnLeave", GameTooltip_Hide)

		if i == 1 then
			entry:SetPoint("TOP", dungeonframe, 0, -26)
		else
			entry:SetPoint("TOP", dungeonframe.entries[i-1], "BOTTOM")
		end

		dungeonframe.entries[i] = entry
	end
end

local function SetUpRecord(self, leaderInfo)
	self.leaderInfo = leaderInfo
	local str = CHALLENGE_MODE_GUILD_BEST_LINE
	if leaderInfo.isYou then
		str = CHALLENGE_MODE_GUILD_BEST_LINE_YOU
	end

	local classColorStr = RAID_CLASS_COLORS[leaderInfo.classFileName].colorStr
	self.CharacterName:SetText(str:format(classColorStr, leaderInfo.name))
	self.Level:SetText(leaderInfo.keystoneLevel)
end

local resize
local function UpdateGuildBest(self)
	if not dungeonframe then CreateBoard() end
	if self.leadersAvailable then
		local leaders = C_ChallengeMode.GetGuildLeaders()
		if leaders and #leaders > 0 then
			for i = 1, #leaders do
				SetUpRecord(dungeonframe.entries[i], leaders[i])
			end
			dungeonframe:Show()
		else
			dungeonframe:Hide()
		end
	end

	if not resize and IsAddOnLoaded("AngryKeystones") then
		local scheduel = select(5, self:GetChildren())
		dungeonframe:SetWidth(246)
		dungeonframe:ClearAllPoints()
		dungeonframe:SetPoint("BOTTOMLEFT", scheduel, "TOPLEFT", 0, 10)

		--self.WeeklyInfo.Child.Label:SetPoint("TOP", -135, -25)
		local affix = self.WeeklyInfo.Child.Affixes[1]
		if affix then
			affix:ClearAllPoints()
			affix:SetPoint("TOPLEFT", 20, -55)
		end

		resize = true
	end
end

local function ChallengesOnLoad(self, event, addon)
	if addon == "Blizzard_ChallengesUI" then
		hooksecurefunc("ChallengesFrame_Update", UpdateGuildBest)
		self:UnregisterEvent(event)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", ChallengesOnLoad)