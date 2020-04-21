---------------------------------------------------------
--------------------  Help Window  ----------------------
---------------------------------------------------------
Ahoy.HelpFrame = CreateFrame("Frame", name, Ahoy.MainFrame)
Ahoy.HelpFrame:SetSize(512, 512)
Ahoy.HelpFrame:SetPoint("CENTER", 2, 2)
Ahoy.HelpFrame_Texture = Ahoy.HelpFrame:CreateTexture() 
Ahoy.HelpFrame_Texture:SetAllPoints() 
Ahoy.HelpFrame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Help.blp");
--HelpFrame_Texture:SetTexCoord(0.9, 1, 0, 0.1)
Ahoy.HelpFrame.background = Ahoy.HelpFrame_Texture
Ahoy.HelpFrame:SetScript("OnMouseDown", 
function(self, arg1)
	Ahoy.HelpFrame:Hide();
end)
Ahoy.HelpFrame:SetFrameLevel(30);
Ahoy.HelpFrame:Hide();