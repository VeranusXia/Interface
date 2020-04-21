----------------------------------------------------------
--	Rewards Window										--
----------------------------------------------------------

----------------------------------------------------------
--	Globals												--
----------------------------------------------------------

Ahoy.RewardBlocks = {}

----------------------------------------------------------
--	UI													--
----------------------------------------------------------

Ahoy.RewardsWindowFrame = CreateFrame("Frame",nil,Ahoy.MainFrame)
Ahoy.RewardsWindowFrame:SetWidth(430) -- Set these to whatever height/width is needed 
Ahoy.RewardsWindowFrame:SetHeight(150) -- for your Texture
Ahoy.RewardsWindowFrame:SetPoint("CENTER",0,0)
local RewardsWindowFrame_Texture = Ahoy.RewardsWindowFrame:CreateTexture() 
RewardsWindowFrame_Texture:SetAllPoints() 
RewardsWindowFrame_Texture:SetColorTexture(0,0,0,0.8)
Ahoy.RewardsWindowFrame.background = RewardsWindowFrame_Texture
Ahoy.RewardsWindowFrame.text = Ahoy.RewardsWindowFrame.text or Ahoy.RewardsWindowFrame:CreateFontString(nil,"ARTWORK","GameFontNormal")
Ahoy.RewardsWindowFrame.text:SetAllPoints(true)
Ahoy.RewardsWindowFrame.text:SetJustifyH("CENTER")
Ahoy.RewardsWindowFrame.text:SetJustifyV("CENTER")
Ahoy.RewardsWindowFrame:Hide()

-- Close Rewards Button --
local CloseRewardsButton = CreateFrame("Button", nil, Ahoy.RewardsWindowFrame)
CloseRewardsButton:SetPoint("CENTER", 0, -90)
CloseRewardsButton:SetWidth(120)
CloseRewardsButton:SetHeight(30)
CloseRewardsButton:SetText("Close Rewards")
CloseRewardsButton:SetNormalFontObject("GameFontNormal")
local CloseRewardsButton_ntex = CloseRewardsButton:CreateTexture()
CloseRewardsButton_ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
CloseRewardsButton_ntex:SetTexCoord(0, 0.625, 0, 0.6875)
CloseRewardsButton_ntex:SetAllPoints()	
CloseRewardsButton:SetNormalTexture(CloseRewardsButton_ntex)
local CloseRewardsButton_htex = CloseRewardsButton:CreateTexture()
CloseRewardsButton_htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
CloseRewardsButton_htex:SetTexCoord(0, 0.625, 0, 0.6875)
CloseRewardsButton_htex:SetAllPoints()
CloseRewardsButton:SetHighlightTexture(CloseRewardsButton_htex)
local CloseRewardsButton_ptex = CloseRewardsButton:CreateTexture()
CloseRewardsButton_ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
CloseRewardsButton_ptex:SetTexCoord(0, 0.625, 0, 0.6875)
CloseRewardsButton_ptex:SetAllPoints()
CloseRewardsButton:SetPushedTexture(CloseRewardsButton_ptex)
CloseRewardsButton:SetScript("OnClick", 
	function (self, button, down)
		Ahoy_WindowSwitch("Expedition")
	end)

----------------------------------------------------------
--	Functions											--
----------------------------------------------------------

for r = 0, 8, 1 do
	local RewardBlockFrame = CreateFrame("Frame",nil,Ahoy.RewardsWindowFrame)
	RewardBlockFrame:SetWidth(140)
	RewardBlockFrame:SetHeight(40)
	RewardBlockFrame:SetPoint("CENTER",0,0)
	local RewardBlockFrame_Texture = RewardBlockFrame:CreateTexture() 
	RewardBlockFrame_Texture:SetAllPoints() 
	RewardBlockFrame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
	RewardBlockFrame_Texture:SetTexCoord(0.47, 0.9, 0, 0.12)
	RewardBlockFrame.background = RewardBlockFrame_Texture
	RewardBlockFrame:SetHyperlinksEnabled(true)
	RewardBlockFrame:SetScript("OnMouseDown", 
		function() 
			child1, child2 = RewardBlockFrame:GetChildren();
			local link = child2.text:GetText();
			SetItemRef(link, link, nil, RewardBlockFrame)
		end)

	local RewardBlockIcon = CreateFrame("Frame",nil,RewardBlockFrame)
	RewardBlockIcon:SetWidth(38)
	RewardBlockIcon:SetHeight(38)
	RewardBlockIcon:SetPoint("LEFT",2,0)
	local RewardBlockIcon_Texture = RewardBlockIcon:CreateTexture() 
	RewardBlockIcon_Texture:SetAllPoints() 
	RewardBlockIcon.background = RewardBlockIcon_Texture

	local RewardBlockText = CreateFrame("Frame",nil,RewardBlockFrame)
	RewardBlockText:SetWidth(100)
	RewardBlockText:SetHeight(40)
	RewardBlockText:SetPoint("RIGHT",2,0)
	RewardBlockText.text = RewardBlockText.text or RewardBlockText:CreateFontString(nil,"ARTWORK","GameFontNormal")
	RewardBlockText.text:SetAllPoints(true)
	RewardBlockText.text:SetJustifyH("CENTER")
	RewardBlockText.text:SetJustifyV("CENTER")
	RewardBlockText.text:SetText(r);
	RewardBlockText:SetHyperlinksEnabled(true)
	RewardBlockText:SetScript("OnHyperlinkClick", 
	function(self,link,text,button) 
		SetItemRef(link, text, button, RewardBlockFrame)
	end);

	Ahoy.RewardBlocks[r] = RewardBlockFrame;
