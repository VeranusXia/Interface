local addonName, addon = ...

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

local plugin = ldb:NewDataObject(addonName, {
	type = "data source",
	text = "Ahoy",
	icon = "Interface\\Icons\\inv_helmet_66",
})

function plugin.OnTooltipShow(tt)
	tt:AddLine("Ahoy!")
	tt:AddLine("Left Click - Open")
	tt:AddLine("Right Click - Reset Position")
end

local Ahoy = Ahoy

function plugin.OnClick(self, button)
	if button == "RightButton" then
		Ahoy_ResetMainframePosition();
	else
		Ahoy_ToggleMainframe();
	end
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function()
	local icon = LibStub("LibDBIcon-1.0", true)
	if not icon then return end
	if not Ahoy_SettingsLDB then Ahoy_SettingsLDB = {} end
	icon:Register(addonName, plugin, Ahoy_SettingsLDB)
	--if not AhoyLDBIconDB then AhoyLDBIconDB = {} end
	--icon:Register(addonName, plugin, AhoyLDBIconDB)
end)
f:RegisterEvent("PLAYER_LOGIN")