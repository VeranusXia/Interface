---------------------------------------------------------
------------------------  Menu  -------------------------
---------------------------------------------------------

local MenuFrame = CreateFrame("Frame", name, Ahoy.MainFrame)
local MenuItem1Frame = CreateFrame("Frame", name, MenuFrame)
local MenuItem2Frame = CreateFrame("Frame", name, MenuFrame)
local MenuItem3Frame = CreateFrame("Frame", name, MenuFrame)
local MenuItem4Frame = CreateFrame("Frame", name, MenuFrame)
local MenuItem5Frame = CreateFrame("Frame", name, MenuFrame)
MenuItem6Frame = CreateFrame("Frame", name, MenuFrame)

local function AhoyToggleMenu()
	if MenuFrame:IsVisible() == true then
		MenuFrame:Hide();
	else
		MenuFrame:Show();
	end
	Ahoy.SettingsWindowFrame:Hide()
end

MenuFrame:SetSize(170, 150)
MenuFrame:SetPoint("CENTER", 0, 100)
local MenuFrame_Texture = MenuFrame:CreateTexture() 
MenuFrame_Texture:SetAllPoints() 
MenuFrame_Texture:SetColorTexture(0,0,0,0)
MenuFrame.background = MenuFrame_Texture

MenuItem1Frame:SetSize(40, 40)
MenuItem1Frame:SetPoint("CENTER", 0, 50)
local MenuItem1Frame_Texture = MenuItem1Frame:CreateTexture() 
MenuItem1Frame_Texture:SetAllPoints() 
MenuItem1Frame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
MenuItem1Frame_Texture:SetTexCoord(0.9, 1, 0, 0.1)
MenuItem1Frame.background = MenuItem1Frame_Texture
MenuItem1Frame:SetScript("OnMouseDown", 
function(self, arg1)
	AhoyToggleMenu();
    Ahoy_DatabaseViewInitialize();
end)
MenuFrame:Hide();

MenuItem2Frame:SetSize(40, 40)
MenuItem2Frame:SetPoint("CENTER", -50, 10)
local MenuItem2Frame_Texture = MenuItem2Frame:CreateTexture() 
MenuItem2Frame_Texture:SetAllPoints() 
MenuItem2Frame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
MenuItem2Frame_Texture:SetTexCoord(0.9, 1, 0.12, 0.22)
MenuItem2Frame.background = MenuItem2Frame_Texture
MenuItem2Frame:SetScript("OnMouseDown", 
function(self, arg1)
	AhoyToggleMenu();
	Ahoy_LoadCheckButtonStates()
    Ahoy.SettingsWindowFrame:Show()
end)

MenuItem3Frame:SetSize(40, 40)
MenuItem3Frame:SetPoint("CENTER", 50, 10)
local MenuItem3Frame_Texture = MenuItem3Frame:CreateTexture() 
MenuItem3Frame_Texture:SetAllPoints() 
MenuItem3Frame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
MenuItem3Frame_Texture:SetTexCoord(0.9, 1, 0.235, 0.335) 
MenuItem3Frame.background = MenuItem3Frame_Texture
MenuItem3Frame:SetScript("OnMouseDown", 
function(self, arg1)
	AhoyToggleMenu();
    Ahoy.HelpFrame:Show();
end)

MenuItem4Frame:SetSize(40, 40)
MenuItem4Frame:SetPoint("CENTER", -100, 10)
local MenuItem4Frame_Texture = MenuItem4Frame:CreateTexture() 
MenuItem4Frame_Texture:SetAllPoints() 
MenuItem4Frame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
MenuItem4Frame_Texture:SetTexCoord(0.798, 0.9, 0.235, 0.335)
MenuItem4Frame.background = MenuItem4Frame_Texture
MenuItem4Frame:SetScript("OnMouseDown", 
function(self, arg1)
	local point, relativeTo, relativePoint, x, y = Ahoy.MainFrame:GetPoint(1);
	local currentScale = Ahoy.MainFrame:GetScale()
	local newScale = currentScale + 0.05;
	if newScale < 3 then
		Ahoy.MainFrame:SetScale(newScale);
		Ahoy_Settings_New.WindowScale = newScale;
		Ahoy_Settings = Ahoy_Settings_New;
		print ("Ahoy Scale: " .. newScale);
	end
end)

