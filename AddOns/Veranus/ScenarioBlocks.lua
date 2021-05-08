local switch=true
local mawBuffsBlock = _G.ScenarioBlocksFrame.MawBuffsBlock
local list = mawBuffsBlock and mawBuffsBlock.Container.List
if list and switch then
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", mawBuffsBlock.Container, "TOPRIGHT", 10, 0)
end