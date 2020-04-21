Ahoy = {}
Ahoy.Version = "1.10";
Ahoy.TabsCount = 16;
Ahoy.updateInterval = 0.1;
Ahoy_Settings_New = {}

function Ahoy_LoadSettings()
	Ahoy_Settings = Ahoy_Settings or {} -- create table if one doesn't exist
	Ahoy_Settings_New = Ahoy_Settings -- assign settings declared above
end

function Ahoy_SetToggleDefaults()
	-- toggle default states
	if Ahoy_Settings_New.Toggle_MobTargetLootDisplay == nil then Ahoy_Settings_New.Toggle_MobTargetLootDisplay = true; end
	if Ahoy_Settings_New.Toggle_MobMouseOverCategory == nil then Ahoy_Settings_New.Toggle_MobMouseOverCategory = true; end
	if Ahoy_Settings_New.Toggle_ShowRewards == nil then Ahoy_Settings_New.Toggle_ShowRewards = true; end
	if Ahoy_Settings_New.Toggle_AutoShowAhoyOnMissionTable == nil then Ahoy_Settings_New.Toggle_AutoShowAhoyOnMissionTable = true; end
	if Ahoy_Settings_New.Toggle_AutoShowAhoyOnIsland == nil then Ahoy_Settings_New.Toggle_AutoShowAhoyOnIsland = true; end
	if Ahoy_Settings_New.Toggle_HideMinimapIcon == nil then Ahoy_Settings_New.Toggle_HideMinimapIcon = false; end
	if Ahoy_Settings_New.WindowLocked == nil then Ahoy_Settings_New.WindowLocked = false; end
	if Ahoy_Settings_New.WindowScale == nil then Ahoy_Settings_New.WindowScale = 1; end
	if Ahoy_Settings_New.ShowCollected == nil then Ahoy_Settings_New.ShowCollected = true; end
	if Ahoy_Settings_New.ShowCollected == false then
		AhoyLootToolbarCollectedButton_Texture:SetTexCoord(0.460, 0.530, 0.640625 - 0.067, 0.640625) -- eye closed 1
	else
		AhoyLootToolbarCollectedButton_Texture:SetTexCoord(0.360, 0.430, 0.640625 - 0.067, 0.640625) -- eye open
	end
	if Ahoy_Settings_New.Toggle_MobTooltipLootDisplay == nil then Ahoy_Settings_New.Toggle_MobTooltipLootDisplay = false; end
	if Ahoy_Settings_New.DEBUGMODE == nil then Ahoy_Settings_New.DEBUGMODE = false; end
	if Ahoy_Settings_New.MapIcons == nil then Ahoy_Settings_New.MapIcons = true; end
	if Ahoy_Settings_New.FlashCards == nil then Ahoy_Settings_New.FlashCards = false; end
	--if Ahoy_Settings.minimapPos == nil then Ahoy_Settings.minimapPos = 127.647629509557; end
end

function Ahoy__wait(delay, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
	return false;
	end
	if(Ahoy.waitFrame == nil) then
	Ahoy.waitFrame = CreateFrame("Frame","Ahoy.waitFrame", UIParent);
	Ahoy.waitFrame:SetScript("onUpdate",function (self,elapse)
		local count = #Ahoy.waitTable;
		local i = 1;
		while(i<=count) do
		local waitRecord = tremove(Ahoy.waitTable,i);
		local d = tremove(waitRecord,1);
		local f = tremove(waitRecord,1);
		local p = tremove(waitRecord,1);
		if(d>elapse) then
			tinsert(Ahoy.waitTable,i,{d-elapse,f,p});
			i = i + 1;
		else
			count = count - 1;
			f(unpack(p));
		end
		end
	end);
	end
	tinsert(Ahoy.waitTable,{delay,func,{...}});
	return true;
end