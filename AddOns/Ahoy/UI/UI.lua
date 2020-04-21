----------------------------------------------------------
-------------------- User Interface ----------------------
----------------------------------------------------------
--Ahoy.ScoreTime = 0.0; 
----------------------------------------------------------
--	Functions											--
----------------------------------------------------------

function Ahoy_WindowSwitch(window)
	if window == "Splashscreen" then
		Ahoy.SplashscreenWindowFrame:Show()
		Ahoy.QueueWindowFrame:Hide()
		Ahoy.ExpeditionWindowFrame:Hide()
		Ahoy.RewardsWindowFrame:Hide()
		Ahoy.animateBackground = true;
	end
	if window == "Queue" then
		Ahoy.SplashscreenWindowFrame:Hide()
		Ahoy.QueueWindowFrame:Show()
		Ahoy.ExpeditionWindowFrame:Hide()
		Ahoy.RewardsWindowFrame:Hide()
		Ahoy.animateBackground = false;
	end
	if window == "Expedition" then
		Ahoy.SplashscreenWindowFrame:Hide()
		Ahoy.QueueWindowFrame:Hide()
		Ahoy.ExpeditionWindowFrame:Show()
		Ahoy.RewardsWindowFrame:Hide()
		Ahoy.animateBackground = false;
	end
	if window == "Rewards" then
		Ahoy.SplashscreenWindowFrame:Hide()
		Ahoy.QueueWindowFrame:Hide()
		Ahoy.ExpeditionWindowFrame:Hide()
		Ahoy.RewardsWindowFrame:Show()
		Ahoy.animateBackground = false;
	end
end

----------------------------------------------------------
--	Start												--
----------------------------------------------------------

Ahoy_CreateTabFrames();
Ahoy_AdjustTabs(-1);
Ahoy_WindowSwitch("Splashscreen");

----------------------------------------------------------
--	Update												--
----------------------------------------------------------

local function GetDistance(x1, y1, x2, y2)
	return math.sqrt(math.pow((x2 - x1), 2) + math.pow((y2 - y1), 2));
end

function Ahoy_OnUpdate(self, elapsed)
	Ahoy.TimeSinceLastUpdate = Ahoy.TimeSinceLastUpdate + elapsed; 	
	while (Ahoy.TimeSinceLastUpdate > Ahoy.updateInterval) do
		Ahoy_UpdateLoop()
		Ahoy.TimeSinceLastUpdate = Ahoy.TimeSinceLastUpdate - Ahoy.updateInterval;
	end
end

local Ahoy_UpdateFrame = CreateFrame("frame")
Ahoy_UpdateFrame:SetScript("OnUpdate", Ahoy_OnUpdate)

function Ahoy_UpdateLoop ()
	if Ahoy.animateBackground then
		if Ahoy.windowIsDragged == false then
			Ahoy.cloudTexCoordIncrement = Ahoy.cloudTexCoordIncrement + 0.0004
			Ahoy.SplashscreenWindowFrame_Texture:SetTexCoord(0 + Ahoy.cloudTexCoordIncrement, 1 + Ahoy.cloudTexCoordIncrement, 0, 0.25);
			Ahoy.SplashScreenWaterReflection_Texture:SetTexCoord(0 + Ahoy.cloudTexCoordIncrement, 1 + Ahoy.cloudTexCoordIncrement, 0.125, 0) 
		end
	end
	-- Map icon tracker --
	if Ahoy.DoingIslandExpedition == true then
		if getn(Ahoy.VisibleIcons) > 0 then
			if Ahoy.CurrentMapID ~= nil then
				local playerPos = C_Map.GetPlayerMapPosition(Ahoy.CurrentMapID, "player")
				if playerPos ~= nil then
					local mapData = AhoyMapDB[Ahoy.CurrentMapName];
					for i = 1, Ahoy.WorldmMapIconLimit, 1 do
						if Ahoy.VisibleIcons[i] == true then
							local iconData = mapData[i];
							local type, xPercentStr, yPercentStr = strsplit('|',iconData);
							if GetDistance(playerPos.x * 100, (1 - playerPos.y)*100, xPercentStr, yPercentStr) < 3 then
								Ahoy.WorldMapIcons[i]:Hide()
								Ahoy.VisibleIcons[i] = false;
							end
						end
					end
				end
			end
		end
	end
	-- Score Tracker --
	if Ahoy_Settings_New.FlashCards == true then
		if Ahoy.DoingIslandExpedition == true then
			Ahoy.ScoreTime = Ahoy.ScoreTime + 0.1;
			Ahoy_UpdateFlashScore(amount)
		end
	end
end