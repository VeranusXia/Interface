----------------------------------------------------------
--	MAINFRAME!											--
----------------------------------------------------------

----------------------------------------------------------
--	Globals												--
----------------------------------------------------------
Ahoy.windowIsDragged = false;

----------------------------------------------------------
--	UI													--
----------------------------------------------------------

Ahoy.MainFrame = CreateFrame("Frame","Ahoy.MainFrame",UIParent)
Ahoy.MainFrame:Hide();
Ahoy.MainFrame:SetFrameStrata("BACKGROUND")
Ahoy.MainFrame:SetWidth(450) -- Set these to whatever height/width is needed 
Ahoy.MainFrame:SetHeight(170) -- for your Texture
Ahoy.MainFrame:SetPoint("BOTTOMLEFT",1403,448)
local textureFrame4 = Ahoy.MainFrame:CreateTexture("BACKGROUND")
textureFrame4:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
textureFrame4:SetTexCoord(0, 1, 0.640625, 1) 
textureFrame4:SetAllPoints(Ahoy.MainFrame)
Ahoy.MainFrame:SetMovable(true)
Ahoy.MainFrame:EnableMouse(true)
Ahoy.MainFrame:RegisterForDrag("LeftButton")
Ahoy.MainFrame:SetScript("OnDragStart", 
function() 
	if not Ahoy_Settings_New.WindowLocked then
		Ahoy.MainFrame:StartMoving() 
		Ahoy.windowIsDragged = true 
	end
end)
Ahoy.MainFrame:SetScript("OnDragStop", 
function() 
	if not Ahoy_Settings_New.WindowLocked then
		Ahoy.MainFrame:StopMovingOrSizing() 
		Ahoy.windowIsDragged = false
		local x = Ahoy.MainFrame:GetLeft()
		local y = Ahoy.MainFrame:GetBottom()
		Ahoy_Settings_New.MainFrameX = x
		Ahoy_Settings_New.MainFrameY = y
		Ahoy_Settings = Ahoy_Settings_New;
	end
end)
Ahoy.MainFrame:SetScript("OnMouseDown", 
function(self, arg1)
	if arg1 == "RightButton" then
		Ahoy_CloseMainframe()
		if Ahoy.InQueue == true then
			Ahoy.WindowClosedDuringQueue = true
		end
		if Ahoy.DoingIslandExpedition == false then
			Ahoy.WindowClosedOutsideExpedition = true
		end
	end
end)

----------------------------------------------------------
--	Functions											--
----------------------------------------------------------

function Ahoy_ToggleMainframe()
	if Ahoy.MainFrame:IsVisible() == true then
		Ahoy.MainFrame:Hide();
	else
		Ahoy.MainFrame:Show();
	end
end

function Ahoy_CloseMainframe()
	Ahoy.MainFrame:Hide();
end

function Ahoy_OpenMainframe()
	Ahoy.MainFrame:Show();
end

function Ahoy_MoveToSavedPosition()
	if Ahoy_Settings_New.MainFrameX ~= nil then
		Ahoy.MainFrame:ClearAllPoints()
		Ahoy.MainFrame:SetPoint("BOTTOMLEFT",Ahoy_Settings_New.MainFrameX,Ahoy_Settings_New.MainFrameY)
	end
end

function Ahoy_ResetMainframePosition()
		Ahoy.MainFrame:ClearAllPoints()
		Ahoy.MainFrame:SetPoint("CENTER",0,0)
		local x,y = Ahoy.MainFrame:GetCenter()
		Ahoy_Settings_New.MainFrameX = x
		Ahoy_Settings_New.MainFrameY = y
		Ahoy_Settings = Ahoy_Settings_New;
end

local function splits(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end