MenuItem5Frame:SetSize(40, 40)
MenuItem5Frame:SetPoint("CENTER", -150, 10)
local MenuItem5Frame_Texture = MenuItem5Frame:CreateTexture() 
MenuItem5Frame_Texture:SetAllPoints() 
MenuItem5Frame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
MenuItem5Frame_Texture:SetTexCoord(0.798, 0.9, 0.122, 0.22)
MenuItem5Frame.background = MenuItem5Frame_Texture
MenuItem5Frame:SetScript("OnMouseDown", 
function(self, arg1)
	local point, relativeTo, relativePoint, x, y = Ahoy.MainFrame:GetPoint(1);
	local currentScale = Ahoy.MainFrame:GetScale()
	local newScale = currentScale - 0.05;
	if newScale > 0.4 then
	Ahoy.MainFrame:SetScale(newScale);
		Ahoy_Settings_New.WindowScale = newScale;
		Ahoy_Settings = Ahoy_Settings_New;
		print ("Ahoy Scale: " .. newScale);
	end
end)

MenuItem6Frame:SetSize(40, 40)
MenuItem6Frame:SetPoint("CENTER", 100, 10)
local MenuItem6Frame_Texture = MenuItem6Frame:CreateTexture() 
MenuItem6Frame_Texture:SetAllPoints() 
MenuItem6Frame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
MenuItem6Frame_Texture:SetTexCoord(0.69, 0.79, 0.122, 0.22)
MenuItem6Frame.background = MenuItem6Frame_Texture
MenuItem6Frame:SetScript("OnMouseDown", 
function(self, arg1)
	Ahoy_Settings_New.WindowLocked = not Ahoy_Settings_New.WindowLocked;
	if Ahoy_Settings_New.WindowLocked then
		-- change icon to locked
		MenuItem6Frame.background:SetTexCoord(0.69, 0.79, 0.122, 0.22)
	else
		-- change icon to unlocked
		MenuItem6Frame.background:SetTexCoord(0.69, 0.79, 0.235, 0.335)
	end
	Ahoy_Settings = Ahoy_Settings_New;
end)

-------------------------------------------------------
---------------------- Hat OuO ------------------------
-------------------------------------------------------

Ahoy.HatFrame = CreateFrame("Frame",nil,Ahoy.MainFrame)
Ahoy.HatFrame:SetFrameStrata("BACKGROUND")
Ahoy.HatFrame:SetWidth(70) -- Set these to whatever height/width is needed 
Ahoy.HatFrame:SetHeight(45) -- for your Texture
Ahoy.HatFrame:SetPoint("CENTER",0,90)
Ahoy.HatFrame_Texture = Ahoy.HatFrame:CreateTexture("BACKGROUND")
Ahoy.HatFrame_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
Ahoy.HatFrame_Texture:SetTexCoord(0.75, 1, .5, 0.640625) 
Ahoy.HatFrame_Texture:SetAllPoints(Ahoy.HatFrame)
Ahoy.HatFrame:EnableMouse()
Ahoy.HatFrame:SetScript('OnEnter', 
function()
	Ahoy.HatFrame_Texture:SetTexCoord(0.75, 1, .5-0.140625, 0.640625-0.140625) 
	Ahoy.HatFrame:SetPoint("CENTER",0,95)
end)
Ahoy.HatFrame:SetScript('OnLeave', 
function()
	Ahoy.HatFrame_Texture:SetTexCoord(0.75, 1, .5, 0.640625) 
	Ahoy.HatFrame:SetPoint("CENTER",0,90)
end)
Ahoy.HatFrame:SetScript("OnMouseDown", 
function() 
	AhoyToggleMenu();
	Ahoy.HatFrame_Texture:SetTexCoord(0.75, 1, .5, 0.640625) 
	Ahoy.HatFrame:SetPoint("CENTER",0,90)
end)
