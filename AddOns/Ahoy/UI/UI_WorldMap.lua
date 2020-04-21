
Ahoy.WorldMapIcons = {}
Ahoy.VisibleIcons = {}
Ahoy.WorldmMapIconLimit = 10;
Ahoy.CurrentMapID = nil;
Ahoy.CurrentMapName = "";
Ahoy.MapIconsLoaded = false;


function Ahoy_CreateMapPins()
	for i = 1, Ahoy.WorldmMapIconLimit, 1 do
		local mapIcon = CreateFrame("Frame","Ahoy_MapIcon_".. i,WorldMapFrame.ScrollContainer.Child)
		mapIcon:SetFrameStrata("HIGH")
		mapIcon:SetWidth(20)
		mapIcon:SetHeight(20)
		mapIcon:SetPoint("BOTTOMLEFT",i * 400, 100)
		local mapIcon_Texture = mapIcon:CreateTexture("Ahoy_MapIconTexture_".. i)
		mapIcon_Texture:SetTexture("Interface\\AddOns\\Ahoy\\Main.blp");
		mapIcon_Texture:SetTexCoord(0.54, .665, .43, 0.55) 
		mapIcon_Texture:SetAllPoints(mapIcon)
		mapIcon.texture = mapIcon_Texture;
		Ahoy.WorldMapIcons[i] = mapIcon;
		Ahoy.VisibleIcons[i] = false;
		mapIcon:Hide();
	end
end

function Ahoy_ClearMapPins()
	for i = 1, Ahoy.WorldmMapIconLimit, 1 do
		if Ahoy.WorldMapIcons[i] ~= nil then
			Ahoy.WorldMapIcons[i]:Hide();
		end
	end
end

function Ahoy_UpdateMap( isOpen )
	if Ahoy.DoingIslandExpedition == true then
		if Ahoy_Settings_New.MapIcons == true then
			Ahoy_ClearMapPins();
			Ahoy.CurrentMapID = WorldMapFrame:GetMapID();
			if Ahoy.CurrentMapID ~= nil then
				local uiMapDetails = C_Map.GetMapInfo(Ahoy.CurrentMapID);
				Ahoy.CurrentMapName = uiMapDetails.name;
				if AhoyMapDB[Ahoy.CurrentMapName] ~= nil then
					local pinNumber = getn(AhoyMapDB[Ahoy.CurrentMapName]);
					for p = 1, pinNumber, 1 do
						if Ahoy.WorldMapIcons[p] ~= nil then
							local x = 0.0;
							local y = 0.0;
							local dataArray = AhoyMapDB[Ahoy.CurrentMapName];
							local dataString = dataArray[p];
							local type, xPercentStr, yPercentStr = strsplit('|',dataString);
							local xPercent = tonumber(xPercentStr);
							local yPercent = tonumber(yPercentStr);
							local mapSizeX = WorldMapFrame.ScrollContainer.Child:GetWidth();
							local mapSizeY = WorldMapFrame.ScrollContainer.Child:GetHeight();
							local x = (xPercent / 100) * mapSizeX;
							local y = (yPercent / 100) * mapSizeY;
							if type == "Rare" then
								Ahoy.WorldMapIcons[p].texture:SetTexCoord(0.54, .665, .43, 0.55) 
							elseif type == "Cave" then
								Ahoy.WorldMapIcons[p].texture:SetTexCoord(0.54-.13, .665-.15, .43, 0.55) 
							end
							local iconSize = mapSizeX/25;
							Ahoy.WorldMapIcons[p]:ClearAllPoints();
							Ahoy.WorldMapIcons[p]:SetPoint("BOTTOMLEFT", x-(iconSize/2) , y-(iconSize/2));
							Ahoy.WorldMapIcons[p]:SetWidth(iconSize)
							Ahoy.WorldMapIcons[p]:SetHeight(iconSize)
							if Ahoy.MapIconsLoaded == false then
								Ahoy.VisibleIcons[p] = true;
						
							end
							if Ahoy.VisibleIcons[p] == true then
								Ahoy.WorldMapIcons[p]:Show();
							end
						end
					end
					if Ahoy.MapIconsLoaded == false then
						Ahoy.MapIconsLoaded = true;
					end
				else
					Ahoy_ClearMapPins();
				end
			end
		else
			Ahoy_ClearMapPins();
		end
	else
		Ahoy_ClearMapPins();
	end
end

function Ahoy_WorldMapInitialize()
	Ahoy_CreateMapPins();
	Ahoy_ClearMapPins();
end