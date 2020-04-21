----------------------------------------------------------
--	SplashScreen Window									--
----------------------------------------------------------

----------------------------------------------------------
--	Globals												--
----------------------------------------------------------

Ahoy.animateBackground = true;
Ahoy.TimeSinceLastUpdate = 0;
Ahoy.cloudTexCoordIncrement = 0;

----------------------------------------------------------
--	UI													--
----------------------------------------------------------

Ahoy.SplashscreenWindowFrame = CreateFrame("Frame",nil,Ahoy.MainFrame)
Ahoy.SplashscreenWindowFrame:SetWidth(430) -- Set these to whatever height/width is needed 
Ahoy.SplashscreenWindowFrame:SetHeight(150) -- for your Texture
Ahoy.SplashscreenWindowFrame:SetPoint("CENTER",0,0)
Ahoy.SplashscreenWindowFrame_Texture = Ahoy.SplashscreenWindowFrame:CreateTexture() 
Ahoy.SplashscreenWindowFrame_Texture:SetAllPoints() 
Ahoy.SplashscreenWindowFrame_Texture:SetTexture("Interface/garrison/garrisonmissionlocationnagrandsea", "REPEAT", "REPEAT");
Ahoy.SplashscreenWindowFrame_Texture:SetTexCoord(0, 1, 0, 0.25) 
Ahoy.SplashscreenWindowFrame_Texture:SetHorizTile(true)
Ahoy.SplashscreenWindowFrame.background = Ahoy.SplashscreenWindowFrame_Texture
Ahoy.SplashscreenWindowFrame:SetFrameLevel(8);

Ahoy.SplashScreenWater = CreateFrame("Frame",nil,Ahoy.SplashscreenWindowFrame)
Ahoy.SplashScreenWater:SetWidth(430) -- Set these to whatever height/width is needed 
Ahoy.SplashScreenWater:SetHeight(200) -- for your Texture
Ahoy.SplashScreenWater:SetPoint("CENTER",0,25)
Ahoy.SplashScreenWater_Texture = Ahoy.SplashScreenWater:CreateTexture() 
Ahoy.SplashScreenWater_Texture:SetAllPoints() 
Ahoy.SplashScreenWater_Texture:SetTexture("Interface/garrison/garrisonmissionlocationnagrandsea");
Ahoy.SplashScreenWater_Texture:SetTexCoord(0, 1, 0.5, 0.8) 
Ahoy.SplashScreenWater.background = Ahoy.SplashScreenWater_Texture
Ahoy.SplashScreenWater:SetFrameLevel(9);

Ahoy.SplashScreenWaterReflection = CreateFrame("Frame",nil,Ahoy.SplashscreenWindowFrame)
Ahoy.SplashScreenWaterReflection:SetWidth(430) -- Set these to whatever height/width is needed 
Ahoy.SplashScreenWaterReflection:SetHeight(70) -- for your Texture
Ahoy.SplashScreenWaterReflection:SetPoint("CENTER",0,-45)
Ahoy.SplashScreenWaterReflection:SetAlpha(.2);
Ahoy.SplashScreenWaterReflection_Texture = Ahoy.SplashScreenWaterReflection:CreateTexture() 
Ahoy.SplashScreenWaterReflection_Texture:SetAllPoints() 
Ahoy.SplashScreenWaterReflection_Texture:SetTexture("Interface/garrison/garrisonmissionlocationnagrandsea", "REPEAT", "REPEAT");
Ahoy.SplashScreenWaterReflection_Texture:SetTexCoord(0, 1, 0.125, 0) 
Ahoy.SplashScreenWaterReflection_Texture:SetHorizTile(true)
Ahoy.SplashScreenWaterReflection.background = Ahoy.SplashScreenWaterReflection_Texture
Ahoy.SplashScreenWaterReflection:SetFrameLevel(10);

local SplashScreenLogo = CreateFrame("Frame",nil,Ahoy.SplashscreenWindowFrame)
SplashScreenLogo:SetWidth(240) -- Set these to whatever height/width is needed 
SplashScreenLogo:SetHeight(90) -- for your Texture
SplashScreenLogo:SetPoint("LEFT",30,0)
local SplashScreenLogo_Texture = SplashScreenLogo:CreateTexture() 
SplashScreenLogo_Texture:SetAllPoints() 
SplashScreenLogo_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
SplashScreenLogo_Texture:SetTexCoord(0, 0.468, 0, 0.175) 
SplashScreenLogo.background = SplashScreenLogo_Texture
SplashScreenLogo:SetFrameLevel(11);

Ahoy.SplashScreenInfo = CreateFrame("Frame",nil,Ahoy.SplashscreenWindowFrame)
Ahoy.SplashScreenInfo:SetWidth(240) -- Set these to whatever height/width is needed 
Ahoy.SplashScreenInfo:SetHeight(90) -- for your Texture
Ahoy.SplashScreenInfo:SetPoint("BOTTOMRIGHT",0,0)
Ahoy.SplashScreenInfo:SetFrameLevel(12);
Ahoy.SplashScreenInfo.text = Ahoy.SplashScreenInfo.text or Ahoy.SplashScreenInfo:CreateFontString(nil,"ARTWORK","GameFontNormal")
Ahoy.SplashScreenInfo.text:SetAllPoints(true)
Ahoy.SplashScreenInfo.text:SetJustifyH("RIGHT")
Ahoy.SplashScreenInfo.text:SetJustifyV("BOTTOM")
Ahoy.SplashScreenInfo.text:SetText("Ahoy v" .. Ahoy.Version .. "\n" .. "by Songzee");
Ahoy.SplashScreenInfo.text:SetFont("fonts/arhei.ttf", 10, "NONE")
Ahoy.SplashScreenInfo.text:SetTextColor(1,1,1,0.5)
