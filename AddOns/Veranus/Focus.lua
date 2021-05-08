--[shift+左键点击头像或者目标快速设置系统焦点，shift+左键点击空白区域则取消]
local modifier = "shift" --按住shift，也可设置为alt或者crtl
local mouseButton = "1" --鼠标按键 1是左键、2是右键、3是中键

local function SetFocusHotkey(frame)
frame:SetAttribute(modifier.."-type"..mouseButton, "focus")
end

local function CreateFrame_Hook(type, name, parent, template)
if name and template == "SecureUnitButtonTemplate" then
SetFocusHotkey(_G[name])
end
end

hooksecurefunc("CreateFrame", CreateFrame_Hook)

local f = CreateFrame("CheckButton", "FocuserButton", UIParent, "SecureActionButtonTemplate")
f:SetAttribute("type1", "macro")
f:SetAttribute("macrotext", "/focus mouseover")
SetOverrideBindingClick(FocuserButton, true, modifier.."-BUTTON"..mouseButton, "FocuserButton")

local duf = {
PetFrame,
PartyMemberFrame1,
PartyMemberFrame2,
PartyMemberFrame3,
PartyMemberFrame4,
PartyMemberFrame1PetFrame,
PartyMemberFrame2PetFrame,
PartyMemberFrame3PetFrame,
PartyMemberFrame4PetFrame,
PartyMemberFrame1TargetFrame,
PartyMemberFrame2TargetFrame,
PartyMemberFrame3TargetFrame,
PartyMemberFrame4TargetFrame,
TargetFrame,
TargetFrameToT,
TargetFrameToTTargetFrame,
}

for i, frame in pairs(duf) do
SetFocusHotkey(frame)
end