end

function RewardBlocksReposition (blockNumber)
	for r = 0, 8, 1 do
		if blockNumber-1 < r then
			Ahoy.RewardBlocks[r]:Hide();
		else
			Ahoy.RewardBlocks[r]:Show();
		end
	end
	local spacing = 5;
	-- 1x1 --
	if blockNumber == 1 then
		Ahoy.RewardBlocks[0]:SetPoint("CENTER",0,0);
	end
	-- 2x1 --
	if blockNumber == 2 then
		Ahoy.RewardBlocks[0]:SetPoint("CENTER",-67.5 - spacing,0);
		Ahoy.RewardBlocks[1]:SetPoint("CENTER",67.5 + spacing,0);
	end
	-- 2x2 --
	if blockNumber > 2 and blockNumber < 5 then
		Ahoy.RewardBlocks[0]:SetPoint("CENTER",-67.5 - spacing,20 + spacing/2);
		Ahoy.RewardBlocks[1]:SetPoint("CENTER",67.5 + spacing,20 + spacing/2);
		Ahoy.RewardBlocks[2]:SetPoint("CENTER",-67.5 - spacing,-20 - spacing/2);
		Ahoy.RewardBlocks[3]:SetPoint("CENTER",67.5 + spacing,-20 - spacing/2);
	end
	-- 3x2 --
	if blockNumber > 4 and blockNumber < 7 then
		Ahoy.RewardBlocks[0]:SetPoint("CENTER",-135 - spacing,20 + spacing/2);
		Ahoy.RewardBlocks[1]:SetPoint("CENTER",0,20 + spacing/2);
		Ahoy.RewardBlocks[2]:SetPoint("CENTER",135 + spacing,20 + spacing/2);
		Ahoy.RewardBlocks[3]:SetPoint("CENTER",-135 - spacing,-20 - spacing/2);
		Ahoy.RewardBlocks[4]:SetPoint("CENTER",0,-20 - spacing/2);
		Ahoy.RewardBlocks[5]:SetPoint("CENTER",135 + spacing,-20 - spacing/2);
	end
	-- 3x3 --
	if blockNumber > 6 and blockNumber < 10 then
		Ahoy.RewardBlocks[0]:SetPoint("CENTER",-135 - spacing,40 + spacing);
		Ahoy.RewardBlocks[1]:SetPoint("CENTER",0,40 + spacing);
		Ahoy.RewardBlocks[2]:SetPoint("CENTER",135 + spacing,40 + spacing);
		Ahoy.RewardBlocks[3]:SetPoint("CENTER",-135 - spacing,0);
		Ahoy.RewardBlocks[4]:SetPoint("CENTER",0,0);
		Ahoy.RewardBlocks[5]:SetPoint("CENTER",135 + spacing,0);
		Ahoy.RewardBlocks[6]:SetPoint("CENTER",-135 - spacing,-40 - spacing);
		Ahoy.RewardBlocks[7]:SetPoint("CENTER",0,-40 - spacing);
		Ahoy.RewardBlocks[8]:SetPoint("CENTER",135 + spacing,-40 - spacing);
	end
end

function Ahoy_UpdateRewardsUI(numRewards)
	itemCounter = 0;
	for i = 1, numRewards do
		local texture, quantity, isBonus, bonusQuantity, name, quality, id, objectType = GetLFGCompletionRewardItem(i);
		if objectType == "item" then
			itemCounter = itemCounter + 1;
			local objectLink = GetLFGCompletionRewardItemLink(i);
			child1, child2 = Ahoy.RewardBlocks[itemCounter-1]:GetChildren();
			child1.background:SetTexture(texture);
			child2.text:SetText(objectLink);
		end
	end
	RewardBlocksReposition(itemCounter);
end
